# BigBang Auth Core

BigBang is a decentralized, on-chain authentication protocol designed for
project-bound, time-based identity proofs.

This repository contains the **core smart contract** of the BigBang protocol.

## Features

- Project-bound One-Time Passwords (OTP)
- Secure daily key derivation with domain separation
- Manager-based project registration
- On-chain fee enforcement via BigBang Token (BBG)
- Root-controlled governance and upgrade hooks
- Designed for extensibility (e.g. FBIP extensions)

## Security Model

- OTP is derived using:
  - `identityHash`
  - `manager` (project context)
  - `timeIndex`
- Cross-project replay attacks are explicitly prevented.
- Minimum entropy enforcement for secrets.

## Status

- ✅ Core finalized
- ✅ Security-critical issues resolved
- 🚧 Extensions under design (FBIP, off-chain integrations)

## Disclaimer

This protocol is provided as-is and has not yet been formally audited.
Use at your own risk.
