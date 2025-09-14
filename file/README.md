# Staking Contract (Phase 3)

This contract allows users to stake fungible tokens (SIP-010 standard), lock them for a period, and withdraw later with rewards or penalties.

## Features
- Stake SIP-010 fungible tokens
- Lock tokens until block height expires
- Withdraw with 10% reward if unlocked
- Early withdrawal with 5% penalty
- Prevent double withdrawals
- Admin can configure the FT contract

## Setup
1. Install Clarinet:
   ```bash
   npm install -g @hirosystems/clarinet
