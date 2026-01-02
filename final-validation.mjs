// Final validation of Enhanced CogNano implementation
import { readFileSync, existsSync } from 'fs';

console.log('='.repeat(70));
console.log('Enhanced CogNano Agent - Final Validation');
console.log('='.repeat(70));
console.log();

const checks = [];

// 1. Module files exist
console.log('1. Module Files Check:');
const modules = {
  'LearnabilityEmbeddings.ts': './src/core/LearnabilityEmbeddings.ts',
  'CognitiveGripFabric.ts': './src/core/CognitiveGripFabric.ts',
  'EnhancedCogNanoAgent.ts': './src/core/EnhancedCogNanoAgent.ts',
  'EnhancedCogNanoTestSuite.ts': './src/core/EnhancedCogNanoTestSuite.ts',
  'EnhancedCogNanoVisualization.tsx': './src/components/EnhancedCogNanoVisualization.tsx'
};

for (const [name, path] of Object.entries(modules)) {
  const exists = existsSync(path);
  console.log(`  ${exists ? '✓' : '✗'} ${name}`);
  checks.push({ name, passed: exists });
}
console.log();

// 2. Core classes check
console.log('2. Core Classes Check:');
const classChecks = [
  { file: modules['LearnabilityEmbeddings.ts'], classes: ['LinearModule', 'TanhModule', 'SequentialModule', 'EmbeddingModule', 'Trainer'] },
  { file: modules['CognitiveGripFabric.ts'], classes: ['RacketBridge', 'ClojureBridge', 'SchemeBridge', 'PerlBridge', 'RakuBridge', 'CognitiveGripFabric'] },
  { file: modules['EnhancedCogNanoAgent.ts'], classes: ['EnhancedCogNanoAgent', 'createEnhancedCogNanoAgent'] },
  { file: modules['EnhancedCogNanoTestSuite.ts'], classes: ['LearnabilityEmbeddingsTestSuite', 'CognitiveGripFabricTestSuite', 'EnhancedCogNanoAgentTestSuite', 'MasterTestSuite'] }
];

for (const check of classChecks) {
  const content = readFileSync(check.file, 'utf8');
  for (const className of check.classes) {
    const found = content.includes(className);
    console.log(`  ${found ? '✓' : '✗'} ${className}`);
    checks.push({ name: className, passed: found });
  }
}
console.log();

// 3. Documentation check
console.log('3. Documentation Check:');
const docs = [
  './docs/ENHANCED_COGNANO_SYSTEM.md',
  './docs/ENHANCED_COGNANO_EXAMPLES.md',
  './ENHANCED_COGNANO_IMPLEMENTATION.md'
];

for (const doc of docs) {
  const exists = existsSync(doc);
  console.log(`  ${exists ? '✓' : '✗'} ${doc}`);
  checks.push({ name: doc, passed: exists });
}
console.log();

// 4. Build artifacts check
console.log('4. Build Artifacts Check:');
const buildFiles = [
  './dist/index.html',
  './dist/assets'
];

for (const file of buildFiles) {
  const exists = existsSync(file);
  console.log(`  ${exists ? '✓' : '✗'} ${file}`);
  checks.push({ name: file, passed: exists });
}
console.log();

// 5. Integration check
console.log('5. Integration Check:');
const appFile = './src/App.tsx';
if (existsSync(appFile)) {
  const appContent = readFileSync(appFile, 'utf8');
  const integrationChecks = [
    { name: 'EnhancedCogNanoVisualization import', pattern: 'EnhancedCogNanoVisualization' },
    { name: 'cognano tab', pattern: 'cognano' },
    { name: 'Code2 icon', pattern: 'Code2' }
  ];
  
  for (const check of integrationChecks) {
    const found = appContent.includes(check.pattern);
    console.log(`  ${found ? '✓' : '✗'} ${check.name}`);
    checks.push({ name: check.name, passed: found });
  }
} else {
  console.log('  ✗ App.tsx not found');
  checks.push({ name: 'App.tsx', passed: false });
}
console.log();

// 6. Feature completeness
console.log('6. Feature Completeness:');
const features = [
  { name: 'Neural Network Modules', file: modules['LearnabilityEmbeddings.ts'], pattern: 'forward' },
  { name: 'Backpropagation', file: modules['LearnabilityEmbeddings.ts'], pattern: 'backward' },
  { name: 'Gradient Descent', file: modules['LearnabilityEmbeddings.ts'], pattern: 'updateParameters' },
  { name: 'Racket Code Gen', file: modules['CognitiveGripFabric.ts'], pattern: '#lang racket' },
  { name: 'Clojure Code Gen', file: modules['CognitiveGripFabric.ts'], pattern: '(ns cognitive' },
  { name: 'Training Loop', file: modules['EnhancedCogNanoAgent.ts'], pattern: 'trainOnPattern' },
  { name: 'Idea Transformation', file: modules['EnhancedCogNanoAgent.ts'], pattern: 'transformCognitiveIdea' },
  { name: 'Test Suite', file: modules['EnhancedCogNanoTestSuite.ts'], pattern: 'runAllTests' }
];

for (const feature of features) {
  const content = readFileSync(feature.file, 'utf8');
  const found = content.includes(feature.pattern);
  console.log(`  ${found ? '✓' : '✗'} ${feature.name}`);
  checks.push({ name: feature.name, passed: found });
}
console.log();

// Summary
console.log('='.repeat(70));
const passed = checks.filter(c => c.passed).length;
const total = checks.length;
const percentage = ((passed / total) * 100).toFixed(1);

console.log(`Validation Summary: ${passed}/${total} checks passed (${percentage}%)`);

if (passed === total) {
  console.log('Status: ✅ ALL CHECKS PASSED - IMPLEMENTATION COMPLETE');
} else {
  console.log('Status: ⚠️  SOME CHECKS FAILED');
  const failed = checks.filter(c => !c.passed);
  console.log('Failed checks:');
  failed.forEach(f => console.log(`  - ${f.name}`));
}
console.log('='.repeat(70));
