# Staking Contract (Clarity - Stacks Blockchain)

This project implements a simple staking smart contract using [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-language), designed for the Stacks blockchain.  
Users can lock their tokens for a specific period and earn rewards upon withdrawal.

---

## 📌 Features
- **Stake tokens**: Users lock tokens for a chosen duration.
- **Unstake tokens**: Available only after the lock period ends.
- **Reward mechanism**: Fixed percentage reward rate.
- **Admin controls**: Contract owner can update reward parameters.

---

## 🛠️ Project Setup

### 1. Install Dependencies
- Install [Clarinet](https://github.com/hirosystems/clarinet).
- Install [Node.js](https://nodejs.org/) (if running tests with TypeScript).

### 2. Initialize Project
```bash
# Create new Clarinet project
clarinet new staking-contract

# Navigate into project
cd staking-contract
