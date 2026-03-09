# HSM Transparency Report

The project's root security is based on a number of hardware signers, currently all of them [Yubico YubiHSM 2](https://www.yubico.com/products/hardware-security-module/) and [Yubico YubiKey](https://www.yubico.com/products/yubikey-5-overview/) devices:

|      Type      |  Serial  | Firmware | FIPS |                       Authenticity                       |                       Connectivity                       |                 Annotated Logs                 |
|:--------------:|:--------:|:--------:|:----:|:--------------------------------------------------------:|:--------------------------------------------------------:|:----------------------------------------------:|
|   YubiHSM 2    | 31650558 |   v2.4   |  No  | [31650558-auth.cert](./certs/yubihsm-31650558-auth.cert) | [31650558-conn.cert](./certs/yubihsm-31650558-conn.cert) | [31650558-logs.md](./logs/yubihsm-31650558.md) |
| YubiKey 5 Nano | 33265034 |  v5.7.4  |  -   |      [33265034.cert](./certs/yubikey-33265034.cert)      |                           n/a                            |                      n/a                       |

## YubiHSM genuinity attestations

The YubiHSMs are attested by [Yubico's YubiHSM intermediate certificate](https://developers.yubico.com/YubiHSM2/Concepts/E45DA5F361B091B30D8F2C6FA040DB6FEF57918E.pem) (also available as [`./certs/yubico-yubihsm-int.cert`](./certs/yubico-yubihsm-int.cert)), which is attested by [Yubico's YubiHSM root certificate](https://developers.yubico.com/YubiHSM2/Concepts/yubihsm2-attest-ca.cert) (also available as [`./certs/yubico-yubihsm-ca.cert`](./certs/yubico-yubihsm-ca.cert)). The HSM itself attests the certificate needed for connectivity:

```sh
$ openssl verify -CAfile ./certs/yubico-yubihsm-ca.cert \
    -untrusted ./certs/yubico-yubihsm-int.cert \
    -untrusted ./certs/yubihsm-31650558-auth.cert \
    ./certs/yubihsm-31650558-conn.cert
./certs/yubihsm-31650558-conn.cert: OK
```

The YubiHSM serial numbers can be verified from the Yubico-attested authenticity certificates. The device connectivity public keys can be retrieved and verified from the HSM-attested connectivity certificates (key id `0x0000` is reserved for internal YubiHSM use):

```sh
$ openssl x509 -in ./certs/yubihsm-31650558-auth.cert -noout -subject
subject=CN=YubiHSM Attestation (31650558)

$ openssl x509 -in ./certs/yubihsm-31650558-conn.cert -noout -subject
subject=CN=YubiHSM Attestation id:0x0000
```

## YubiKey genuinity attestations

The YubiKeys are attested by [Yubico's YubiKey intermediate certificate](https://developers.yubico.com/PKI/yubico-intermediate.pem) (also available as [`./certs/yubico-yubikey-int.cert`](./certs/yubico-yubikey-int.cert)), which is attested by [Yubico's YubiKey root certificate](https://developers.yubico.com/PKI/yubico-ca-1.pem) (also available as [`./certs/yubico-yubikey-ca.cert`](./certs/yubico-yubikey-ca.cert)):

```sh
$ openssl verify -CAfile ./certs/yubico-yubikey-ca.cert \
    -untrusted ./certs/yubico-yubikey-int.cert \
    ./certs/yubikey-33265034.cert
./certs/yubikey-33265034.cert: OK
```

Opposed to YubiHSMs, the YubiKey device attestations do not contain the serial number, those can be cross-referenced from key attestations. 

## Audit logs

Each HSM has a pre-annotated audit log published. You can extract the raw YubiHSM audit logs from it with [`./scripts/extract.sh`](./scripts/extract.sh). The log hash progression can be verified either via a 3rd party tool, or with [`./scripts/verify.sh`](./scripts/verify.sh) included in this repository.

```sh
$ cat ./logs/yubihsm-31650558.md | ./scripts/extract.sh | ./scripts/verify.sh
✅ Verified N entries.
```

Unfortunately, YubiHSM 2 with firmware 2.4 does ***not*** support signing its own audit log. As such, whilst the above scripts can verify audit log hash progressions; they can attest neither the provenance of the audit log (i.e. which YubiHSM generated it, if any) nor its freshness (i.e. are there unpublished entries).

The only cryptographically secure way to validate a YubiHSM audit log is to establish a live session via asymmetric-key authentication (force verifying the identity of the YubiHSM) and then query the audit log live.

```sh
# Extract the connectivity pubkey in hex form (yubihsm-shell limitation)
$ openssl x509 -in ./certs/yubihsm-31650558-conn.cert -noout -pubkey \
    | openssl ec -pubin -noout -text 2>/dev/null \
    | grep '^    ' | tr -d ' :\n' \
    > yubihsm-31650558-conn.hex
    
# Establish an interactive shell connection to the YubiHSM
$ yubihsm-shell -P \
    --connector=https://31650558.hsm.dark.bio \
    --device-pubkey=`cat yubihsm-31650558-conn.hex`
    
# Authenticate and audit manually (0x00ff is the audit account)
$ yubihsm> session open_asym 0x00ff ./keys/audit.key
Created session X
$ yubihsm> audit get X
```

Keeping the HSMs public at all times isn't a sane proposition, so for audit queries, please contact us at transparency@dark.bio, and we'll try to grant you temporary access. Do note, that we will only respond to queries from legitimate sources, and we reserve the right to publish the request and resolution.
