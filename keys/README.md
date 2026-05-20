# Pubkey Transparency Report

## Secure boot

All operating system images are signed with RSA-2048 keys via YubiHSMs; with keys generated on the HSM and certified so. The choice of RSA is bound by the capabilities and limitations of the compute chip inside the Ark enclaves.

|     Series      |                                   RSA-2048 Pubkey                                    |                                  YubiHSM Certificate                                   |
|:---------------:|:------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------:|
|  Ark I - alpha  |   [`secureboot-ark1-alpha.rsa.pub`](../hsms/attests/secureboot-ark1-alpha.rsa.pub)   |   [`secureboot-ark1-alpha.rsa.cert`](../hsms/attests/secureboot-ark1-alpha.rsa.cert)   |
| Ark I - friend  |  [`secureboot-ark1-friend.rsa.pub`](../hsms/attests/secureboot-ark1-friend.rsa.pub)  |  [`secureboot-ark1-friend.rsa.cert`](../hsms/attests/secureboot-ark1-friend.rsa.cert)  |
| Ark I - founder | [`secureboot-ark1-founder.rsa.pub`](../hsms/attests/secureboot-ark1-founder.rsa.pub) | [`secureboot-ark1-founder.rsa.cert`](../hsms/attests/secureboot-ark1-founder.rsa.cert) |

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

|     Series      |                                          xDSA Pubkey                                           |                                          ML-DSA Pubkey                                           |                                          Ed25519 Pubkey                                          |                                    YubiHSM Ed25519 Certificate                                     |
|:---------------:|:----------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------------:|
|  Ark I - alpha  |   [`firmwareupdate-ark1-alpha.xdsa.pub`](../hsms/attests/firmwareupdate-ark1-alpha.xdsa.pub)   |   [`firmwareupdate-ark1-alpha.mldsa.pub`](../hsms/attests/firmwareupdate-ark1-alpha.mldsa.pub)   |   [`firmwareupdate-ark1-alpha.eddsa.pub`](../hsms/attests/firmwareupdate-ark1-alpha.eddsa.pub)   |   [`firmwareupdate-ark1-alpha.eddsa.cert`](../hsms/attests/firmwareupdate-ark1-alpha.eddsa.cert)   |
| Ark I - friend  |  [`firmwareupdate-ark1-friend.xdsa.pub`](../hsms/attests/firmwareupdate-ark1-friend.xdsa.pub)  |  [`firmwareupdate-ark1-friend.mldsa.pub`](../hsms/attests/firmwareupdate-ark1-friend.mldsa.pub)  |  [`firmwareupdate-ark1-friend.eddsa.pub`](../hsms/attests/firmwareupdate-ark1-friend.eddsa.pub)  |  [`firmwareupdate-ark1-friend.eddsa.cert`](../hsms/attests/firmwareupdate-ark1-friend.eddsa.cert)  |
| Ark I - founder | [`firmwareupdate-ark1-founder.xdsa.pub`](../hsms/attests/firmwareupdate-ark1-founder.xdsa.pub) | [`firmwareupdate-ark1-founder.mldsa.pub`](../hsms/attests/firmwareupdate-ark1-founder.mldsa.pub) | [`firmwareupdate-ark1-founder.eddsa.pub`](../hsms/attests/firmwareupdate-ark1-founder.eddsa.pub) | [`firmwareupdate-ark1-founder.eddsa.cert`](../hsms/attests/firmwareupdate-ark1-founder.eddsa.cert) |

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

|     Series      |                                        xDSA Pubkey                                         |                                        ML-DSA Pubkey                                         |                                        Ed25519 Pubkey                                        |                                         YubiKey Ed25519 Certificate                                          |
|:---------------:|:------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------:|
|  Ark I - alpha  |   [`deviceattest-ark1-alpha.xdsa.pub`](../hsms/attests/deviceattest-ark1-alpha.xdsa.pub)   |   [`deviceattest-ark1-alpha.mldsa.pub`](../hsms/attests/deviceattest-ark1-alpha.mldsa.pub)   |   [`deviceattest-ark1-alpha.eddsa.pub`](../hsms/attests/deviceattest-ark1-alpha.eddsa.pub)   |   [`deviceattest-ark1-alpha.eddsa.attest.cert`](../hsms/attests/deviceattest-ark1-alpha.eddsa.attest.cert)   |
| Ark I - friend  |  [`deviceattest-ark1-friend.xdsa.pub`](../hsms/attests/deviceattest-ark1-friend.xdsa.pub)  |  [`deviceattest-ark1-friend.mldsa.pub`](../hsms/attests/deviceattest-ark1-friend.mldsa.pub)  |  [`deviceattest-ark1-friend.eddsa.pub`](../hsms/attests/deviceattest-ark1-friend.eddsa.pub)  |  [`deviceattest-ark1-friend.eddsa.attest.cert`](../hsms/attests/deviceattest-ark1-friend.eddsa.attest.cert)  |
| Ark I - founder | [`deviceattest-ark1-founder.xdsa.pub`](../hsms/attests/deviceattest-ark1-founder.xdsa.pub) | [`deviceattest-ark1-founder.mldsa.pub`](../hsms/attests/deviceattest-ark1-founder.mldsa.pub) | [`deviceattest-ark1-founder.eddsa.pub`](../hsms/attests/deviceattest-ark1-founder.eddsa.pub) | [`deviceattest-ark1-founder.eddsa.attest.cert`](../hsms/attests/deviceattest-ark1-founder.eddsa.attest.cert) |

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
