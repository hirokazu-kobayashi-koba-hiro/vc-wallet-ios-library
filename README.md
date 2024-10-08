# vc-wallet-ios-library

## overview
This library provides protocol of OID4VC and OID4VP and multi account management.

This library is implemented based on [OpenID for Verifiable Credentials](https://openid.net/sg/openid4vc/) and [OpenID for Verifiable Presentation](https://openid.github.io/OpenID4VP/openid-4-verifiable-presentations-wg-draft.html).


## feature
The library provides the following functionality:

- Account management
    - [ ] OIDC
- Key management
    - [ ] generate key-pair
    - web3-eth
        - [ ] generate key-pair
        - [ ] restore key-pair with seed
- Document management
    - [ ] Storage encryption
    - [ ] separate with namespace
- OpenID for Verifiable Credential Issuance
    - protocol
        - [ ] Authorization Code Flow
        - [ ] Pre-authorization Code Flow
        - [ ] Support for deferred issuing
        - [ ] Dynamic registration of clients
    - use-case
        - [ ] same device
        - [ ] cross device
    - format
        - [ ] mso_mdoc
        - [ ] sd-jwt-vc
        - [ ] jwt_vc_json
        - [ ] did_jwt_vc
        - [ ] jwt_vc_json-ld
        - [ ] ldp_vc
    - extension
        - [ ] Support for DPoP JWT in authorization
- OpenID for Verifiable Presentations
    - protocol
        - [ ] For pre-registered verifiers
        - [ ] Dynamic registration of verifiers
    - use-case
        - [ ] remote
        - [ ] proximity

## requirements

iOS 15 higher

## installation

To use VcWalletLibrary, add the following dependency to your Package.swift:

```
dependencies: [
        .package(url: "https://github.com/hirokazu-kobayashi-koba-hiro/vc-wallet-ios-library.git", from: "1.0.0")
]
```

Then add the VcWalletLibrary package to your target's dependencies:

```
dependencies: [
    .product(name: "VcWalletLibrary", package: "vc-wallet-ios-library"),
]

```


## quick start

TODO


## implementation

### format

```shell
./scripts/format.sh Sources
```