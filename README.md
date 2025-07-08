# Tokenized Decentralized Senior Housing Networks

A comprehensive blockchain-based platform for connecting seniors with appropriate housing facilities while facilitating family involvement, healthcare coordination, and community engagement.

## Overview

This system consists of five interconnected smart contracts that work together to create a decentralized senior housing network:

1. **Health Assessment Contract** - Evaluates and stores care level requirements for seniors
2. **Facility Matching Contract** - Connects seniors with appropriate housing facilities based on their needs
3. **Family Involvement Contract** - Facilitates relative participation in care decisions and oversight
4. **Social Activity Contract** - Organizes and manages community engagement programs
5. **Medical Coordination Contract** - Manages healthcare provider integration and medical records

## Key Features

- **Decentralized Care Assessment**: Blockchain-based health evaluations and care level determinations
- **Smart Facility Matching**: Automated matching of seniors to appropriate facilities based on care needs
- **Family Governance**: Democratic decision-making processes for family members
- **Community Engagement**: Tokenized social activities and community programs
- **Healthcare Integration**: Secure medical record management and provider coordination
- **Transparency**: All decisions and assessments recorded on-chain for accountability

## Token Economics

The system uses native STX tokens for:
- Facility deposits and payments
- Healthcare service fees
- Social activity participation
- Family voting incentives
- Assessment validation rewards

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized data structures and validation mechanisms.

### Health Assessment Contract
- Stores comprehensive health profiles
- Manages care level classifications
- Tracks assessment history
- Validates healthcare provider credentials

### Facility Matching Contract
- Maintains facility registry with capabilities
- Implements matching algorithms
- Manages availability and capacity
- Handles booking and reservations

### Family Involvement Contract
- Manages family member registration
- Implements voting mechanisms for care decisions
- Tracks family engagement metrics
- Handles emergency contact protocols

### Social Activity Contract
- Organizes community events and programs
- Manages participant registration
- Tracks engagement and participation
- Distributes rewards for active participation

### Medical Coordination Contract
- Coordinates between healthcare providers
- Manages medical appointments and schedules
- Stores encrypted medical records
- Handles insurance and billing coordination

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing
- Node.js for running tests

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Testing

The project uses Vitest for comprehensive testing of all contract functions:

\`\`\`bash
npm test
\`\`\`

## Usage Examples

### Registering a Senior for Assessment
\`\`\`clarity
(contract-call? .health-assessment register-senior
"John Doe"
u75
"Diabetes, Hypertension"
u2)
\`\`\`

### Finding Matching Facilities
\`\`\`clarity
(contract-call? .facility-matching find-matches
u1
u2
"assisted-living")
\`\`\`

### Family Voting on Care Decisions
\`\`\`clarity
(contract-call? .family-involvement cast-vote
u1
u1
true)
\`\`\`

## Security Considerations

- All sensitive data is encrypted before storage
- Multi-signature requirements for critical decisions
- Regular security audits and updates
- Compliance with healthcare privacy regulations

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

