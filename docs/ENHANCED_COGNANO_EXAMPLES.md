# Enhanced CogNano Agent - Quick Start Examples

This guide provides practical examples to get started with the Enhanced CogNano Agent system.

## Example 1: Simple Pattern Learning

Learn to recognize and classify patterns using neural embeddings.

```typescript
import { createEnhancedCogNanoAgent } from './src/core/EnhancedCogNanoAgent';

// Create agent with default configuration
const agent = createEnhancedCogNanoAgent('default');

// Define training patterns (binary classification example)
const positivePattern = new Float32Array(64).fill(0).map((_, i) => i < 32 ? 1 : 0);
const negativePattern = new Float32Array(64).fill(0).map((_, i) => i < 32 ? 0 : 1);

const positiveTarget = new Float32Array(32).fill(0).map((_, i) => i === 0 ? 1 : 0);
const negativeTarget = new Float32Array(32).fill(0).map((_, i) => i === 1 ? 1 : 0);

// Train on patterns
console.log('Training on patterns...');
for (let epoch = 0; epoch < 10; epoch++) {
  const loss1 = agent.trainOnPattern(positivePattern, positiveTarget);
  const loss2 = agent.trainOnPattern(negativePattern, negativeTarget);
  console.log(`Epoch ${epoch + 1}: Loss = ${(loss1 + loss2) / 2}`);
}

// Generate embeddings for new patterns
const testPattern = new Float32Array(64).fill(0).map((_, i) => i < 32 ? 1 : 0);
const embedding = agent.generateEmbedding(testPattern);
console.log('Generated embedding:', embedding.slice(0, 5));

// Check agent state
const state = agent.getState();
console.log(`Training steps: ${state.learnability_metrics.total_training_steps}`);
console.log(`Average loss: ${state.learnability_metrics.average_loss.toFixed(4)}`);
```

## Example 2: Multi-Language Cognitive Transformation

Transform a cognitive idea into implementations across multiple programming languages.

```typescript
import { 
  createEnhancedCogNanoAgent, 
  ExampleCognitiveIdeas 
} from './src/core/EnhancedCogNanoAgent';

// Create agent
const agent = createEnhancedCogNanoAgent('default');

// Define a cognitive idea
const myIdea = {
  id: 'attention_mechanism_001',
  name: 'Attention Mechanism',
  description: 'Focus computational resources on important elements',
  domain: 'attention-control',
  abstract_pattern: 'input -> compute_importance -> allocate_resources -> output',
  dependencies: [],
  metadata: {
    complexity: 'high',
    real_time: true
  }
};

// Transform to all languages
console.log('Transforming cognitive idea to multiple languages...');
const result = agent.transformCognitiveIdea(myIdea);

console.log(`Success: ${result.success}`);
console.log(`Generated ${result.implementations.size} implementations`);
console.log(`Selected language: ${result.selected_language}`);
console.log(`Transformation time: ${result.transformation_time_ms.toFixed(2)}ms`);

// Inspect Racket implementation
const racketImpl = result.implementations.get('Racket');
if (racketImpl) {
  console.log('\n--- Racket Implementation ---');
  console.log(racketImpl.code.substring(0, 500) + '...');
}

// Inspect Clojure implementation
const clojureImpl = result.implementations.get('Clojure');
if (clojureImpl) {
  console.log('\n--- Clojure Implementation ---');
  console.log(clojureImpl.code.substring(0, 500) + '...');
}
```

## Example 3: Complete Cognitive Workflow

Combine learning and transformation in a complete workflow.

```typescript
import { 
  createEnhancedCogNanoAgent,
  ExampleCognitiveIdeas 
} from './src/core/EnhancedCogNanoAgent';

async function runCognitiveWorkflow() {
  // Create high-performance agent
  const agent = createEnhancedCogNanoAgent('high-performance');
  
  // Prepare training data
  const inputPatterns = [
    new Float32Array(128).fill(0).map(() => Math.random()),
    new Float32Array(128).fill(0).map(() => Math.random()),
    new Float32Array(128).fill(0).map(() => Math.random())
  ];
  
  const targetPatterns = [
    new Float32Array(64).fill(0).map(() => Math.random()),
    new Float32Array(64).fill(0).map(() => Math.random()),
    new Float32Array(64).fill(0).map(() => Math.random())
  ];
  
  // Define ideas to transform
  const ideas = [
    ExampleCognitiveIdeas.patternRecognition,
    ExampleCognitiveIdeas.knowledgeTransformation,
    ExampleCognitiveIdeas.reasoningChain
  ];
  
  console.log('Running complete cognitive workflow...');
  
  // Execute workflow
  const workflow = await agent.processCognitiveWorkflow(
    inputPatterns,
    targetPatterns,
    ideas
  );
  
  // Report results
  console.log('\n=== Workflow Results ===');
  console.log(`Training losses: ${workflow.training_losses.join(', ')}`);
  console.log(`Ideas transformed: ${workflow.transformations.length}`);
  
  workflow.transformations.forEach((t, i) => {
    console.log(`\nIdea ${i + 1}: ${t.idea.name}`);
    console.log(`  Implementations: ${t.implementations.size}`);
    console.log(`  Selected: ${t.selected_language}`);
    console.log(`  Time: ${t.transformation_time_ms.toFixed(2)}ms`);
  });
  
  console.log('\n=== Final Metrics ===');
  const metrics = workflow.final_metrics;
  console.log(`Total training steps: ${metrics.total_training_steps}`);
  console.log(`Average loss: ${metrics.average_loss.toFixed(4)}`);
  console.log(`Convergence score: ${metrics.convergence_score.toFixed(4)}`);
}

runCognitiveWorkflow().catch(console.error);
```

## Example 4: Custom Language Bridge

Add support for a new programming language.

```typescript
import { 
  CognitiveGripFabric,
  LanguageBridge,
  LanguageParadigm,
  CognitiveIdea,
  OperationalImplementation
} from './src/core/CognitiveGripFabric';

// Create a custom Haskell bridge
class HaskellBridge implements LanguageBridge {
  language = 'Haskell';
  paradigm = LanguageParadigm.FUNCTIONAL;
  
  transform(idea: CognitiveIdea): OperationalImplementation {
    const code = this.generateHaskellCode(idea);
    
    return {
      id: `haskell_${idea.id}`,
      idea_id: idea.id,
      language: this.language,
      paradigm: this.paradigm,
      code,
      interface_definition: '{}',
      runtime_requirements: ['ghc >= 9.0'],
      performance_characteristics: {
        time_complexity: 'O(n)',
        space_complexity: 'O(n)',
        parallelizable: true
      }
    };
  }
  
  private generateHaskellCode(idea: CognitiveIdea): string {
    return `-- ${idea.name}
-- ${idea.description}

module Cognitive.${this.toPascalCase(idea.name)} where

-- Main cognitive function
${this.toCamelCase(idea.name)} :: Input -> Output
${this.toCamelCase(idea.name)} input = 
  case input of
    Pattern data -> processPattern data
    Transform source target -> transformRepresentation source target
    _ -> error "Unknown cognitive pattern"

-- Helper functions
processPattern :: [a] -> [a]
processPattern = id

transformRepresentation :: [a] -> TargetType -> [b]
transformRepresentation source target = map (applyTransformation target) source

applyTransformation :: TargetType -> a -> b
applyTransformation Symbolic x = show x
applyTransformation Numeric x = read (show x) :: Double
`;
  }
  
  generateInterface(impl: OperationalImplementation): string {
    return impl.interface_definition;
  }
  
  validate(impl: OperationalImplementation): boolean {
    return impl.code.includes('module ');
  }
  
  private toCamelCase(str: string): string {
    return str.replace(/\s+/g, '').replace(/^./, s => s.toLowerCase());
  }
  
  private toPascalCase(str: string): string {
    return str.replace(/\s+/g, '').replace(/^./, s => s.toUpperCase());
  }
}

// Use the custom bridge
const fabric = new CognitiveGripFabric();
fabric.registerBridge(new HaskellBridge());

const idea = {
  id: 'custom_001',
  name: 'Custom Processor',
  description: 'Custom cognitive processing',
  domain: 'custom',
  abstract_pattern: 'input -> process -> output',
  dependencies: [],
  metadata: {}
};

const haskellImpl = fabric.transformToLanguage(idea, 'Haskell');
console.log('Haskell implementation:');
console.log(haskellImpl?.code);
```

## Example 5: Integration with AtomSpace

Integrate learned embeddings with the existing AtomSpace system.

```typescript
import { createEnhancedCogNanoAgent } from './src/core/EnhancedCogNanoAgent';
import { AtomSpaceAtom } from './src/hooks/useEnhancedAtomSpace';

// Create agent
const agent = createEnhancedCogNanoAgent('default');

// Convert AtomSpace atom to embedding
function atomToEmbedding(atom: AtomSpaceAtom): Float32Array {
  // Extract features from atom
  const features = new Float32Array(64);
  
  // Encode atom type (simple one-hot encoding)
  const typeHash = atom.type.split('').reduce((h, c) => h + c.charCodeAt(0), 0);
  features[typeHash % 32] = 1.0;
  
  // Encode truth value
  features[32] = atom.truthValue.strength;
  features[33] = atom.truthValue.confidence;
  
  // Encode attention value
  features[34] = atom.attentionValue.sti / 100;
  features[35] = atom.attentionValue.lti / 100;
  
  return features;
}

// Example atom
const exampleAtom: AtomSpaceAtom = {
  id: 'atom_001',
  type: 'ConceptNode',
  name: 'consciousness',
  truthValue: { strength: 0.8, confidence: 0.9 },
  attentionValue: { sti: 50, lti: 30, vlti: false }
};

// Generate embedding
const atomFeatures = atomToEmbedding(exampleAtom);
const embedding = agent.generateEmbedding(atomFeatures);

console.log('Atom:', exampleAtom.name);
console.log('Embedding (first 10 dims):', embedding.slice(0, 10));

// Use embedding for similarity search or reasoning
```

## Running the Examples

1. **Setup**: Ensure you have installed dependencies:
   ```bash
   npm install
   ```

2. **Development**: Start the dev server to test in browser:
   ```bash
   npm run dev
   ```

3. **Testing**: Run the test suite:
   ```bash
   node test-runner.mjs
   ```

## Next Steps

- Explore the full API documentation in `docs/ENHANCED_COGNANO_SYSTEM.md`
- Experiment with different agent presets ('default', 'high-performance', 'minimal')
- Try creating custom language bridges for your favorite languages
- Integrate with existing NanoBrain components (AtomSpace, Time Crystals, etc.)

## Troubleshooting

**Issue**: Training loss not decreasing
- **Solution**: Increase learning rate or train for more epochs

**Issue**: Language transformation fails
- **Solution**: Check that the cognitive idea has valid abstract_pattern

**Issue**: Memory usage too high
- **Solution**: Use 'minimal' preset or reduce embedding dimensions

## Additional Resources

- [Full Documentation](docs/ENHANCED_COGNANO_SYSTEM.md)
- [Torch7 nn Module Reference](https://github.com/torch/nn)
- [GGML Tensor Architecture](docs/GGML_TENSOR_ARCHITECTURE.md)
