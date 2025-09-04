# BitBridge Protocol

[![Stacks](https://img.shields.io/badge/Stacks-2.1-blue.svg)](https://www.stacks.co/)
[![Clarity](https://img.shields.io/badge/Clarity-2.0-orange.svg)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A sophisticated Bitcoin-anchored payment channel system enabling instant, trustless micropayments with enterprise-grade security.

## Overview

BitBridge Protocol is a Layer 2 payment channel solution built on the Stacks blockchain that leverages Bitcoin's uncompromising security model while providing scalability for high-frequency transactions. The protocol enables two parties to establish bidirectional payment channels, conduct unlimited off-chain transactions, and settle final balances on-chain with cryptographic guarantees.

### Key Features

- **Bitcoin-Anchored Security**: Built on Stacks, inheriting Bitcoin's security model
- **Instant Micropayments**: Near-zero latency transactions within established channels
- **Trustless Architecture**: No intermediaries required for channel operations
- **Enterprise-Grade Security**: Enhanced validation, authorization controls, and safety checks
- **Dispute Resolution**: Built-in challenge mechanisms for unilateral channel closures
- **Gas Optimization**: Minimal on-chain footprint reduces transaction costs

## Architecture

### Core Components

```
┌─────────────────┐    ┌─────────────────┐
│   Participant A │    │   Participant B │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────┬───────────┘
                     │
         ┌───────────▼───────────┐
         │   Payment Channel     │
         │   (BitBridge Contract)│
         └───────────────────────┘
                     │
         ┌───────────▼───────────┐
         │   Stacks Blockchain   │
         └───────────────────────┘
                     │
         ┌───────────▼───────────┐
         │   Bitcoin Network     │
         └───────────────────────┘
```

### Channel Lifecycle

1. **Channel Establishment**: Two parties authorize each other and establish a channel with initial deposits
2. **Off-Chain Transactions**: Unlimited instant transactions within channel capacity
3. **Channel Closure**: Cooperative or unilateral closure with on-chain settlement

## Security Enhancements

- **Counterparty Validation**: Prevents unauthorized access through explicit authorization requirements
- **Input Sanitization**: Comprehensive boundary checks and parameter validation
- **Enhanced Signature Verification**: Cryptographic validation placeholders for production deployment
- **Fund Transfer Safety**: Multiple validation layers for all financial operations
- **Overflow Protection**: Safeguards against arithmetic overflow attacks
- **Emergency Protocols**: Owner-controlled emergency fund recovery mechanisms

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) >= 1.0.0
- [Node.js](https://nodejs.org/) >= 16.0.0
- [Git](https://git-scm.com/)

### Setup

```bash
# Clone the repository
git clone https://github.com/elijah-mbah/bit-bridge.git
cd bit-bridge

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

## Usage

### 1. Authorize Counterparty

Before establishing a channel, participants must authorize each other:

```clarity
(contract-call? .bit-bridge authorize-counterparty 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### 2. Establish Payment Channel

Create a bidirectional payment channel:

```clarity
(contract-call? .bit-bridge establish-channel 
  0x1234567890abcdef1234567890abcdef12345678  ;; channel-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7   ;; counterparty
  u1000000)                                   ;; initial deposit (1 STX)
```

### 3. Deposit Additional Funds

Add liquidity to an existing channel:

```clarity
(contract-call? .bit-bridge deposit-funds
  0x1234567890abcdef1234567890abcdef12345678  ;; channel-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7   ;; counterparty
  u500000)                                    ;; deposit amount (0.5 STX)
```

### 4. Close Channel Cooperatively

Both parties sign final balances for instant settlement:

```clarity
(contract-call? .bit-bridge close-channel-cooperatively
  0x1234567890abcdef1234567890abcdef12345678  ;; channel-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7   ;; counterparty
  u800000                                     ;; final balance A
  u700000                                     ;; final balance B
  0x3045022100...                             ;; signature A
  0x3045022100...)                            ;; signature B
```

### 5. Force Close Channel

Initiate unilateral closure with challenge period:

```clarity
(contract-call? .bit-bridge initiate-force-close
  0x1234567890abcdef1234567890abcdef12345678  ;; channel-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7   ;; counterparty
  u800000                                     ;; claimed balance A
  u700000                                     ;; claimed balance B
  0x3045022100...)                            ;; state signature
```

## API Reference

### Public Functions

#### Channel Management

| Function | Description | Parameters |
|----------|-------------|------------|
| `establish-channel` | Create a new payment channel | `channel-id`, `counterparty`, `initial-deposit` |
| `deposit-funds` | Add funds to existing channel | `channel-id`, `counterparty`, `deposit-amount` |
| `close-channel-cooperatively` | Close channel with mutual consent | `channel-id`, `counterparty`, `final-balance-a`, `final-balance-b`, `signature-a`, `signature-b` |
| `initiate-force-close` | Start unilateral closure process | `channel-id`, `counterparty`, `claimed-balance-a`, `claimed-balance-b`, `state-signature` |
| `finalize-force-close` | Complete force closure after dispute period | `channel-id`, `counterparty` |

#### Security Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `authorize-counterparty` | Grant authorization to another user | `counterparty` |
| `revoke-counterparty` | Revoke counterparty authorization | `counterparty` |
| `emergency-fund-recovery` | Emergency fund recovery (owner only) | None |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-channel-state` | Retrieve complete channel information | Channel state object |
| `is-channel-active` | Check if channel is currently active | Boolean |
| `check-counterparty-authorization` | Verify authorization status | Boolean |
| `get-contract-balance` | Get total contract balance | Uint |

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `ERR-UNAUTHORIZED` | Caller lacks required permissions |
| u101 | `ERR-CHANNEL-EXISTS` | Channel already exists |
| u102 | `ERR-CHANNEL-NOT-FOUND` | Channel does not exist |
| u103 | `ERR-INSUFFICIENT-FUNDS` | Insufficient balance for operation |
| u104 | `ERR-INVALID-SIGNATURE` | Signature verification failed |
| u105 | `ERR-CHANNEL-CLOSED` | Channel is not active |
| u106 | `ERR-DISPUTE-ACTIVE` | Dispute period still active |
| u107 | `ERR-INVALID-PARAMETERS` | Invalid input parameters |
| u108 | `ERR-BALANCE-MISMATCH` | Balance distribution error |
| u109 | `ERR-INVALID-COUNTERPARTY` | Invalid counterparty specification |
| u110 | `ERR-VALUE-TOO-HIGH` | Value exceeds maximum limit |
| u111 | `ERR-VALUE-TOO-LOW` | Value below minimum limit |

## Configuration

### Constants

- **Dispute Period**: 1,008 blocks (~1 week)
- **Maximum Channel Value**: 1,000,000 STX
- **Minimum Channel Value**: 0.001 STX

### Environment Settings

The protocol supports multiple network configurations:

- **Mainnet**: Production deployment with full security
- **Testnet**: Testing environment with relaxed constraints
- **Devnet**: Local development with instant mining

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npx vitest tests/bit-bridge.test.ts

# Run tests with coverage
npm run test:coverage

# Check contract syntax
clarinet check
```

### Test Coverage

- ✅ Channel establishment and validation
- ✅ Fund deposits and withdrawals
- ✅ Cooperative channel closure
- ✅ Force closure mechanisms
- ✅ Authorization controls
- ✅ Error handling and edge cases
- ✅ Security validations

## Security Considerations

### Production Deployment Checklist

- [ ] Implement proper ECDSA signature verification
- [ ] Conduct comprehensive security audit
- [ ] Set up monitoring and alerting systems
- [ ] Configure emergency response procedures
- [ ] Implement rate limiting and DoS protection
- [ ] Validate all external integrations

### Known Limitations

1. **Signature Verification**: Current implementation uses placeholder verification logic
2. **Channel Discovery**: No built-in channel discovery mechanism
3. **Partial Withdrawals**: No support for partial fund withdrawals
4. **Multi-hop Payments**: Single-hop channels only

## Development

### Project Structure

```
bit-bridge/
├── contracts/
│   └── bit-bridge.clar          # Main protocol contract
├── tests/
│   └── bit-bridge.test.ts       # Comprehensive test suite
├── settings/
│   ├── Devnet.toml             # Development configuration
│   ├── Testnet.toml            # Testing configuration
│   └── Mainnet.toml            # Production configuration
├── Clarinet.toml               # Project configuration
├── package.json                # Node.js dependencies
└── README.md                   # This file
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Clarity best practices
- Use descriptive variable and function names
- Include comprehensive comments
- Maintain consistent indentation
- Add tests for new functionality

## Roadmap

### Phase 1: Core Protocol ✅

- [x] Basic channel establishment
- [x] Fund deposits and withdrawals
- [x] Cooperative closure
- [x] Force closure with disputes

### Phase 2: Security Enhancements ✅

- [x] Authorization controls
- [x] Enhanced validation
- [x] Emergency protocols
- [x] Comprehensive testing

### Phase 3: Advanced Features 🚧

- [ ] Multi-hop payment routing
- [ ] Channel rebalancing
- [ ] Watchtower services
- [ ] Mobile SDK integration

### Phase 4: Enterprise Features 📋

- [ ] Multi-signature channels
- [ ] Atomic swaps
- [ ] Privacy enhancements
- [ ] Regulatory compliance tools

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Stacks Foundation](https://stacks.org/) for the robust blockchain infrastructure
- [Clarity Language](https://clarity-lang.org/) for smart contract capabilities
- Bitcoin Network for providing the security foundation
- Open source community for continuous feedback and contributions
