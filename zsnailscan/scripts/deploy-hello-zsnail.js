import hre from 'hardhat';

async function main() {
  console.log('🚀 Deploying HelloZSnail to ZSnail L2...');
  console.log('Network:', hre.network.name);
  
  // Get the deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log('Deploying with account:', deployer.address);
  
  // Check balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log('Account balance:', hre.ethers.formatEther(balance), 'ETH');
  
  // Get network info
  const networkInfo = await hre.ethers.provider.getNetwork();
  console.log('Chain ID:', networkInfo.chainId.toString());
  console.log('Block number:', await hre.ethers.provider.getBlockNumber());
  
  // Deploy the contract
  const HelloZSnail = await hre.ethers.getContractFactory('HelloZSnail');
  const initialMessage = 'Welcome to ZSnail L2 Blockchain!';
  
  console.log('Deploying HelloZSnail contract...');
  const helloZSnail = await HelloZSnail.deploy(initialMessage);
  
  // Wait for deployment
  await helloZSnail.waitForDeployment();
  const contractAddress = await helloZSnail.getAddress();
  
  console.log('✅ HelloZSnail deployed successfully!');
  console.log('Contract address:', contractAddress);
  
  // Verify deployment by calling contract functions
  console.log('\n🔍 Verifying deployment...');
  const message = await helloZSnail.message();
  const owner = await helloZSnail.owner();
  const deploymentBlock = await helloZSnail.deploymentBlock();
  
  console.log('Contract message:', message);
  console.log('Contract owner:', owner);
  console.log('Deployed at block:', deploymentBlock.toString());
  
  // Test the greet function
  console.log('\n🎉 Testing contract functionality...');
  const greetTx = await helloZSnail.greet();
  await greetTx.wait();
  
  const callCount = await helloZSnail.callCount();
  console.log('Total calls:', callCount.toString());
  
  // Get chain info from contract
  const [chainId, blockNumber] = await helloZSnail.getChainInfo();
  console.log('Chain ID from contract:', chainId.toString());
  console.log('Current block from contract:', blockNumber.toString());
  
  console.log('\n🎯 Deployment Summary:');
  console.log('Contract: HelloZSnail');
  console.log('Address:', contractAddress);
  console.log('Network: ZSnail L2');
  console.log('Chain ID:', chainId.toString());
  console.log('Deployer Wallet:', deployer.address);
  console.log('Status: ✅ DEPLOYED AND VERIFIED');
  
  return {
    contract: helloZSnail,
    address: contractAddress,
    deployer: deployer.address
  };
}

// Handle errors
main()
  .then(() => {
    console.log('\n🚀 Deployment completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Deployment failed:');
    console.error(error);
    process.exit(1);
  });