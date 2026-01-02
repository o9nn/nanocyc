/**
 * Test Suite for Enhanced CogNano Agent System
 * 
 * Tests for:
 * - Learnability embeddings
 * - Cognitive grip fabric
 * - Enhanced CogNano agent integration
 */

import {
  LinearModule,
  TanhModule,
  SigmoidModule,
  ReLUModule,
  SequentialModule,
  EmbeddingModule,
  MSECriterion,
  Trainer
} from './LearnabilityEmbeddings';

import {
  CognitiveGripFabric,
  RacketBridge,
  ClojureBridge,
  SchemeBridge,
  PerlBridge,
  RakuBridge,
  ExampleCognitiveIdeas
} from './CognitiveGripFabric';

import {
  EnhancedCogNanoAgent,
  createEnhancedCogNanoAgent,
  CogNanoExamples
} from './EnhancedCogNanoAgent';

import { GgmlTensor } from './GgmlTensorKernel';

/**
 * Test result interface
 */
export interface TestResult {
  test_name: string;
  passed: boolean;
  error?: string;
  duration_ms: number;
  details?: Record<string, unknown>;
}

/**
 * Test suite for learnability embeddings
 */
export class LearnabilityEmbeddingsTestSuite {
  private results: TestResult[] = [];
  
  /**
   * Test linear module forward pass
   */
  testLinearForward(): TestResult {
    const startTime = performance.now();
    const test_name = 'Linear Module Forward Pass';
    
    try {
      const linear = new LinearModule(4, 3);
      const input: GgmlTensor = {
        id: 'test_input',
        shape: [2, 4],
        data: new Float32Array([1, 2, 3, 4, 5, 6, 7, 8]),
        dtype: 'f32',
        requires_grad: true
      };
      
      const output = linear.forward(input);
      
      // Check output shape
      const shapeCorrect = output.shape[0] === 2 && output.shape[1] === 3;
      const dataExists = output.data.length === 6;
      
      if (!shapeCorrect || !dataExists) {
        throw new Error('Output shape or data incorrect');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: { output_shape: output.shape, output_size: output.data.length }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test activation functions
   */
  testActivations(): TestResult {
    const startTime = performance.now();
    const test_name = 'Activation Functions';
    
    try {
      const input: GgmlTensor = {
        id: 'test_input',
        shape: [1, 4],
        data: new Float32Array([-2, -1, 0, 1]),
        dtype: 'f32',
        requires_grad: true
      };
      
      // Test Tanh
      const tanh = new TanhModule();
      const tanhOutput = tanh.forward(input);
      
      // Test Sigmoid
      const sigmoid = new SigmoidModule();
      const sigmoidOutput = sigmoid.forward(input);
      
      // Test ReLU
      const relu = new ReLUModule();
      const reluOutput = relu.forward(input);
      
      // Verify ReLU zeroes negative values
      const reluCorrect = reluOutput.data[0] === 0 && 
                          reluOutput.data[1] === 0 &&
                          reluOutput.data[3] === 1;
      
      if (!reluCorrect) {
        throw new Error('Activation function output incorrect');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          tanh_output: Array.from(tanhOutput.data),
          sigmoid_output: Array.from(sigmoidOutput.data),
          relu_output: Array.from(reluOutput.data)
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test sequential module
   */
  testSequential(): TestResult {
    const startTime = performance.now();
    const test_name = 'Sequential Module';
    
    try {
      const model = new SequentialModule(
        new LinearModule(4, 8),
        new TanhModule(),
        new LinearModule(8, 2),
        new SigmoidModule()
      );
      
      const input: GgmlTensor = {
        id: 'test_input',
        shape: [1, 4],
        data: new Float32Array([1, 2, 3, 4]),
        dtype: 'f32',
        requires_grad: true
      };
      
      model.training = false;
      const output = model.forward(input);
      
      // Check output shape
      const shapeCorrect = output.shape[0] === 1 && output.shape[1] === 2;
      
      if (!shapeCorrect) {
        throw new Error('Sequential output shape incorrect');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          output_shape: output.shape,
          output_values: Array.from(output.data)
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test embedding module
   */
  testEmbedding(): TestResult {
    const startTime = performance.now();
    const test_name = 'Embedding Module';
    
    try {
      const embedding = new EmbeddingModule(10, 5);
      const input: GgmlTensor = {
        id: 'test_input',
        shape: [3, 1],
        data: new Float32Array([0, 5, 9]),
        dtype: 'f32',
        requires_grad: false
      };
      
      const output = embedding.forward(input);
      
      // Check output shape
      const shapeCorrect = output.shape[0] === 3 && output.shape[1] === 5;
      
      if (!shapeCorrect) {
        throw new Error('Embedding output shape incorrect');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          output_shape: output.shape,
          embedding_sample: Array.from(output.data.slice(0, 5))
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test training loop
   */
  testTraining(): TestResult {
    const startTime = performance.now();
    const test_name = 'Training Loop';
    
    try {
      const model = new SequentialModule(
        new LinearModule(2, 4),
        new TanhModule(),
        new LinearModule(4, 1),
        new SigmoidModule()
      );
      
      const criterion = new MSECriterion();
      const trainer = new Trainer(model, criterion, 0.1);
      
      const input: GgmlTensor = {
        id: 'train_input',
        shape: [1, 2],
        data: new Float32Array([0.5, 0.5]),
        dtype: 'f32',
        requires_grad: true
      };
      
      const target: GgmlTensor = {
        id: 'train_target',
        shape: [1, 1],
        data: new Float32Array([1.0]),
        dtype: 'f32',
        requires_grad: false
      };
      
      // Train for a few iterations
      const losses: number[] = [];
      for (let i = 0; i < 10; i++) {
        const loss = trainer.train(input, target);
        losses.push(loss);
      }
      
      // Check that loss decreased
      const lossDecreased = losses[losses.length - 1] < losses[0];
      
      const result: TestResult = {
        test_name,
        passed: lossDecreased,
        duration_ms: performance.now() - startTime,
        details: {
          initial_loss: losses[0],
          final_loss: losses[losses.length - 1],
          all_losses: losses
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Run all tests
   */
  runAll(): TestResult[] {
    console.log('Running Learnability Embeddings Tests...');
    
    this.testLinearForward();
    this.testActivations();
    this.testSequential();
    this.testEmbedding();
    this.testTraining();
    
    return this.results;
  }
  
  /**
   * Get test results
   */
  getResults(): TestResult[] {
    return this.results;
  }
  
  /**
   * Print summary
   */
  printSummary(): void {
    const passed = this.results.filter(r => r.passed).length;
    const total = this.results.length;
    
    console.log('\n=== Learnability Embeddings Test Summary ===');
    console.log(`Passed: ${passed}/${total}`);
    console.log(`Failed: ${total - passed}/${total}`);
    
    this.results.forEach(result => {
      const status = result.passed ? '✓' : '✗';
      console.log(`${status} ${result.test_name} (${result.duration_ms.toFixed(2)}ms)`);
      if (!result.passed) {
        console.log(`  Error: ${result.error}`);
      }
    });
  }
}

/**
 * Test suite for cognitive grip fabric
 */
export class CognitiveGripFabricTestSuite {
  private results: TestResult[] = [];
  
  /**
   * Test language bridges
   */
  testLanguageBridges(): TestResult {
    const startTime = performance.now();
    const test_name = 'Language Bridges';
    
    try {
      const idea = ExampleCognitiveIdeas.patternRecognition;
      
      const racket = new RacketBridge();
      const clojure = new ClojureBridge();
      const scheme = new SchemeBridge();
      const perl = new PerlBridge();
      const raku = new RakuBridge();
      
      const racketImpl = racket.transform(idea);
      const clojureImpl = clojure.transform(idea);
      const schemeImpl = scheme.transform(idea);
      const perlImpl = perl.transform(idea);
      const rakuImpl = raku.transform(idea);
      
      const allValid = 
        racket.validate(racketImpl) &&
        clojure.validate(clojureImpl) &&
        scheme.validate(schemeImpl) &&
        perl.validate(perlImpl) &&
        raku.validate(rakuImpl);
      
      if (!allValid) {
        throw new Error('One or more language implementations invalid');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          languages_tested: 5,
          racket_valid: racket.validate(racketImpl),
          clojure_valid: clojure.validate(clojureImpl),
          scheme_valid: scheme.validate(schemeImpl),
          perl_valid: perl.validate(perlImpl),
          raku_valid: raku.validate(rakuImpl)
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test cognitive grip fabric
   */
  testCognitiveGripFabric(): TestResult {
    const startTime = performance.now();
    const test_name = 'Cognitive Grip Fabric';
    
    try {
      const fabric = new CognitiveGripFabric();
      const idea = ExampleCognitiveIdeas.knowledgeTransformation;
      
      const implementations = fabric.transformIdea(idea);
      
      const expectedLanguages = ['Racket', 'Clojure', 'Scheme', 'Perl', 'Raku'];
      const allLanguagesPresent = expectedLanguages.every(lang => 
        implementations.has(lang)
      );
      
      if (!allLanguagesPresent) {
        throw new Error('Not all languages generated implementations');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          implementations_count: implementations.size,
          languages: Array.from(implementations.keys())
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test interop layer generation
   */
  testInteropLayer(): TestResult {
    const startTime = performance.now();
    const test_name = 'Interop Layer Generation';
    
    try {
      const fabric = new CognitiveGripFabric();
      const idea = ExampleCognitiveIdeas.reasoningChain;
      
      const implementations = fabric.transformIdea(idea);
      const interopCode = fabric.generateInteropLayer(implementations);
      
      const hasContent = interopCode.length > 0;
      const hasLanguages = implementations.size > 0;
      
      if (!hasContent || !hasLanguages) {
        throw new Error('Interop layer generation failed');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          interop_code_length: interopCode.length,
          languages_count: implementations.size
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Run all tests
   */
  runAll(): TestResult[] {
    console.log('Running Cognitive Grip Fabric Tests...');
    
    this.testLanguageBridges();
    this.testCognitiveGripFabric();
    this.testInteropLayer();
    
    return this.results;
  }
  
  /**
   * Get test results
   */
  getResults(): TestResult[] {
    return this.results;
  }
  
  /**
   * Print summary
   */
  printSummary(): void {
    const passed = this.results.filter(r => r.passed).length;
    const total = this.results.length;
    
    console.log('\n=== Cognitive Grip Fabric Test Summary ===');
    console.log(`Passed: ${passed}/${total}`);
    console.log(`Failed: ${total - passed}/${total}`);
    
    this.results.forEach(result => {
      const status = result.passed ? '✓' : '✗';
      console.log(`${status} ${result.test_name} (${result.duration_ms.toFixed(2)}ms)`);
      if (!result.passed) {
        console.log(`  Error: ${result.error}`);
      }
    });
  }
}

/**
 * Test suite for enhanced CogNano agent
 */
export class EnhancedCogNanoAgentTestSuite {
  private results: TestResult[] = [];
  
  /**
   * Test agent creation
   */
  testAgentCreation(): TestResult {
    const startTime = performance.now();
    const test_name = 'Agent Creation';
    
    try {
      const agent = createEnhancedCogNanoAgent('default');
      const state = agent.getState();
      
      if (state.status !== 'ready') {
        throw new Error('Agent not in ready state');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          status: state.status,
          active_language: state.active_language
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test agent learning
   */
  testAgentLearning(): TestResult {
    const startTime = performance.now();
    const test_name = 'Agent Learning';
    
    try {
      const { agent, inputPatterns, targetPatterns } = CogNanoExamples.createLearningExample();
      
      const losses: number[] = [];
      for (let i = 0; i < inputPatterns.length; i++) {
        const loss = agent.trainOnPattern(inputPatterns[i], targetPatterns[i]);
        losses.push(loss);
      }
      
      const metrics = agent.getLearnabilityMetrics();
      
      if (metrics.total_training_steps !== inputPatterns.length) {
        throw new Error('Training step count incorrect');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          training_steps: metrics.total_training_steps,
          final_loss: metrics.current_loss,
          average_loss: metrics.average_loss
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test cognitive transformation
   */
  testCognitiveTransformation(): TestResult {
    const startTime = performance.now();
    const test_name = 'Cognitive Transformation';
    
    try {
      const { agent, ideas } = CogNanoExamples.createTransformationExample();
      
      const results = ideas.map(idea => agent.transformCognitiveIdea(idea));
      
      const allSuccessful = results.every(r => r.success);
      
      if (!allSuccessful) {
        throw new Error('Some transformations failed');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          ideas_transformed: results.length,
          total_implementations: results.reduce((sum, r) => sum + r.implementations.size, 0),
          selected_languages: results.map(r => r.selected_language)
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Test complete workflow
   */
  async testCompleteWorkflow(): Promise<TestResult> {
    const startTime = performance.now();
    const test_name = 'Complete Workflow';
    
    try {
      const agent = createEnhancedCogNanoAgent('minimal');
      
      const inputPatterns = [
        new Float32Array(32).fill(0).map((_, i) => i < 16 ? 1 : 0),
        new Float32Array(32).fill(0).map((_, i) => i < 16 ? 0 : 1)
      ];
      
      const targetPatterns = [
        new Float32Array(16).fill(0).map((_, i) => i < 8 ? 1 : 0),
        new Float32Array(16).fill(0).map((_, i) => i < 8 ? 0 : 1)
      ];
      
      const ideas = [ExampleCognitiveIdeas.patternRecognition];
      
      const workflow = await agent.processCognitiveWorkflow(
        inputPatterns,
        targetPatterns,
        ideas
      );
      
      const hasTraining = workflow.training_losses.length > 0;
      const hasTransformations = workflow.transformations.length > 0;
      
      if (!hasTraining || !hasTransformations) {
        throw new Error('Workflow incomplete');
      }
      
      const result: TestResult = {
        test_name,
        passed: true,
        duration_ms: performance.now() - startTime,
        details: {
          training_losses: workflow.training_losses,
          transformations_count: workflow.transformations.length,
          final_metrics: workflow.final_metrics
        }
      };
      
      this.results.push(result);
      return result;
    } catch (error) {
      const result: TestResult = {
        test_name,
        passed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration_ms: performance.now() - startTime
      };
      
      this.results.push(result);
      return result;
    }
  }
  
  /**
   * Run all tests
   */
  async runAll(): Promise<TestResult[]> {
    console.log('Running Enhanced CogNano Agent Tests...');
    
    this.testAgentCreation();
    this.testAgentLearning();
    this.testCognitiveTransformation();
    await this.testCompleteWorkflow();
    
    return this.results;
  }
  
  /**
   * Get test results
   */
  getResults(): TestResult[] {
    return this.results;
  }
  
  /**
   * Print summary
   */
  printSummary(): void {
    const passed = this.results.filter(r => r.passed).length;
    const total = this.results.length;
    
    console.log('\n=== Enhanced CogNano Agent Test Summary ===');
    console.log(`Passed: ${passed}/${total}`);
    console.log(`Failed: ${total - passed}/${total}`);
    
    this.results.forEach(result => {
      const status = result.passed ? '✓' : '✗';
      console.log(`${status} ${result.test_name} (${result.duration_ms.toFixed(2)}ms)`);
      if (!result.passed) {
        console.log(`  Error: ${result.error}`);
      }
    });
  }
}

/**
 * Master test suite runner
 */
export class MasterTestSuite {
  async runAllTests(): Promise<void> {
    console.log('='.repeat(60));
    console.log('Enhanced CogNano System - Master Test Suite');
    console.log('='.repeat(60));
    
    // Run learnability embeddings tests
    const embeddingsTests = new LearnabilityEmbeddingsTestSuite();
    embeddingsTests.runAll();
    embeddingsTests.printSummary();
    
    // Run cognitive grip fabric tests
    const fabricTests = new CognitiveGripFabricTestSuite();
    fabricTests.runAll();
    fabricTests.printSummary();
    
    // Run enhanced CogNano agent tests
    const agentTests = new EnhancedCogNanoAgentTestSuite();
    await agentTests.runAll();
    agentTests.printSummary();
    
    // Print overall summary
    const allResults = [
      ...embeddingsTests.getResults(),
      ...fabricTests.getResults(),
      ...agentTests.getResults()
    ];
    
    const totalPassed = allResults.filter(r => r.passed).length;
    const totalTests = allResults.length;
    
    console.log('\n' + '='.repeat(60));
    console.log('Overall Test Summary');
    console.log('='.repeat(60));
    console.log(`Total Tests: ${totalTests}`);
    console.log(`Passed: ${totalPassed} (${((totalPassed / totalTests) * 100).toFixed(1)}%)`);
    console.log(`Failed: ${totalTests - totalPassed} (${(((totalTests - totalPassed) / totalTests) * 100).toFixed(1)}%)`);
    console.log('='.repeat(60));
  }
}

// Export for use in other modules
export { TestResult };
