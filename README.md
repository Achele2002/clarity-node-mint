# NodeMint
A Clarity smart contract platform for minting IoT-based NFTs on the Stacks blockchain.

## Features
- Mint NFTs with IoT device data
- Register IoT devices as data sources
- Verify device authenticity 
- Transfer NFT ownership
- View NFT metadata and history

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Register an IoT device
(contract-call? .node-mint register-device 
  "device123" 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  "temperature_sensor"
)

;; Mint NFT with IoT data
(contract-call? .node-mint mint-nft
  "device123"
  {temp: u72, humidity: u45, timestamp: u1634567890}
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
)

;; Transfer NFT
(contract-call? .node-mint transfer-nft
  u1
  'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
