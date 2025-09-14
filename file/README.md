# Staking Contract Ecosystem - Phase 4

A comprehensive staking system with rewards distribution and enhanced security features built on the Stacks blockchain using Clarity smart contracts.

## Overview

This project has evolved through multiple phases to create a robust staking ecosystem:

- **Phase 1-3**: Basic staking functionality with SIP-010 token integration
- **Phase 4**: Advanced rewards system with enhanced security features

## Contracts

### 1. ft-trait.clar
Defines the SIP-010 Fungible Token trait interface for token compatibility.

### 2. staking.clar
Core staking contract that allows users to:
- Stake tokens with minimum amount requirements
- Withdraw tokens after unlock period
- Query staker information

### 3. staking-rewards.clar (NEW - Phase 4)
Advanced rewards distribution system with enhanced security features:

#### Key Features:
- **Multi-Token Reward Pools**: Support for multiple reward tokens
- **Flexible Reward Distribution**: Configurable rewards per block
- **Enhanced Security**:
  - Multi-signature admin controls
  - Emergency pause functionality
  - Cooldown periods for reward claims
  - Batch operations for efficiency
- **Transparent Operations**: Read-only functions for monitoring

#### Security Enhancements:
1. **Emergency Pause**: Contract owner can pause all operations in case of emergency
2. **Multi-Admin System**: Requires multiple authorized admins for critical operations
3. **Cooldown Protection**: Prevents rapid reward claiming (144 blocks ≈ 1 day)
4. **Input Validation**: Comprehensive checks on all parameters
5. **Reentrancy Protection**: Secure state updates before external calls

#### Core Functions:

**Admin Functions:**
- `create-reward-pool`: Create new reward pools for different tokens
- `add-rewards-to-pool`: Add more rewards to existing pools
- `batch-distribute-rewards`: Efficiently distribute rewards to multiple users
- `emergency-pause-toggle`: Pause/unpause contract operations
- `add-admin`/`remove-admin`: Manage authorized administrators

**User Functions:**
- `claim-rewards`: Claim accumulated rewards with security checks
- `calculate-pending-rewards`: View pending rewards (read-only)

**Monitoring Functions:**
- `get-reward-pool-info`: View pool statistics
- `get-staker-reward-info`: View individual staker reward data
- `get-contract-stats`: Overall contract statistics

### 4. sample-token.clar (Optional)
A sample SIP-010 token implementation for testing purposes.

## Security Features

### Phase 4 Security Enhancements:

1. **Multi-Signature Controls**: Critical operations require multiple admin approvals
2. **Emergency Circuit Breaker**: Immediate pause capability for security incidents
3. **Rate Limiting**: Cooldown periods prevent abuse
4. **Input Sanitization**: Comprehensive validation of all inputs
5. **Overflow Protection**: Safe arithmetic operations
6. **Access Control**: Role-based permissions system
7. **State Isolation**: Separate reward tracking per token/staker pair

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   ft-trait      │    │    staking       │    │ staking-rewards │
│   (Interface)   │◄───┤   (Core Logic)   │◄───┤  (Rewards Mgmt) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Token Contract │    │  Reward Tokens  │
                       │  (SIP-010)      │    │  (SIP-010)      │
                       └─────────────────┘    └─────────────────┘
```

## Usage Examples

### Basic Staking
```clarity
;; Stake 1000 tokens
(contract-call? .staking stake u1000)

;; Check staker info
(contract-call? .staking get-staker tx-sender)

;; Withdraw after unlock period
(contract-call? .staking withdraw)
```

### Rewards Management
```clarity
;; Create reward pool (admin only)
(contract-call? .staking-rewards create-reward-pool .reward-token u10000 u100)

;; Check pending rewards
(contract-call? .staking-rewards calculate-pending-rewards tx-sender .reward-token)

;; Claim rewards
(contract-call? .staking-rewards claim-rewards .reward-token)
```

## Constants & Configuration

### Staking Contract
- `MIN-STAKE`: Minimum stake amount (1 token)

### Rewards Contract
- `MIN-REWARD-AMOUNT`: Minimum reward amount (1 token)
- `REWARD-COOLDOWN`: Cooldown period (144 blocks ≈ 1 day)
- `PRECISION`: Calculation precision (1,000,000)

## Error Codes

### Staking Contract
- `u1`: Insufficient stake amount
- `u2`: No stake found
- `u3`: Stake still locked
- `u4`: Already withdrawn
- `u5`: Transfer failed

### Rewards Contract
- `u100`: Not authorized
- `u101`: Invalid amount
- `u102`: No rewards available
- `u103`: Reward pool empty
- `u104`: Staker not found
- `u105`: Cooldown period active
- `u106`: Invalid period

## Development

### Prerequisites
- Clarinet CLI
- Stacks blockchain node (for deployment)

### Testing
```bash
clarinet check
clarinet test
```

### Deployment
```bash
clarinet deploy --network testnet
```

## Security Considerations

1. **Always test thoroughly** before mainnet deployment
2. **Monitor reward pools** to ensure adequate funding
3. **Use multi-sig wallets** for admin operations
4. **Implement gradual rollout** for new features
5. **Regular security audits** recommended for production use

## Future Enhancements

- Dynamic reward rates based on total staked amount
- Governance token integration for decentralized management
- Slashing mechanisms for validator behavior
- Cross-chain reward token support
- Advanced reward calculation algorithms

## License

This project is open source and available under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Contact

**Author**: Hammed Yakub  
**Email**: hamsohood@gmail.com
