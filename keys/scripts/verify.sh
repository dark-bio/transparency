#!/bin/sh
# Verifies the consistency of the published key material against the hardware
# attestations, so that the report can be audited with a single command using
# nothing beyond openssl and the standard POSIX shell utilities:
#
#   - the HSM and YubiKey device certificates chain up to Yubico's roots
#   - every key attestation certificate chains up to its signing device
#   - every attestation certificate carries exactly the published public key
#   - every composite xDSA public key is its published ML-DSA and Ed25519 parts
#   - every published public key is listed with its fingerprint in the manifest
#
# The result is one row per device and per published key, with the attestation
# column stating how far hardware vouches for the key (software-held keys have
# no attestation at all, composite keys are attested as far as their parts).

set -u
cd "$(dirname "$0")/../.." || exit 1

fails=0
scratch=$(mktemp -d) || exit 1
trap 'rm -rf "$scratch"' EXIT

# outcome records the textual result of the last command, counting failures.
outcome() {
	if [ "$1" -eq 0 ]; then
		outcome=ok
	else
		outcome=FAIL
		fails=$((fails + 1))
	fi
}

# der decodes a PEM file into its DER bytes.
der() {
	sed -e '/^-----/d' "$1" | openssl base64 -d
}

# sha256 hashes stdin, printing the hex digest.
sha256() {
	openssl dgst -sha256 -r | cut -d' ' -f1
}

# lehex reverses the byte order of a hex string and zero pads it to a length.
lehex() {
	printf '%s' "$1" | fold -w2 | awk -v len="$2" '
		{ bytes[NR] = $0 }
		END {
			for (i = NR; i > 0; i--) printf "%s", bytes[i]
			for (i = NR * 2; i < len; i += 2) printf "00"
		}'
}

# bin converts a hex string on stdin into raw bytes.
bin() {
	printf '%b' "$(awk '
		BEGIN { hex = "0123456789abcdef" }
		{
			for (i = 1; i <= length($0); i += 2) {
				hi = index(hex, substr($0, i, 1)) - 1
				lo = index(hex, substr($0, i + 1, 1)) - 1
				printf "\\0%03o", hi * 16 + lo
			}
		}')"
}

# fingerprint computes the fingerprint of a public key, being the SHA-256 of
# the raw key for the xDSA, ML-DSA and Ed25519 keys, and of the little endian
# modulus and exponent (padded to 256 and 8 bytes) for the RSA keys.
fingerprint() {
	case $1 in
	*.xdsa.pub) der "$1" | tail -c 1984 | sha256 ;;
	*.mldsa.pub) der "$1" | tail -c 1952 | sha256 ;;
	*.eddsa.pub) der "$1" | tail -c 32 | sha256 ;;
	*.rsa.pub)
		modulus=$(openssl rsa -pubin -in "$1" -modulus -noout | sed -e 's/^Modulus=//' | tr 'A-F' 'a-f')
		exponent=$(openssl rsa -pubin -in "$1" -text -noout | sed -n -e 's/.*Exponent:.*(0x\([0-9a-fA-F]*\)).*/\1/p' | tr 'A-F' 'a-f')
		case $exponent in ?|???|?????|???????) exponent="0$exponent" ;; esac
		{ lehex "$modulus" 512; lehex "$exponent" 16; } | bin | sha256
		;;
	esac
}

# listed checks that the manifest carries a key under its computed fingerprint.
listed() {
	grep -qFx "$(fingerprint "$1")  ${1#keys/}" keys/fingerprints.txt
}

# chain verifies a certificate against a root and untrusted intermediates.
chain() {
	root=$1
	cert=$2
	shift 2
	untrusted=""
	for inter in "$@"; do
		untrusted="$untrusted -untrusted $inter"
	done
	# shellcheck disable=SC2086
	openssl verify -CAfile "$root" $untrusted "$cert" >/dev/null 2>&1
}

# attests verifies a key attestation certificate against the device that made
# it, the device attestation keys also carrying a self-signed certificate.
attests() {
	case $1 in
	*.self.cert) chain "$1" "$1" ;;
	hsms/attests/deviceattest-*) chain hsms/certs/yubico-yubikey-ca.cert "$1" hsms/certs/yubico-yubikey-int.cert $key_certs ;;
	*) chain hsms/certs/yubico-yubihsm-ca.cert "$1" hsms/certs/yubico-yubihsm-int.cert $hsm_certs ;;
	esac
}

# carries checks that a certificate embeds exactly the published public key.
carries() {
	openssl x509 -in "$1" -pubkey -noout | tr -d '\n' >"$scratch/cert.pub"
	tr -d '\n' <"$2" >"$scratch/key.pub"
	cmp -s "$scratch/cert.pub" "$scratch/key.pub"
}

# composed checks that an xDSA key is the concatenation of its ML-DSA-65 and
# Ed25519 parts, which are the trailing 1952 and 32 bytes of their DER forms.
composed() {
	der "$1" | tail -c 1984 >"$scratch/composite"
	{ der "$2" | tail -c 1952; der "$3" | tail -c 32; } >"$scratch/parts"
	cmp -s "$scratch/composite" "$scratch/parts"
}

# device names the hardware that attested a key, based on its certificates.
device() {
	case $1 in
	deviceattest-*) printf 'yubikey' ;;
	*) printf 'yubihsm' ;;
	esac
}

# Verify the hardware devices against Yubico's roots, an HSM's connectivity
# certificate being attested by its own authenticity certificate.
printf '%-38s %s\n' 'Devices' 'chain'
hsm_certs=""
for conn in hsms/certs/yubihsm-*-conn.cert; do
	auth="${conn%-conn.cert}-auth.cert"
	name=$(basename "$conn" -conn.cert)
	chain hsms/certs/yubico-yubihsm-ca.cert "$conn" hsms/certs/yubico-yubihsm-int.cert "$auth"
	outcome $?
	printf '  %-36s %s\n' "$name" "$outcome"
	hsm_certs="$hsm_certs $auth $conn"
done
key_certs=""
for yk in hsms/certs/yubikey-*.cert; do
	name=$(basename "$yk" .cert)
	chain hsms/certs/yubico-yubikey-ca.cert "$yk" hsms/certs/yubico-yubikey-int.cert
	outcome $?
	printf '  %-36s %s\n' "$name" "$outcome"
	key_certs="$key_certs $yk"
done

# keyrow verifies a published key against its attestation certificates, the
# fingerprint manifest and, for composites, against its published parts,
# printing the outcomes as a row.
keyrow() {
	pub=$1
	dir=$(dirname "$pub")
	name=$(basename "$pub" .pub)
	chained="-"
	carried="-"
	parts="-"
	attestation="software"
	keys=$((keys + 1))

	listed "$pub"
	outcome $?
	listed=$outcome

	case $name in
	*.xdsa)
		base="${name%.xdsa}"
		composed "$pub" "$dir/$base.mldsa.pub" "$dir/$base.eddsa.pub"
		outcome $?
		parts=$outcome
		# A composite is attested as far as its parts are
		mldsa=$(ls hsms/attests/"$base".mldsa*.cert 2>/dev/null | wc -l)
		eddsa=$(ls hsms/attests/"$base".eddsa*.cert 2>/dev/null | wc -l)
		if [ "$mldsa" -gt 0 ] && [ "$eddsa" -gt 0 ]; then
			attestation=$(device "$name")
		elif [ "$eddsa" -gt 0 ]; then
			attestation="ed25519 part only"
		elif [ "$mldsa" -gt 0 ]; then
			attestation="ml-dsa part only"
		fi
		;;
	*)
		for cert in hsms/attests/"$name".cert hsms/attests/"$name".attest.cert hsms/attests/"$name".self.cert; do
			[ -f "$cert" ] || continue
			attestation=$(device "$name")
			# Every certificate of a key must chain and carry the key, a
			# single failure failing the key
			attests "$cert"
			outcome $?
			[ "$chained" != "FAIL" ] && chained=$outcome
			carries "$cert" "$pub"
			outcome $?
			[ "$carried" != "FAIL" ] && carried=$outcome
		done
		;;
	esac
	printf '  %-36s %-7s %-7s %-7s %-11s %s\n' "$name" "$chained" "$carried" "$parts" "$listed" "$attestation"
}

# Verify the production keys, then the internal ones of the non-production
# environments.
keys=0
printf '\n%-38s %-7s %-7s %-7s %-11s %s\n' 'Keys' 'chain' 'pubkey' 'parts' 'fingerprint' 'attestation'
for pub in keys/pubkeys/*.pub; do
	keyrow "$pub"
done
printf '\n%-38s %-7s %-7s %-7s %-11s %s\n' 'Internal keys' 'chain' 'pubkey' 'parts' 'fingerprint' 'attestation'
for pub in keys/pubkeys/internal/*.pub; do
	keyrow "$pub"
done

# Verify that the manifest has exactly as many entries as there are keys, every
# key having been found in it above, so that no stale entries can linger.
printf '\n%-38s %s\n' 'Fingerprints' 'entries'
[ "$(wc -l <keys/fingerprints.txt)" -eq "$keys" ]
outcome $?
printf '  %-36s %s\n' 'fingerprints.txt' "$outcome"

if [ "$fails" -ne 0 ]; then
	printf '\n%d check(s) failed\n' "$fails"
	exit 1
fi
printf '\nall checks passed\n'
