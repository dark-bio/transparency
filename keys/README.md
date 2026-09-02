# Pubkey Transparency Report

Keys are referenced throughout Dark Bio systems by their fingerprints, listed in [`fingerprints.txt`](./fingerprints.txt). The fingerprint of an xDSA, ML-DSA or Ed25519 key is the SHA-256 of the raw public key. The fingerprint of an RSA key is the SHA-256 of the little endian modulus and exponent, zero padded to 256 and 8 bytes.

All keys in this report can be verified by hand with `openssl` as shown in each section, or in bulk via [`scripts/verify.sh`](./scripts/verify.sh), which checks the certificate chains, the pubkeys against their certificates, the xDSA compositions and the fingerprints.

## Secure boot

All operating system images are signed with RSA-2048 keys via YubiHSMs; with keys generated on the HSM and certified so. The choice of RSA is bound by the capabilities and limitations of the compute chip inside the Ark enclaves.

|     Series      |                                RSA-2048 Pubkey                                 |                                  YubiHSM Certificate                                   |
|:---------------:|:------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------:|
|  Ark I - alpha  |   [`secureboot-ark1-alpha.rsa.pub`](./pubkeys/secureboot-ark1-alpha.rsa.pub)   |   [`secureboot-ark1-alpha.rsa.cert`](../hsms/attests/secureboot-ark1-alpha.rsa.cert)   |
| Ark I - friend  |  [`secureboot-ark1-friend.rsa.pub`](./pubkeys/secureboot-ark1-friend.rsa.pub)  |  [`secureboot-ark1-friend.rsa.cert`](../hsms/attests/secureboot-ark1-friend.rsa.cert)  |
| Ark I - founder | [`secureboot-ark1-founder.rsa.pub`](./pubkeys/secureboot-ark1-founder.rsa.pub) | [`secureboot-ark1-founder.rsa.cert`](../hsms/attests/secureboot-ark1-founder.rsa.cert) |

You can verify the attestation chain from Yubico to the secure-boot keys:

```sh
# Verify the certificate chains
$ openssl verify -CAfile ../hsms/certs/yubico-yubihsm-ca.cert \
    -untrusted ../hsms/certs/yubico-yubihsm-int.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-auth.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-conn.cert \
    ../hsms/attests/secureboot-ark1-alpha.rsa.cert
../hsms/attests/secureboot-ark1-alpha.rsa.cert: OK

$ openssl verify -CAfile ../hsms/certs/yubico-yubihsm-ca.cert \
    -untrusted ../hsms/certs/yubico-yubihsm-int.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-auth.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-conn.cert \
    ../hsms/attests/secureboot-ark1-friend.rsa.cert
../hsms/attests/secureboot-ark1-friend.rsa.cert: OK

$ openssl verify -CAfile ../hsms/certs/yubico-yubihsm-ca.cert \
    -untrusted ../hsms/certs/yubico-yubihsm-int.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-auth.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-conn.cert \
    ../hsms/attests/secureboot-ark1-founder.rsa.cert
../hsms/attests/secureboot-ark1-founder.rsa.cert: OK

# Print the certificate / pubkey details
$ openssl x509 -in ../hsms/attests/secureboot-ark1-alpha.rsa.cert --noout --text
[...]

$ openssl x509 -in ../hsms/attests/secureboot-ark1-friend.rsa.cert --noout --text
[...]

$ openssl x509 -in ../hsms/attests/secureboot-ark1-founder.rsa.cert --noout --text
[...]
```

## Firmware update

All firmware update bundles are signed with xDSA keys (composite ML-DSA with Ed25519). The Ed25519 part is signed via YubiHSMs (with keys generated on the HSM and certified so) whereas the ML-DSA is signed in software only due to no HSM capability at the time of writing.

|     Series      |                                       xDSA Pubkey                                        |                                       ML-DSA Pubkey                                        |                                       Ed25519 Pubkey                                       |                                    YubiHSM Ed25519 Certificate                                     |
|:---------------:|:----------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------------:|
|  Ark I - alpha  |   [`firmwareupdate-ark1-alpha.xdsa.pub`](./pubkeys/firmwareupdate-ark1-alpha.xdsa.pub)   |   [`firmwareupdate-ark1-alpha.mldsa.pub`](./pubkeys/firmwareupdate-ark1-alpha.mldsa.pub)   |   [`firmwareupdate-ark1-alpha.eddsa.pub`](./pubkeys/firmwareupdate-ark1-alpha.eddsa.pub)   |   [`firmwareupdate-ark1-alpha.eddsa.cert`](../hsms/attests/firmwareupdate-ark1-alpha.eddsa.cert)   |
| Ark I - friend  |  [`firmwareupdate-ark1-friend.xdsa.pub`](./pubkeys/firmwareupdate-ark1-friend.xdsa.pub)  |  [`firmwareupdate-ark1-friend.mldsa.pub`](./pubkeys/firmwareupdate-ark1-friend.mldsa.pub)  |  [`firmwareupdate-ark1-friend.eddsa.pub`](./pubkeys/firmwareupdate-ark1-friend.eddsa.pub)  |  [`firmwareupdate-ark1-friend.eddsa.cert`](../hsms/attests/firmwareupdate-ark1-friend.eddsa.cert)  |
| Ark I - founder | [`firmwareupdate-ark1-founder.xdsa.pub`](./pubkeys/firmwareupdate-ark1-founder.xdsa.pub) | [`firmwareupdate-ark1-founder.mldsa.pub`](./pubkeys/firmwareupdate-ark1-founder.mldsa.pub) | [`firmwareupdate-ark1-founder.eddsa.pub`](./pubkeys/firmwareupdate-ark1-founder.eddsa.pub) | [`firmwareupdate-ark1-founder.eddsa.cert`](../hsms/attests/firmwareupdate-ark1-founder.eddsa.cert) |

You can verify the attestation chain from Yubico to the firmware-update EdDSA keys:

```sh
# Verify the certificate chains
$ openssl verify -CAfile ../hsms/certs/yubico-yubihsm-ca.cert \
    -untrusted ../hsms/certs/yubico-yubihsm-int.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-auth.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-conn.cert \
    ../hsms/attests/firmwareupdate-ark1-alpha.eddsa.cert
../hsms/attests/firmwareupdate-ark1-alpha.eddsa.cert: OK

$ openssl verify -CAfile ../hsms/certs/yubico-yubihsm-ca.cert \
    -untrusted ../hsms/certs/yubico-yubihsm-int.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-auth.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-conn.cert \
    ../hsms/attests/firmwareupdate-ark1-friend.eddsa.cert
../hsms/attests/firmwareupdate-ark1-friend.eddsa.cert: OK

$ openssl verify -CAfile ../hsms/certs/yubico-yubihsm-ca.cert \
    -untrusted ../hsms/certs/yubico-yubihsm-int.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-auth.cert \
    -untrusted ../hsms/certs/yubihsm-31650558-conn.cert \
    ../hsms/attests/firmwareupdate-ark1-founder.eddsa.cert
../hsms/attests/firmwareupdate-ark1-founder.eddsa.cert: OK

# Print the certificate / pubkey details
$ openssl x509 -in ../hsms/attests/firmwareupdate-ark1-alpha.eddsa.cert --noout --text
[...]

$ openssl x509 -in ../hsms/attests/firmwareupdate-ark1-friend.eddsa.cert --noout --text
[...]

$ openssl x509 -in ../hsms/attests/firmwareupdate-ark1-founder.eddsa.cert --noout --text
[...]
```

The xDSA pubkey is `mldsa || eddsa` and is provided for convenience.

## Device attestation

All Ark enclaves have a unique xDSA identity (composite ML-DSA with Ed25519) burnt into their computing chip, signed by a root attestation xDSA key. The Ed25519 part is signed via YubiKeys (with keys generated on the YK and certified so) whereas the ML-DSA is signed in software only due to no YK capability at the time of writing.

|     Series      |                                     xDSA Pubkey                                      |                                     ML-DSA Pubkey                                      |                                     Ed25519 Pubkey                                     |                                         YubiKey Ed25519 Certificate                                          |
|:---------------:|:------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------:|
|  Ark I - alpha  |   [`deviceattest-ark1-alpha.xdsa.pub`](./pubkeys/deviceattest-ark1-alpha.xdsa.pub)   |   [`deviceattest-ark1-alpha.mldsa.pub`](./pubkeys/deviceattest-ark1-alpha.mldsa.pub)   |   [`deviceattest-ark1-alpha.eddsa.pub`](./pubkeys/deviceattest-ark1-alpha.eddsa.pub)   |   [`deviceattest-ark1-alpha.eddsa.attest.cert`](../hsms/attests/deviceattest-ark1-alpha.eddsa.attest.cert)   |
| Ark I - friend  |  [`deviceattest-ark1-friend.xdsa.pub`](./pubkeys/deviceattest-ark1-friend.xdsa.pub)  |  [`deviceattest-ark1-friend.mldsa.pub`](./pubkeys/deviceattest-ark1-friend.mldsa.pub)  |  [`deviceattest-ark1-friend.eddsa.pub`](./pubkeys/deviceattest-ark1-friend.eddsa.pub)  |  [`deviceattest-ark1-friend.eddsa.attest.cert`](../hsms/attests/deviceattest-ark1-friend.eddsa.attest.cert)  |
| Ark I - founder | [`deviceattest-ark1-founder.xdsa.pub`](./pubkeys/deviceattest-ark1-founder.xdsa.pub) | [`deviceattest-ark1-founder.mldsa.pub`](./pubkeys/deviceattest-ark1-founder.mldsa.pub) | [`deviceattest-ark1-founder.eddsa.pub`](./pubkeys/deviceattest-ark1-founder.eddsa.pub) | [`deviceattest-ark1-founder.eddsa.attest.cert`](../hsms/attests/deviceattest-ark1-founder.eddsa.attest.cert) |

You can verify the attestation chain from Yubico to the device-attestation EdDSA keys:

```sh
# Verify the certificate chain
$ openssl verify -CAfile ../hsms/certs/yubico-yubikey-ca.cert \
    -untrusted ../hsms/certs/yubico-yubikey-int.cert \
    -untrusted ../hsms/certs/yubikey-33265034.cert \
    ../hsms/attests/deviceattest-ark1-alpha.eddsa.attest.cert
../hsms/attests/deviceattest-ark1-alpha.eddsa.attest.cert: OK

$ openssl verify -CAfile ../hsms/certs/yubico-yubikey-ca.cert \
    -untrusted ../hsms/certs/yubico-yubikey-int.cert \
    -untrusted ../hsms/certs/yubikey-33265034.cert \
    ../hsms/attests/deviceattest-ark1-friend.eddsa.attest.cert
../hsms/attests/deviceattest-ark1-friend.eddsa.attest.cert: OK

$ openssl verify -CAfile ../hsms/certs/yubico-yubikey-ca.cert \
    -untrusted ../hsms/certs/yubico-yubikey-int.cert \
    -untrusted ../hsms/certs/yubikey-33265034.cert \
    ../hsms/attests/deviceattest-ark1-founder.eddsa.attest.cert
../hsms/attests/deviceattest-ark1-founder.eddsa.attest.cert: OK

# Print the certificate / pubkey details
$ openssl x509 -in ../hsms/attests/deviceattest-ark1-alpha.eddsa.attest.cert --noout --text
[...]

$ openssl x509 -in ../hsms/attests/deviceattest-ark1-friend.eddsa.attest.cert --noout --text
[...]

$ openssl x509 -in ../hsms/attests/deviceattest-ark1-founder.eddsa.attest.cert --noout --text
[...]
```

The xDSA pubkey is `mldsa || eddsa` and is provided for convenience.

## Emulator attestation

All Ark emulators have a unique xDSA identity (composite ML-DSA with Ed25519) issued online by the cloud sandbox, signed by a root attestation xDSA key. Both parts are signed in software only, as emulated devices are recognized by the sandbox alone and never by the Arks or the live cloud.

| Environment |                                         xDSA Pubkey                                          |                                         ML-DSA Pubkey                                          |                                         Ed25519 Pubkey                                         |
|:-----------:|:--------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------:|
|   Release   | [`deviceattest-emulator-release.xdsa.pub`](./pubkeys/deviceattest-emulator-release.xdsa.pub) | [`deviceattest-emulator-release.mldsa.pub`](./pubkeys/deviceattest-emulator-release.mldsa.pub) | [`deviceattest-emulator-release.eddsa.pub`](./pubkeys/deviceattest-emulator-release.eddsa.pub) |

The xDSA pubkey is `mldsa || eddsa` and is provided for convenience.

## Cloud attestation

All Dark Bio cloud identities (composite ML-DSA with Ed25519) are rotated periodically, signed by a root attestation xDSA key. Both parts are signed in software only, as the root is swappable via firmware updates and the cloud is untrusted by the Arks.

| Environment |                               xDSA Pubkey                                |                               ML-DSA Pubkey                                |                               Ed25519 Pubkey                               |
|:-----------:|:------------------------------------------------------------------------:|:--------------------------------------------------------------------------:|:--------------------------------------------------------------------------:|
|   Release   | [`cloudattest-release.xdsa.pub`](./pubkeys/cloudattest-release.xdsa.pub) | [`cloudattest-release.mldsa.pub`](./pubkeys/cloudattest-release.mldsa.pub) | [`cloudattest-release.eddsa.pub`](./pubkeys/cloudattest-release.eddsa.pub) |

The xDSA pubkey is `mldsa || eddsa` and is provided for convenience.

## Internal keys

The develop and staging environments have their own secure boot, firmware update and root attestation keys mirroring the production ones. All are held in software only and are published for reference, no production Ark, emulator or cloud trusts them.


|   Purpose   | Environment |                                     RSA-2048 Pubkey                                     |
|:-----------:|:-----------:|:---------------------------------------------------------------------------------------:|
| Secure boot |   Develop   | [`secureboot-ark1-develop.rsa.pub`](./pubkeys/internal/secureboot-ark1-develop.rsa.pub) |
| Secure boot |   Staging   | [`secureboot-ark1-staging.rsa.pub`](./pubkeys/internal/secureboot-ark1-staging.rsa.pub) |


|       Purpose        | Environment |                                              xDSA Pubkey                                              |                                              ML-DSA Pubkey                                              |                                             Ed25519 Pubkey                                              |
|:--------------------:|:-----------:|:-----------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------------------------------------:|
|  Device attestation  |   Develop   |     [`deviceattest-ark1-develop.xdsa.pub`](./pubkeys/internal/deviceattest-ark1-develop.xdsa.pub)     |     [`deviceattest-ark1-develop.mldsa.pub`](./pubkeys/internal/deviceattest-ark1-develop.mldsa.pub)     |     [`deviceattest-ark1-develop.eddsa.pub`](./pubkeys/internal/deviceattest-ark1-develop.eddsa.pub)     |
|  Device attestation  |   Staging   |     [`deviceattest-ark1-staging.xdsa.pub`](./pubkeys/internal/deviceattest-ark1-staging.xdsa.pub)     |     [`deviceattest-ark1-staging.mldsa.pub`](./pubkeys/internal/deviceattest-ark1-staging.mldsa.pub)     |     [`deviceattest-ark1-staging.eddsa.pub`](./pubkeys/internal/deviceattest-ark1-staging.eddsa.pub)     |
| Emulator attestation |   Develop   | [`deviceattest-emulator-develop.xdsa.pub`](./pubkeys/internal/deviceattest-emulator-develop.xdsa.pub) | [`deviceattest-emulator-develop.mldsa.pub`](./pubkeys/internal/deviceattest-emulator-develop.mldsa.pub) | [`deviceattest-emulator-develop.eddsa.pub`](./pubkeys/internal/deviceattest-emulator-develop.eddsa.pub) |
| Emulator attestation |   Staging   | [`deviceattest-emulator-staging.xdsa.pub`](./pubkeys/internal/deviceattest-emulator-staging.xdsa.pub) | [`deviceattest-emulator-staging.mldsa.pub`](./pubkeys/internal/deviceattest-emulator-staging.mldsa.pub) | [`deviceattest-emulator-staging.eddsa.pub`](./pubkeys/internal/deviceattest-emulator-staging.eddsa.pub) |
|  Cloud attestation   |   Develop   |           [`cloudattest-develop.xdsa.pub`](./pubkeys/internal/cloudattest-develop.xdsa.pub)           |           [`cloudattest-develop.mldsa.pub`](./pubkeys/internal/cloudattest-develop.mldsa.pub)           |           [`cloudattest-develop.eddsa.pub`](./pubkeys/internal/cloudattest-develop.eddsa.pub)           |
|  Cloud attestation   |   Staging   |           [`cloudattest-staging.xdsa.pub`](./pubkeys/internal/cloudattest-staging.xdsa.pub)           |           [`cloudattest-staging.mldsa.pub`](./pubkeys/internal/cloudattest-staging.mldsa.pub)           |           [`cloudattest-staging.eddsa.pub`](./pubkeys/internal/cloudattest-staging.eddsa.pub)           |
|   Firmware update    |   Develop   |   [`firmwareupdate-ark1-develop.xdsa.pub`](./pubkeys/internal/firmwareupdate-ark1-develop.xdsa.pub)   |   [`firmwareupdate-ark1-develop.mldsa.pub`](./pubkeys/internal/firmwareupdate-ark1-develop.mldsa.pub)   |   [`firmwareupdate-ark1-develop.eddsa.pub`](./pubkeys/internal/firmwareupdate-ark1-develop.eddsa.pub)   |
|   Firmware update    |   Staging   |   [`firmwareupdate-ark1-staging.xdsa.pub`](./pubkeys/internal/firmwareupdate-ark1-staging.xdsa.pub)   |   [`firmwareupdate-ark1-staging.mldsa.pub`](./pubkeys/internal/firmwareupdate-ark1-staging.mldsa.pub)   |   [`firmwareupdate-ark1-staging.eddsa.pub`](./pubkeys/internal/firmwareupdate-ark1-staging.eddsa.pub)   |

The xDSA pubkey is `mldsa || eddsa` and is provided for convenience.
