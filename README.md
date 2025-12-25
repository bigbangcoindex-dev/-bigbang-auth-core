
# BigBang Auth Core

## Introduction

[متن معرفی رسمی پروژه را اینجا کامل paste کن]
🔐 BigBang Auth Core – Official Project Introduction
BigBang Auth Core is a decentralized, on-chain authentication protocol designed to provide project‑bound, replay‑resistant identity verification without relying on centralized servers or off‑chain trust assumptions.

At its core, BigBang introduces a minimal and auditable authentication primitive based on time‑derived one‑time keys (OTP) that are cryptographically bound to the project context, ensuring that authentication proofs cannot be reused across different managers, domains, or applications.

### Core Design Philosophy
BigBang Auth Core is built around three fundamental principles:

-**On-Chain Verifiability**

All authentication proofs are generated and validated directly on‑chain, enabling trustless verification without external services.

- **Project-Bound Security Model**

Each project is uniquely scoped by its manager address. Authentication keys are cryptographically bound to this context, eliminating cross‑project replay attacks by design.

- **Minimal Surface, Maximum Auditability**

The protocol intentionally avoids unnecessary complexity, focusing on a small, readable, and auditable Solidity core suitable for formal review and long‑term maintenance.

✦ Authentication Model
BigBang Auth Core uses a time‑indexed OTP mechanism derived from:

A user‑specific identity hash
A project‑specific manager address
A deterministic time index
Explicit domain separation
This guarantees that each authentication key is:

Valid only within a specific time window
Bound to a single project
Non‑reusable across managers or contexts
✦ Security Guarantees
The protocol enforces:

Replay resistance across projects
Domain‑bound temporal proofs
Minimum entropy requirements for secrets
Strict validation at registration time
These guarantees make BigBang Auth Core suitable as a foundational authentication layer for decentralized applications, private networks, and identity‑aware smart contract systems.

✦ Current Status
BigBang Auth Core has been publicly released as v0.1.0, representing the first stable and production‑ready version of the core protocol.

The current release focuses exclusively on the authentication primitive. Higher‑level tooling, SDKs, and integrations are intentionally kept out of scope to preserve clarity and security at the core layer.

✦ Vision
BigBang Auth Core aims to become a low‑level authentication building block for decentralized infrastructures—enabling developers to build secure, identity‑aware systems without sacrificing decentralization or verifiability.
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
