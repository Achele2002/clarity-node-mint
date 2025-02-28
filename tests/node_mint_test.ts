import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test device registration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test device registration as owner
    let block = chain.mineBlock([
      Tx.contractCall('node-mint', 'register-device', 
        [
          types.ascii("device123"),
          types.principal(wallet1.address),
          types.ascii("temperature_sensor")
        ],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test device registration as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall('node-mint', 'register-device',
        [
          types.ascii("device456"),
          types.principal(wallet1.address),
          types.ascii("humidity_sensor")
        ],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test NFT minting",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Register device first
    chain.mineBlock([
      Tx.contractCall('node-mint', 'register-device',
        [
          types.ascii("device123"),
          types.principal(wallet1.address),
          types.ascii("temperature_sensor")
        ],
        deployer.address
      )
    ]);
    
    // Test minting NFT with authorized device
    let block = chain.mineBlock([
      Tx.contractCall('node-mint', 'mint-nft',
        [
          types.ascii("device123"),
          types.list([types.uint(72), types.uint(45)]),
          types.principal(wallet1.address)
        ],
        wallet1.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Verify NFT data
    let response = chain.callReadOnlyFn(
      'node-mint',
      'get-nft-data',
      [types.uint(1)],
      deployer.address
    );
    response.result.expectOk();
  }
});

Clarinet.test({
  name: "Test NFT transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Setup: Register device and mint NFT
    chain.mineBlock([
      Tx.contractCall('node-mint', 'register-device',
        [
          types.ascii("device123"),
          types.principal(wallet1.address),
          types.ascii("temperature_sensor")
        ],
        deployer.address
      )
    ]);
    
    chain.mineBlock([
      Tx.contractCall('node-mint', 'mint-nft',
        [
          types.ascii("device123"),
          types.list([types.uint(72), types.uint(45)]),
          types.principal(wallet1.address)
        ],
        wallet1.address
      )
    ]);
    
    // Test NFT transfer
    let block = chain.mineBlock([
      Tx.contractCall('node-mint', 'transfer-nft',
        [
          types.uint(1),
          types.principal(wallet2.address)
        ],
        wallet1.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify new owner
    let response = chain.callReadOnlyFn(
      'node-mint',
      'get-nft-data',
      [types.uint(1)],
      deployer.address
    );
    response.result.expectOk();
  }
});
