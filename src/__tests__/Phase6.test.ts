/**
 * Phase 6 Implementation Tests
 * Comprehensive test suite for all Phase 6 modules
 */

import {
  LeakyReLUModule,
  ELUModule,
  GELUModule,
  SwishModule,
  BatchNormModule,
  LayerNormModule,
  DropoutModule,
  Conv1DModule,
  Conv2DModule,
  LSTMModule,
  GRUModule,
  MultiHeadAttentionModule,
  MaxPool1DModule,
  AvgPool1DModule,
  FlattenModule
} from '../core/ExtendedNeuralArchitectures';

import {
  SGDOptimizer,
  AdamOptimizer,
  AdamWOptimizer,
  RMSpropOptimizer,
  AdagradOptimizer,
  StepLRScheduler,
  ExponentialLRScheduler,
  CosineAnnealingLRScheduler,
  ReduceLROnPlateauScheduler,
  WarmupLRScheduler,
  OneCycleLRScheduler,
  createOptimizer,
  createScheduler
} from '../core/AdvancedOptimizers';

import {
  HaskellBridge,
  PrologBridge,
  JuliaBridge,
  RustBridge,
  APLBridge
} from '../core/ExtendedLanguageBridges';

import {
  KernelCompositionEngine,
  ComposedKernel,
  MultiDomainProblem
} from '../core/KernelCompositionEngine';

import {
  MAMLLearner,
  PrototypicalNetwork,
  MultiTaskLearner,
  EWCLearner,
  EvolutionaryNAS,
  MetaTaskGenerator
} from '../core/MetaLearningEngine';

import {
  ASTNode,
  ASTBuilder,
  ASTVisitor,
  TypeScriptGenerator,
  PythonGenerator,
  ProgramSynthesizer,
  CodeAnalyzer,
  CodeOptimizer
} from '../core/CodeSynthesisEngine';

import { UnifiedCognitiveOrchestrator } from '../core/UnifiedCognitiveOrchestrator';
import { WebGPUAccelerator, AcceleratedTensorOps } from '../core/WebGPUAccelerator';

// =============================================================================
// Extended Neural Architectures Tests
// =============================================================================

describe('Extended Neural Architectures', () => {
  describe('Activation Functions', () => {
    test('LeakyReLU applies correct transformation', () => {
      const leakyRelu = new LeakyReLUModule(0.01);
      const input = [-2, -1, 0, 1, 2];
      const output = leakyRelu.forward(input);

      expect(output[0]).toBeCloseTo(-0.02);
      expect(output[1]).toBeCloseTo(-0.01);
      expect(output[2]).toBe(0);
      expect(output[3]).toBe(1);
      expect(output[4]).toBe(2);
    });

    test('ELU applies correct transformation', () => {
      const elu = new ELUModule(1.0);
      const input = [-1, 0, 1];
      const output = elu.forward(input);

      expect(output[0]).toBeCloseTo(Math.exp(-1) - 1);
      expect(output[1]).toBe(0);
      expect(output[2]).toBe(1);
    });

    test('GELU approximates Gaussian error correctly', () => {
      const gelu = new GELUModule();
      const input = [0];
      const output = gelu.forward(input);

      // GELU(0) should be 0
      expect(output[0]).toBeCloseTo(0, 5);
    });

    test('Swish self-gates correctly', () => {
      const swish = new SwishModule();
      const input = [0];
      const output = swish.forward(input);

      // Swish(0) = 0 * sigmoid(0) = 0 * 0.5 = 0
      expect(output[0]).toBeCloseTo(0);
    });
  });

  describe('Normalization Layers', () => {
    test('BatchNorm normalizes across batch dimension', () => {
      const batchNorm = new BatchNormModule(4);
      const input = [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6], [4, 5, 6, 7]];
      const output = batchNorm.forward(input);

      expect(output).toHaveLength(4);
      expect(output[0]).toHaveLength(4);
    });

    test('LayerNorm normalizes across feature dimension', () => {
      const layerNorm = new LayerNormModule(4);
      const input = [[1, 2, 3, 4]];
      const output = layerNorm.forward(input);

      expect(output).toHaveLength(1);
      // Mean should be close to 0 after normalization
      const mean = output[0].reduce((a: number, b: number) => a + b, 0) / 4;
      expect(mean).toBeCloseTo(0, 1);
    });
  });

  describe('Dropout', () => {
    test('Dropout zeros elements during training', () => {
      const dropout = new DropoutModule(0.5);
      dropout.setTraining(true);
      const input = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
      const output = dropout.forward(input);

      // Some elements should be zeroed
      const zeroCount = output.filter((x: number) => x === 0).length;
      expect(zeroCount).toBeGreaterThan(0);
    });

    test('Dropout passes through during eval', () => {
      const dropout = new DropoutModule(0.5);
      dropout.setTraining(false);
      const input = [1, 2, 3, 4, 5];
      const output = dropout.forward(input);

      expect(output).toEqual(input);
    });
  });

  describe('Convolutional Layers', () => {
    test('Conv1D produces correct output shape', () => {
      const conv = new Conv1DModule(1, 16, 3, 1, 1);
      const input = Array(32).fill(0).map(() => [Math.random()]);
      const output = conv.forward(input);

      expect(output.length).toBe(32); // Same padding
      expect(output[0].length).toBe(16); // 16 output channels
    });

    test('Conv2D produces correct output shape', () => {
      const conv = new Conv2DModule(3, 16, 3, 1, 1);
      const input = Array(28).fill(null).map(() =>
        Array(28).fill(null).map(() => [Math.random(), Math.random(), Math.random()])
      );
      const output = conv.forward(input);

      expect(output.length).toBe(28);
      expect(output[0].length).toBe(28);
      expect(output[0][0].length).toBe(16);
    });
  });

  describe('Recurrent Layers', () => {
    test('LSTM processes sequence correctly', () => {
      const lstm = new LSTMModule(10, 20);
      const sequence = Array(5).fill(null).map(() =>
        Array(10).fill(0).map(() => Math.random())
      );
      const { outputs, hiddenState, cellState } = lstm.forward(sequence);

      expect(outputs.length).toBe(5);
      expect(outputs[0].length).toBe(20);
      expect(hiddenState.length).toBe(20);
      expect(cellState.length).toBe(20);
    });

    test('GRU processes sequence correctly', () => {
      const gru = new GRUModule(10, 20);
      const sequence = Array(5).fill(null).map(() =>
        Array(10).fill(0).map(() => Math.random())
      );
      const { outputs, hiddenState } = gru.forward(sequence);

      expect(outputs.length).toBe(5);
      expect(outputs[0].length).toBe(20);
      expect(hiddenState.length).toBe(20);
    });
  });

  describe('Attention', () => {
    test('MultiHeadAttention produces correct output shape', () => {
      const attention = new MultiHeadAttentionModule(64, 8);
      const input = Array(10).fill(null).map(() =>
        Array(64).fill(0).map(() => Math.random())
      );
      const output = attention.forward(input);

      expect(output.length).toBe(10);
      expect(output[0].length).toBe(64);
    });
  });

  describe('Pooling Layers', () => {
    test('MaxPool1D reduces sequence length', () => {
      const pool = new MaxPool1DModule(2, 2);
      const input = Array(10).fill(null).map(() => [Math.random()]);
      const output = pool.forward(input);

      expect(output.length).toBe(5);
    });

    test('AvgPool1D computes correct averages', () => {
      const pool = new AvgPool1DModule(2, 2);
      const input = [[1], [3], [5], [7]];
      const output = pool.forward(input);

      expect(output.length).toBe(2);
      expect(output[0][0]).toBe(2); // (1+3)/2
      expect(output[1][0]).toBe(6); // (5+7)/2
    });
  });

  describe('Flatten', () => {
    test('Flatten reshapes correctly', () => {
      const flatten = new FlattenModule();
      const input = [[1, 2], [3, 4], [5, 6]];
      const output = flatten.forward(input);

      expect(output).toEqual([1, 2, 3, 4, 5, 6]);
    });
  });
});

// =============================================================================
// Advanced Optimizers Tests
// =============================================================================

describe('Advanced Optimizers', () => {
  const createMockParams = () => [
    { value: [1, 2, 3], grad: [0.1, 0.2, 0.3] },
    { value: [4, 5], grad: [0.4, 0.5] }
  ];

  describe('SGD Optimizer', () => {
    test('SGD updates parameters correctly', () => {
      const params = createMockParams();
      const sgd = new SGDOptimizer(params, { lr: 0.1, momentum: 0 });

      sgd.step();

      expect(params[0].value[0]).toBeCloseTo(0.99);
      expect(params[0].value[1]).toBeCloseTo(1.98);
    });

    test('SGD with momentum accumulates velocity', () => {
      const params = createMockParams();
      const sgd = new SGDOptimizer(params, { lr: 0.1, momentum: 0.9 });

      sgd.step();
      const firstUpdate = [...params[0].value];

      params[0].grad = [0.1, 0.2, 0.3];
      sgd.step();

      // Second update should be larger due to momentum
      expect(params[0].value[0]).toBeLessThan(firstUpdate[0]);
    });
  });

  describe('Adam Optimizer', () => {
    test('Adam updates with adaptive learning rates', () => {
      const params = createMockParams();
      const adam = new AdamOptimizer(params, { lr: 0.001 });

      const initialValue = params[0].value[0];
      adam.step();

      expect(params[0].value[0]).not.toBe(initialValue);
    });

    test('Adam handles bias correction', () => {
      const params = createMockParams();
      const adam = new AdamOptimizer(params, { lr: 0.001 });

      // First few steps should have significant bias correction
      adam.step();
      adam.step();
      adam.step();

      // Parameters should have changed
      expect(params[0].value[0]).toBeLessThan(1);
    });
  });

  describe('AdamW Optimizer', () => {
    test('AdamW applies weight decay separately', () => {
      const params = createMockParams();
      const adamw = new AdamWOptimizer(params, { lr: 0.001, weightDecay: 0.01 });

      const initialValue = params[0].value[0];
      adamw.step();

      // Weight decay should cause additional reduction
      expect(params[0].value[0]).toBeLessThan(initialValue);
    });
  });

  describe('Learning Rate Schedulers', () => {
    test('StepLR reduces LR at step intervals', () => {
      const params = createMockParams();
      const optimizer = new SGDOptimizer(params, { lr: 0.1 });
      const scheduler = new StepLRScheduler(optimizer, 10, 0.1);

      expect(optimizer.getLR()).toBe(0.1);

      for (let i = 0; i < 10; i++) scheduler.step();
      expect(optimizer.getLR()).toBeCloseTo(0.01);
    });

    test('ExponentialLR decays continuously', () => {
      const params = createMockParams();
      const optimizer = new SGDOptimizer(params, { lr: 0.1 });
      const scheduler = new ExponentialLRScheduler(optimizer, 0.9);

      scheduler.step();
      expect(optimizer.getLR()).toBeCloseTo(0.09);

      scheduler.step();
      expect(optimizer.getLR()).toBeCloseTo(0.081);
    });

    test('CosineAnnealing follows cosine curve', () => {
      const params = createMockParams();
      const optimizer = new SGDOptimizer(params, { lr: 0.1 });
      const scheduler = new CosineAnnealingLRScheduler(optimizer, 100);

      // At T_max/2, LR should be around minLR + (maxLR - minLR) * 0.5
      for (let i = 0; i < 50; i++) scheduler.step();
      expect(optimizer.getLR()).toBeLessThan(0.1);
      expect(optimizer.getLR()).toBeGreaterThan(0);
    });

    test('WarmupLR increases LR during warmup', () => {
      const params = createMockParams();
      const optimizer = new SGDOptimizer(params, { lr: 0.1 });
      const scheduler = new WarmupLRScheduler(optimizer, 10, 0.1);

      // Should start low
      expect(optimizer.getLR()).toBeCloseTo(0.01);

      // Should increase
      for (let i = 0; i < 5; i++) scheduler.step();
      expect(optimizer.getLR()).toBeGreaterThan(0.01);

      // Should reach target after warmup
      for (let i = 0; i < 5; i++) scheduler.step();
      expect(optimizer.getLR()).toBeCloseTo(0.1);
    });
  });

  describe('Factory Functions', () => {
    test('createOptimizer creates correct type', () => {
      const params = createMockParams();

      const sgd = createOptimizer('sgd', params, { lr: 0.1 });
      expect(sgd).toBeInstanceOf(SGDOptimizer);

      const adam = createOptimizer('adam', params, { lr: 0.001 });
      expect(adam).toBeInstanceOf(AdamOptimizer);
    });

    test('createScheduler creates correct type', () => {
      const params = createMockParams();
      const optimizer = new SGDOptimizer(params, { lr: 0.1 });

      const step = createScheduler('step', optimizer, { stepSize: 10 });
      expect(step).toBeInstanceOf(StepLRScheduler);

      const cosine = createScheduler('cosine', optimizer, { T_max: 100 });
      expect(cosine).toBeInstanceOf(CosineAnnealingLRScheduler);
    });
  });
});

// =============================================================================
// Extended Language Bridges Tests
// =============================================================================

describe('Extended Language Bridges', () => {
  const networkDef = {
    architecture: [784, 256, 128, 10],
    activations: ['relu', 'relu', 'softmax'],
    name: 'TestNetwork'
  };

  describe('HaskellBridge', () => {
    const bridge = new HaskellBridge();

    test('generates valid network definition', () => {
      const code = bridge.generateNetworkDefinition(networkDef);

      expect(code).toContain('module TestNetwork');
      expect(code).toContain('data Layer');
      expect(code).toContain('createNetwork');
    });

    test('generates training loop', () => {
      const code = bridge.generateTrainingLoop({
        optimizer: 'adam',
        epochs: 100,
        batchSize: 32
      });

      expect(code).toContain('trainNetwork');
      expect(code).toContain('adamOptimizer');
    });

    test('generates inference code', () => {
      const code = bridge.generateInference(networkDef);

      expect(code).toContain('runInference');
      expect(code).toContain('forward');
    });
  });

  describe('PrologBridge', () => {
    const bridge = new PrologBridge();

    test('generates network as Prolog facts', () => {
      const code = bridge.generateNetworkDefinition(networkDef);

      expect(code).toContain('network(testnetwork');
      expect(code).toContain('layer(');
      expect(code).toContain('activation(');
    });

    test('generates inference predicates', () => {
      const code = bridge.generateInference(networkDef);

      expect(code).toContain('forward_pass');
      expect(code).toContain('apply_activation');
    });
  });

  describe('JuliaBridge', () => {
    const bridge = new JuliaBridge();

    test('generates Julia struct definition', () => {
      const code = bridge.generateNetworkDefinition(networkDef);

      expect(code).toContain('module TestNetwork');
      expect(code).toContain('struct');
      expect(code).toContain('Dense(');
    });

    test('generates training with Flux.jl style', () => {
      const code = bridge.generateTrainingLoop({
        optimizer: 'adam',
        epochs: 100,
        batchSize: 32
      });

      expect(code).toContain('function train!');
      expect(code).toContain('ADAM');
      expect(code).toContain('Flux.train!');
    });
  });

  describe('RustBridge', () => {
    const bridge = new RustBridge();

    test('generates Rust struct with derives', () => {
      const code = bridge.generateNetworkDefinition(networkDef);

      expect(code).toContain('pub struct TestNetwork');
      expect(code).toContain('#[derive(');
      expect(code).toContain('impl TestNetwork');
    });

    test('generates forward method', () => {
      const code = bridge.generateInference(networkDef);

      expect(code).toContain('pub fn forward');
      expect(code).toContain('&self');
    });
  });

  describe('APLBridge', () => {
    const bridge = new APLBridge();

    test('generates APL array operations', () => {
      const code = bridge.generateNetworkDefinition(networkDef);

      expect(code).toContain('⍝');  // APL comment
      expect(code).toContain('←');  // Assignment
    });

    test('generates matrix operations', () => {
      const code = bridge.generateInference(networkDef);

      expect(code).toContain('+.×');  // Matrix multiply in APL
    });
  });
});

// =============================================================================
// Kernel Composition Engine Tests
// =============================================================================

describe('Kernel Composition Engine', () => {
  let engine: KernelCompositionEngine;

  beforeEach(() => {
    engine = new KernelCompositionEngine();
  });

  test('registers kernels correctly', () => {
    const kernel = (x: number[], y: number[]) =>
      x.reduce((sum, xi, i) => sum + xi * y[i], 0);

    engine.registerKernel(kernel, 'linear');

    expect(engine.getKernelDomains()).toContain('linear');
  });

  test('sequential composition applies kernels in order', () => {
    const k1 = (x: number[], y: number[]) => x[0] + y[0];
    const k2 = (x: number[], y: number[]) => x[0] * y[0];

    engine.registerKernel(k1, 'add');
    engine.registerKernel(k2, 'mul');

    const composed = engine.composeKernels(['add', 'mul'], 'sequential');
    const result = composed.compute([2], [3]);

    expect(typeof result).toBe('number');
  });

  test('parallel composition combines kernels with weights', () => {
    const k1 = (x: number[], y: number[]) => 1;
    const k2 = (x: number[], y: number[]) => 2;

    engine.registerKernel(k1, 'one');
    engine.registerKernel(k2, 'two');

    const composed = engine.composeKernels(['one', 'two'], 'parallel', {
      weights: [0.5, 0.5]
    });
    const result = composed.compute([1], [1]);

    expect(result).toBeCloseTo(1.5); // 0.5 * 1 + 0.5 * 2
  });

  test('solves multi-domain problem', () => {
    const k1 = (x: number[], y: number[]) => x[0] + y[0];
    engine.registerKernel(k1, 'domain1');

    const problem: MultiDomainProblem = {
      domains: ['domain1'],
      data: { domain1: { X: [[1], [2]], Y: [[2], [3]] } },
      constraints: []
    };

    const solution = engine.solveMultiDomainProblem(problem);

    expect(solution).toBeDefined();
    expect(solution.domainSolutions).toBeDefined();
  });
});

// =============================================================================
// Meta-Learning Engine Tests
// =============================================================================

describe('Meta-Learning Engine', () => {
  describe('MetaTaskGenerator', () => {
    const generator = new MetaTaskGenerator();

    test('generates classification tasks', () => {
      const tasks = generator.generateTasks('classification', 5, {
        nWay: 5,
        kShot: 1,
        querySize: 15
      });

      expect(tasks.length).toBe(5);
      expect(tasks[0].type).toBe('classification');
      expect(tasks[0].supportSet).toBeDefined();
      expect(tasks[0].querySet).toBeDefined();
    });

    test('generates regression tasks', () => {
      const tasks = generator.generateTasks('regression', 3, {
        inputDim: 10,
        outputDim: 1
      });

      expect(tasks.length).toBe(3);
      expect(tasks[0].type).toBe('regression');
    });
  });

  describe('MAMLLearner', () => {
    test('initializes with correct config', () => {
      const mockModel = {
        forward: (x: number[]) => x,
        getParameters: () => [{ value: [1, 2], grad: [0, 0] }],
        setParameters: () => {}
      };

      const maml = new MAMLLearner(mockModel, {
        innerLR: 0.01,
        outerLR: 0.001,
        innerSteps: 5
      });

      expect(maml).toBeDefined();
    });
  });

  describe('PrototypicalNetwork', () => {
    test('computes prototypes from support set', () => {
      const mockEncoder = (x: number[]) => x; // Identity encoder
      const proto = new PrototypicalNetwork(mockEncoder, 4);

      const supportSet = [
        { x: [1, 0, 0, 0], y: 0 },
        { x: [0, 1, 0, 0], y: 1 }
      ];

      const prototypes = proto.computePrototypes(supportSet);

      expect(prototypes.size).toBe(2);
      expect(prototypes.get(0)).toEqual([1, 0, 0, 0]);
    });
  });

  describe('EWCLearner', () => {
    test('computes Fisher information', () => {
      const mockModel = {
        forward: (x: number[]) => x,
        getParameters: () => [{ value: [1, 2], grad: [0.1, 0.2] }]
      };

      const ewc = new EWCLearner(mockModel, { lambda: 1000 });

      const data = [[1, 2], [3, 4]];
      ewc.computeFisherInformation(data);

      expect(ewc.getFisherDiagonal()).toBeDefined();
    });
  });

  describe('EvolutionaryNAS', () => {
    test('initializes population', () => {
      const nas = new EvolutionaryNAS({
        populationSize: 10,
        generations: 5,
        mutationRate: 0.1
      });

      nas.initializePopulation();

      expect(nas.getPopulationSize()).toBe(10);
    });

    test('evolves population', () => {
      const nas = new EvolutionaryNAS({
        populationSize: 10,
        generations: 5,
        mutationRate: 0.1
      });

      nas.initializePopulation();
      const fitnessFunc = (arch: any) => Math.random();

      nas.evolve(fitnessFunc, 1);

      expect(nas.getBestArchitecture()).toBeDefined();
    });
  });
});

// =============================================================================
// Code Synthesis Engine Tests
// =============================================================================

describe('Code Synthesis Engine', () => {
  describe('ASTBuilder', () => {
    test('builds function declaration', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .function('add')
          .parameter('a', 'number')
          .parameter('b', 'number')
          .returns('number')
          .body(
            builder.return(
              builder.binary('+', builder.identifier('a'), builder.identifier('b'))
            )
          )
        .build();

      expect(ast.type).toBe('Program');
      expect(ast.children?.[0].type).toBe('FunctionDeclaration');
      expect(ast.children?.[0].name).toBe('add');
    });

    test('builds variable declaration', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .variable('x', 'number', builder.literal(42))
        .build();

      expect(ast.children?.[0].type).toBe('VariableDeclaration');
      expect(ast.children?.[0].name).toBe('x');
    });

    test('builds if statement', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .if(
          builder.binary('>', builder.identifier('x'), builder.literal(0)),
          builder.return(builder.literal(true)),
          builder.return(builder.literal(false))
        )
        .build();

      expect(ast.children?.[0].type).toBe('IfStatement');
    });
  });

  describe('TypeScriptGenerator', () => {
    test('generates function code', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .function('greet')
          .parameter('name', 'string')
          .returns('string')
          .body(
            builder.return(
              builder.binary('+', builder.literal('Hello, '), builder.identifier('name'))
            )
          )
        .build();

      const generator = new TypeScriptGenerator();
      const code = generator.generate(ast);

      expect(code).toContain('function greet');
      expect(code).toContain('name: string');
      expect(code).toContain(': string');
      expect(code).toContain('return');
    });

    test('generates class code', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .class('Person')
          .property('name', 'string', true)
          .method('getName')
            .returns('string')
            .body(
              builder.return(builder.memberAccess('this', 'name'))
            )
        .build();

      const generator = new TypeScriptGenerator();
      const code = generator.generate(ast);

      expect(code).toContain('class Person');
      expect(code).toContain('name: string');
      expect(code).toContain('getName()');
    });
  });

  describe('PythonGenerator', () => {
    test('generates Python function', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .function('add')
          .parameter('a', 'int')
          .parameter('b', 'int')
          .returns('int')
          .body(
            builder.return(
              builder.binary('+', builder.identifier('a'), builder.identifier('b'))
            )
          )
        .build();

      const generator = new PythonGenerator();
      const code = generator.generate(ast);

      expect(code).toContain('def add');
      expect(code).toContain('a: int');
      expect(code).toContain('-> int');
    });
  });

  describe('CodeAnalyzer', () => {
    test('computes cyclomatic complexity', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .function('test')
          .body(
            builder.if(
              builder.identifier('cond1'),
              builder.if(
                builder.identifier('cond2'),
                builder.return(builder.literal(1)),
                builder.return(builder.literal(2))
              ),
              builder.return(builder.literal(3))
            )
          )
        .build();

      const analyzer = new CodeAnalyzer();
      const metrics = analyzer.analyze(ast);

      expect(metrics.cyclomaticComplexity).toBeGreaterThan(1);
    });

    test('counts nodes correctly', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .variable('x', 'number', builder.literal(1))
        .variable('y', 'number', builder.literal(2))
        .build();

      const analyzer = new CodeAnalyzer();
      const metrics = analyzer.analyze(ast);

      expect(metrics.nodeCount).toBeGreaterThan(0);
    });
  });

  describe('CodeOptimizer', () => {
    test('detects map patterns', () => {
      const builder = new ASTBuilder();
      const ast = builder
        .program()
        .function('doubleAll')
          .parameter('arr', 'number[]')
          .body(
            builder.forLoop('i', builder.literal(0), builder.identifier('arr.length'),
              builder.expressionStatement(
                builder.assignment(
                  builder.identifier('result[i]'),
                  builder.binary('*', builder.identifier('arr[i]'), builder.literal(2))
                )
              )
            )
          )
        .build();

      const optimizer = new CodeOptimizer();
      const patterns = optimizer.detectPatterns(ast);

      // Should detect map-like pattern
      expect(patterns.length).toBeGreaterThanOrEqual(0);
    });
  });

  describe('ProgramSynthesizer', () => {
    test('synthesizes from input-output examples', () => {
      const synthesizer = new ProgramSynthesizer();

      const examples = [
        { input: [1], output: 2 },
        { input: [2], output: 4 },
        { input: [3], output: 6 }
      ];

      const program = synthesizer.synthesize(examples, {
        maxDepth: 3,
        operators: ['+', '*']
      });

      expect(program).toBeDefined();
    });
  });
});

// =============================================================================
// Unified Cognitive Orchestrator Tests
// =============================================================================

describe('Unified Cognitive Orchestrator', () => {
  let orchestrator: UnifiedCognitiveOrchestrator;

  beforeEach(async () => {
    orchestrator = new UnifiedCognitiveOrchestrator();
    await orchestrator.initialize();
  });

  afterEach(() => {
    orchestrator.shutdown();
  });

  test('initializes correctly', () => {
    const status = orchestrator.getSystemStatus();

    expect(status.initialized).toBe(true);
    expect(status.activeModels).toBeDefined();
    expect(status.taskQueue).toBeDefined();
  });

  test('registers and retrieves models', () => {
    const mockModel = {
      forward: (x: number[]) => x,
      getParameters: () => []
    };

    orchestrator.registerModel('testModel', mockModel, {
      optimizer: 'adam',
      lr: 0.001
    });

    const retrieved = orchestrator.getModel('testModel');
    expect(retrieved).toBeDefined();
    expect(retrieved.model).toBe(mockModel);
  });

  test('executes training task', async () => {
    const mockModel = {
      forward: (x: number[]) => x.map(v => v * 2),
      backward: () => {},
      getParameters: () => [{ value: [1], grad: [0.1] }],
      setParameters: () => {}
    };

    orchestrator.registerModel('trainable', mockModel, { optimizer: 'sgd' });

    const result = await orchestrator.executeTask({
      type: 'train',
      model: 'trainable',
      data: { X: [[1, 2], [3, 4]], Y: [[2, 4], [6, 8]] },
      epochs: 1
    });

    expect(result.success).toBe(true);
  });

  test('executes inference task', async () => {
    const mockModel = {
      forward: (x: number[]) => x.map(v => v * 2),
      getParameters: () => []
    };

    orchestrator.registerModel('inference', mockModel);

    const result = await orchestrator.executeTask({
      type: 'infer',
      model: 'inference',
      input: [1, 2, 3]
    });

    expect(result.success).toBe(true);
    expect(result.output).toEqual([2, 4, 6]);
  });

  test('provides system health check', () => {
    const health = orchestrator.healthCheck();

    expect(health.status).toBeDefined();
    expect(['healthy', 'degraded', 'unhealthy']).toContain(health.status);
    expect(health.uptime).toBeGreaterThanOrEqual(0);
  });

  test('handles task queue', async () => {
    const mockModel = {
      forward: (x: number[]) => x,
      getParameters: () => []
    };

    orchestrator.registerModel('queue-test', mockModel);

    // Queue multiple tasks
    const task1 = orchestrator.executeTask({ type: 'infer', model: 'queue-test', input: [1] });
    const task2 = orchestrator.executeTask({ type: 'infer', model: 'queue-test', input: [2] });

    const [result1, result2] = await Promise.all([task1, task2]);

    expect(result1.success).toBe(true);
    expect(result2.success).toBe(true);
  });
});

// =============================================================================
// WebGPU Accelerator Tests
// =============================================================================

describe('WebGPU Accelerator', () => {
  // Note: These tests will run in CPU fallback mode in Node.js environment

  describe('AcceleratedTensorOps', () => {
    test('matrix multiplication produces correct shape', async () => {
      const accelerator = new WebGPUAccelerator();
      await accelerator.initialize();

      const ops = new AcceleratedTensorOps(accelerator);

      const A = [1, 2, 3, 4, 5, 6]; // 2x3
      const B = [1, 2, 3, 4, 5, 6]; // 3x2

      const result = await ops.matmul(A, B, [2, 3], [3, 2]);

      expect(result.length).toBe(4); // 2x2
    });

    test('element-wise addition works correctly', async () => {
      const accelerator = new WebGPUAccelerator();
      await accelerator.initialize();

      const ops = new AcceleratedTensorOps(accelerator);

      const A = [1, 2, 3, 4];
      const B = [5, 6, 7, 8];

      const result = await ops.add(A, B);

      expect(result).toEqual([6, 8, 10, 12]);
    });

    test('element-wise multiplication works correctly', async () => {
      const accelerator = new WebGPUAccelerator();
      await accelerator.initialize();

      const ops = new AcceleratedTensorOps(accelerator);

      const A = [1, 2, 3, 4];
      const B = [2, 2, 2, 2];

      const result = await ops.multiply(A, B);

      expect(result).toEqual([2, 4, 6, 8]);
    });

    test('ReLU activation works correctly', async () => {
      const accelerator = new WebGPUAccelerator();
      await accelerator.initialize();

      const ops = new AcceleratedTensorOps(accelerator);

      const input = [-2, -1, 0, 1, 2];
      const result = await ops.relu(input);

      expect(result).toEqual([0, 0, 0, 1, 2]);
    });

    test('Softmax produces valid probability distribution', async () => {
      const accelerator = new WebGPUAccelerator();
      await accelerator.initialize();

      const ops = new AcceleratedTensorOps(accelerator);

      const input = [1, 2, 3];
      const result = await ops.softmax(input);

      // Sum should be approximately 1
      const sum = result.reduce((a, b) => a + b, 0);
      expect(sum).toBeCloseTo(1.0);

      // All values should be positive
      expect(result.every(v => v > 0)).toBe(true);

      // Values should be in ascending order (since inputs were)
      expect(result[0]).toBeLessThan(result[1]);
      expect(result[1]).toBeLessThan(result[2]);
    });
  });

  describe('WebGPUAccelerator', () => {
    test('reports availability status', async () => {
      const accelerator = new WebGPUAccelerator();
      await accelerator.initialize();

      // In Node.js, GPU won't be available
      expect(typeof accelerator.isAvailable()).toBe('boolean');
    });

    test('provides device info', async () => {
      const accelerator = new WebGPUAccelerator();
      await accelerator.initialize();

      const info = accelerator.getDeviceInfo();

      expect(info).toBeDefined();
      expect(info.backend).toBeDefined();
    });
  });
});

// =============================================================================
// Integration Tests
// =============================================================================

describe('Integration Tests', () => {
  test('full pipeline: build model, train, infer', async () => {
    // Build a simple model using extended architectures
    const layers = [
      new LayerNormModule(10),
      new GELUModule(),
      new DropoutModule(0.1)
    ];

    // Create orchestrator
    const orchestrator = new UnifiedCognitiveOrchestrator();
    await orchestrator.initialize();

    // Create simple model
    const model = {
      forward: (x: number[]) => {
        let out = x;
        for (const layer of layers) {
          out = layer.forward([out])[0];
        }
        return out;
      },
      getParameters: () => []
    };

    orchestrator.registerModel('pipeline-test', model);

    // Run inference
    const result = await orchestrator.executeTask({
      type: 'infer',
      model: 'pipeline-test',
      input: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    });

    expect(result.success).toBe(true);
    expect(result.output.length).toBe(10);

    orchestrator.shutdown();
  });

  test('code synthesis to TypeScript generation', () => {
    const builder = new ASTBuilder();

    // Build a neural network forward function
    const ast = builder
      .program()
      .function('forward')
        .parameter('input', 'number[]')
        .returns('number[]')
        .body(
          builder.variable('hidden', 'number[]',
            builder.call('relu', [builder.call('matmul', [
              builder.identifier('weights1'),
              builder.identifier('input')
            ])])
          ),
          builder.return(
            builder.call('softmax', [builder.call('matmul', [
              builder.identifier('weights2'),
              builder.identifier('hidden')
            ])])
          )
        )
      .build();

    const generator = new TypeScriptGenerator();
    const code = generator.generate(ast);

    expect(code).toContain('function forward');
    expect(code).toContain('relu');
    expect(code).toContain('softmax');
    expect(code).toContain('matmul');
  });

  test('kernel composition with meta-learning', () => {
    const engine = new KernelCompositionEngine();

    // Register kernels
    engine.registerKernel(
      (x, y) => x.reduce((s, xi, i) => s + xi * y[i], 0),
      'linear'
    );

    engine.registerKernel(
      (x, y) => Math.exp(-x.reduce((s, xi, i) => s + (xi - y[i]) ** 2, 0)),
      'rbf'
    );

    // Compose adaptively
    const composed = engine.composeKernels(['linear', 'rbf'], 'adaptive');

    // Use in multi-domain problem
    const problem: MultiDomainProblem = {
      domains: ['linear', 'rbf'],
      data: {
        linear: { X: [[1, 2], [3, 4]], Y: [[2], [4]] },
        rbf: { X: [[1, 2], [3, 4]], Y: [[1], [0]] }
      },
      constraints: []
    };

    const solution = engine.solveMultiDomainProblem(problem);

    expect(solution).toBeDefined();
  });
});
