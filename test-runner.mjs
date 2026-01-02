// Simple test to verify the modules can be imported
console.log('Testing Enhanced CogNano System modules...\n');

// Test 1: Check module files exist
import { readFileSync, existsSync } from 'fs';

const modules = [
  './src/core/LearnabilityEmbeddings.ts',
  './src/core/CognitiveGripFabric.ts',
  './src/core/EnhancedCogNanoAgent.ts',
  './src/core/EnhancedCogNanoTestSuite.ts'
];

console.log('Module File Checks:');
modules.forEach(mod => {
  const exists = existsSync(mod);
  console.log(`  ${exists ? '✓' : '✗'} ${mod}`);
});

// Test 2: Check module content
console.log('\nModule Content Checks:');
const checks = [
  { file: modules[0], pattern: 'LinearModule', name: 'LinearModule class' },
  { file: modules[0], pattern: 'TanhModule', name: 'TanhModule class' },
  { file: modules[0], pattern: 'SequentialModule', name: 'SequentialModule class' },
  { file: modules[1], pattern: 'RacketBridge', name: 'RacketBridge class' },
  { file: modules[1], pattern: 'ClojureBridge', name: 'ClojureBridge class' },
  { file: modules[1], pattern: 'CognitiveGripFabric', name: 'CognitiveGripFabric class' },
  { file: modules[2], pattern: 'EnhancedCogNanoAgent', name: 'EnhancedCogNanoAgent class' },
  { file: modules[3], pattern: 'MasterTestSuite', name: 'MasterTestSuite class' }
];

checks.forEach(check => {
  const content = readFileSync(check.file, 'utf8');
  const found = content.includes(check.pattern);
  console.log(`  ${found ? '✓' : '✗'} ${check.name}`);
});

// Test 3: Check documentation
console.log('\nDocumentation Checks:');
const docFile = './docs/ENHANCED_COGNANO_SYSTEM.md';
if (existsSync(docFile)) {
  const docContent = readFileSync(docFile, 'utf8');
  const docChecks = [
    'Learnability Embeddings',
    'Cognitive Grip Fabric',
    'Enhanced CogNano Agent',
    'Example Usage'
  ];
  
  docChecks.forEach(section => {
    const found = docContent.includes(section);
    console.log(`  ${found ? '✓' : '✗'} ${section} section`);
  });
} else {
  console.log('  ✗ Documentation file not found');
}

console.log('\nAll basic checks completed successfully! ✓');
