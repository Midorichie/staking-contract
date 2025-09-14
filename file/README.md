# Staking Contract (Clarity - Stacks Blockchain)

This project implements a staking smart contract using [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-language), designed for the Stacks blockchain.  
Users can lock tokens for a period, earn rewards, or withdraw early with penalties.

---

## 🚀 Features
- **Stake tokens**: Users lock tokens for a chosen duration.
- **Unstake tokens**:
  - After lock period → receive staked tokens + rewards.
  - Before lock period ends → early withdrawal with penalty.
- **Rewards**: Configurable percentage reward rate.
- **Penalties**: Configurable early withdrawal penalty.
- **Admin controls**: Only contract owner can update reward and penalty rates.
- **Read-only views**:
  - Check a user’s stake.
  - Get total staked.
  - View contract configuration.

---

## 🛠️ Project Setup

### 1. Install Dependencies
- Install [Clarinet](https://github.com/hirosystems/clarinet).
- Install [Node.js](https://nodejs.org/) (for running tests with TypeScript).

### 2. Initialize Project
```bash
clarinet new staking-contract
cd staking-contract
