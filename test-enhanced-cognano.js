import { MasterTestSuite } from './src/core/EnhancedCogNanoTestSuite.ts';

async function main() {
  console.log('Starting Enhanced CogNano Test Suite...\n');
  
  const suite = new MasterTestSuite();
  await suite.runAllTests();
  
  console.log('\nTest suite completed!');
}

main().catch(console.error);
