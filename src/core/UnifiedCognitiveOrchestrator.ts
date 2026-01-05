/**
 * Unified Cognitive Orchestrator - Phase 6
 *
 * Central system integration layer that connects all cognitive engines:
 * - Neural architectures coordination
 * - Kernel composition management
 * - Meta-learning integration
 * - Code synthesis pipeline
 * - Cross-system optimization
 * - Unified API for cognitive operations
 */

import { GgmlTensor, GgmlTensorKernel, AtomSpaceTensorConfig } from './GgmlTensorKernel';
import { NNModule, SequentialModule, LinearModule, Trainer, MSECriterion } from './LearnabilityEmbeddings';
import { ExtendedArchitectures, MultiHeadAttentionModule, LSTMModule, BatchNormModule, DropoutModule } from './ExtendedNeuralArchitectures';
import { Optimizers, Schedulers, createOptimizer, createScheduler, Optimizer, LRScheduler } from './AdvancedOptimizers';
import { CognitiveGripFabric, CognitiveIdea, OperationalImplementation } from './CognitiveGripFabric';
import { registerExtendedBridges } from './ExtendedLanguageBridges';
import { UniversalKernelGenerator, GeneratedKernel, DomainSpecification } from './UniversalKernelGenerator';
import { KernelCompositionEngine, ComposedKernel, CompositionStrategy, MultiDomainProblem } from './KernelCompositionEngine';
import { MAMLLearner, PrototypicalNetwork, MultiTaskLearner, MetaTask, EpisodeResult } from './MetaLearningEngine';
import { ASTBuilder, TypeScriptGenerator, PythonGenerator, ProgramSynthesizer, CodeAnalyzer, CodeOptimizer, FunctionNode, ProgramNode } from './CodeSynthesisEngine';

// ============================================================================
// ORCHESTRATOR INTERFACES
// ============================================================================

/**
 * Configuration for the orchestrator
 */
export interface OrchestratorConfig {
  // Neural network settings
  defaultEmbeddingDim: number;
  defaultHiddenDim: number;
  defaultAttentionHeads: number;

  // Training settings
  defaultLearningRate: number;
  defaultBatchSize: number;
  defaultOptimizer: 'adam' | 'adamw' | 'sgd' | 'rmsprop';

  // Meta-learning settings
  metaLearningEnabled: boolean;
  innerLearningRate: number;
  innerSteps: number;

  // Code synthesis settings
  targetLanguage: 'typescript' | 'python' | 'both';
  optimizeCode: boolean;

  // Resource management
  maxMemoryMB: number;
  enableParallelism: boolean;
  logLevel: 'debug' | 'info' | 'warn' | 'error';
}

/**
 * Cognitive task specification
 */
export interface CognitiveTask {
  id: string;
  type: TaskType;
  priority: number;
  input: unknown;
  config?: Partial<TaskConfig>;
  dependencies?: string[];
}

export enum TaskType {
  PATTERN_RECOGNITION = 'pattern_recognition',
  REASONING = 'reasoning',
  LEARNING = 'learning',
  CODE_GENERATION = 'code_generation',
  KERNEL_COMPOSITION = 'kernel_composition',
  META_LEARNING = 'meta_learning',
  CROSS_DOMAIN = 'cross_domain'
}

export interface TaskConfig {
  timeout: number;
  retries: number;
  cacheResult: boolean;
}

/**
 * Task execution result
 */
export interface TaskResult {
  taskId: string;
  success: boolean;
  output: unknown;
  metrics: ExecutionMetrics;
  errors?: string[];
}

export interface ExecutionMetrics {
  startTime: number;
  endTime: number;
  duration: number;
  memoryUsed: number;
  operationsCount: number;
}

/**
 * System state snapshot
 */
export interface SystemState {
  timestamp: number;
  activeModels: ModelInfo[];
  activeKernels: KernelInfo[];
  resourceUsage: ResourceUsage;
  recentTasks: TaskSummary[];
  healthStatus: HealthStatus;
}

export interface ModelInfo {
  id: string;
  type: string;
  parameterCount: number;
  lastUsed: number;
}

export interface KernelInfo {
  id: string;
  domain: string;
  gripQuality: number;
  compositionType?: string;
}

export interface ResourceUsage {
  memoryUsedMB: number;
  memoryTotalMB: number;
  cpuUtilization: number;
  activeOperations: number;
}

export interface TaskSummary {
  id: string;
  type: TaskType;
  status: 'completed' | 'failed' | 'running';
  duration: number;
}

export interface HealthStatus {
  overall: 'healthy' | 'degraded' | 'unhealthy';
  components: { name: string; status: string }[];
}

// ============================================================================
// UNIFIED COGNITIVE ORCHESTRATOR
// ============================================================================

/**
 * Main orchestrator class that integrates all cognitive subsystems
 */
export class UnifiedCognitiveOrchestrator {
  private config: OrchestratorConfig;

  // Core components
  private tensorKernel: GgmlTensorKernel;
  private gripFabric: CognitiveGripFabric;
  private kernelGenerator: UniversalKernelGenerator;
  private kernelComposer: KernelCompositionEngine;
  private codeSynthesizer: ProgramSynthesizer;
  private codeAnalyzer: CodeAnalyzer;
  private codeOptimizer: CodeOptimizer;
  private astBuilder: ASTBuilder;

  // Model registry
  private models: Map<string, NNModule> = new Map();
  private optimizers: Map<string, Optimizer> = new Map();
  private schedulers: Map<string, LRScheduler> = new Map();

  // Kernel registry
  private kernels: Map<string, GeneratedKernel> = new Map();
  private composedKernels: Map<string, ComposedKernel> = new Map();

  // Meta-learners
  private mamlLearners: Map<string, MAMLLearner> = new Map();
  private protoNetworks: Map<string, PrototypicalNetwork> = new Map();
  private multiTaskLearners: Map<string, MultiTaskLearner> = new Map();

  // Task management
  private taskQueue: CognitiveTask[] = [];
  private taskResults: Map<string, TaskResult> = new Map();
  private runningTasks: Set<string> = new Set();

  // System metrics
  private operationsCount = 0;
  private startTime: number;

  constructor(config?: Partial<OrchestratorConfig>) {
    this.config = {
      defaultEmbeddingDim: 128,
      defaultHiddenDim: 256,
      defaultAttentionHeads: 8,
      defaultLearningRate: 0.001,
      defaultBatchSize: 32,
      defaultOptimizer: 'adam',
      metaLearningEnabled: true,
      innerLearningRate: 0.01,
      innerSteps: 5,
      targetLanguage: 'typescript',
      optimizeCode: true,
      maxMemoryMB: 1024,
      enableParallelism: true,
      logLevel: 'info',
      ...config
    };

    this.startTime = Date.now();

    // Initialize core components
    this.tensorKernel = new GgmlTensorKernel({
      node_embedding_dim: this.config.defaultEmbeddingDim,
      link_embedding_dim: this.config.defaultEmbeddingDim,
      attention_heads: this.config.defaultAttentionHeads,
      max_hypergraph_size: 10000,
      symbolic_depth_levels: 5,
      truth_value_encoding: 'continuous',
      attention_mechanism: 'hybrid'
    });

    this.gripFabric = new CognitiveGripFabric();
    registerExtendedBridges(this.gripFabric);

    this.kernelGenerator = new UniversalKernelGenerator();
    this.kernelComposer = new KernelCompositionEngine();

    this.codeSynthesizer = new ProgramSynthesizer();
    this.codeAnalyzer = new CodeAnalyzer();
    this.codeOptimizer = new CodeOptimizer();
    this.astBuilder = new ASTBuilder();

    this.log('info', 'Unified Cognitive Orchestrator initialized');
  }

  // ==========================================================================
  // NEURAL NETWORK MANAGEMENT
  // ==========================================================================

  /**
   * Create a neural network model
   */
  public createModel(
    id: string,
    architecture: ModelArchitecture
  ): NNModule {
    let model: NNModule;

    switch (architecture.type) {
      case 'mlp':
        model = this.createMLP(architecture);
        break;
      case 'cnn':
        model = this.createCNN(architecture);
        break;
      case 'rnn':
        model = this.createRNN(architecture);
        break;
      case 'transformer':
        model = this.createTransformer(architecture);
        break;
      default:
        model = this.createMLP(architecture);
    }

    this.models.set(id, model);
    this.log('info', `Created model: ${id} (${architecture.type})`);

    return model;
  }

  private createMLP(arch: ModelArchitecture): NNModule {
    const layers: NNModule[] = [];
    const dims = arch.layerDims || [this.config.defaultEmbeddingDim, this.config.defaultHiddenDim, arch.outputDim || 10];

    for (let i = 0; i < dims.length - 1; i++) {
      layers.push(new LinearModule(dims[i], dims[i + 1]));
      if (i < dims.length - 2) {
        if (arch.batchNorm) layers.push(new BatchNormModule(dims[i + 1]));
        layers.push(new ExtendedArchitectures.GELU());
        if (arch.dropout) layers.push(new DropoutModule(arch.dropout));
      }
    }

    return new SequentialModule(...layers);
  }

  private createCNN(arch: ModelArchitecture): NNModule {
    const layers: NNModule[] = [];

    // Convolutional layers
    const channels = arch.channelDims || [1, 32, 64];
    for (let i = 0; i < channels.length - 1; i++) {
      layers.push(new ExtendedArchitectures.Conv1D(channels[i], channels[i + 1], 3, 1, 1));
      if (arch.batchNorm) layers.push(new BatchNormModule(channels[i + 1]));
      layers.push(new ExtendedArchitectures.GELU());
      layers.push(new ExtendedArchitectures.MaxPool1D(2));
    }

    // Flatten and dense layers
    layers.push(new ExtendedArchitectures.Flatten());
    layers.push(new LinearModule(channels[channels.length - 1] * 8, arch.outputDim || 10)); // Assuming 8 after pooling

    return new SequentialModule(...layers);
  }

  private createRNN(arch: ModelArchitecture): NNModule {
    return new LSTMModule(
      arch.inputDim || this.config.defaultEmbeddingDim,
      arch.hiddenDim || this.config.defaultHiddenDim,
      arch.numLayers || 2
    );
  }

  private createTransformer(arch: ModelArchitecture): NNModule {
    const layers: NNModule[] = [];
    const numLayers = arch.numLayers || 4;
    const embedDim = arch.embeddingDim || this.config.defaultEmbeddingDim;
    const numHeads = arch.numHeads || this.config.defaultAttentionHeads;

    for (let i = 0; i < numLayers; i++) {
      layers.push(new MultiHeadAttentionModule(embedDim, numHeads));
      layers.push(new ExtendedArchitectures.LayerNorm([embedDim]));
      layers.push(new LinearModule(embedDim, embedDim * 4));
      layers.push(new ExtendedArchitectures.GELU());
      layers.push(new LinearModule(embedDim * 4, embedDim));
      layers.push(new ExtendedArchitectures.LayerNorm([embedDim]));
    }

    return new SequentialModule(...layers);
  }

  /**
   * Get or create optimizer for a model
   */
  public getOptimizer(
    modelId: string,
    type?: 'adam' | 'adamw' | 'sgd' | 'rmsprop',
    config?: Record<string, unknown>
  ): Optimizer {
    const existingOpt = this.optimizers.get(modelId);
    if (existingOpt) return existingOpt;

    const model = this.models.get(modelId);
    if (!model) throw new Error(`Model not found: ${modelId}`);

    const optimizer = createOptimizer(
      model,
      type || this.config.defaultOptimizer,
      { lr: this.config.defaultLearningRate, ...config }
    );

    this.optimizers.set(modelId, optimizer);
    return optimizer;
  }

  /**
   * Create learning rate scheduler
   */
  public getScheduler(
    modelId: string,
    type: 'step' | 'cosine' | 'warmup' | 'onecycle',
    config?: Record<string, unknown>
  ): LRScheduler {
    const optimizer = this.getOptimizer(modelId);
    const scheduler = createScheduler(optimizer, type, config);
    this.schedulers.set(modelId, scheduler);
    return scheduler;
  }

  // ==========================================================================
  // KERNEL MANAGEMENT
  // ==========================================================================

  /**
   * Generate kernel for a domain
   */
  public generateKernel(domain: DomainSpecification): GeneratedKernel {
    const kernel = this.kernelGenerator.generateKernel(domain);
    this.kernels.set(domain.name, kernel);
    this.log('info', `Generated kernel for domain: ${domain.name}`);
    return kernel;
  }

  /**
   * Generate all domain kernels
   */
  public generateAllKernels(): Record<string, GeneratedKernel> {
    const kernels = this.kernelGenerator.generateDomainKernels();
    for (const [name, kernel] of Object.entries(kernels)) {
      this.kernels.set(name, kernel);
    }
    return kernels;
  }

  /**
   * Compose kernels
   */
  public composeKernels(
    kernelIds: string[],
    strategy: CompositionStrategy = CompositionStrategy.PARALLEL,
    name?: string
  ): ComposedKernel {
    const kernels = kernelIds.map(id => {
      const kernel = this.kernels.get(id);
      if (!kernel) throw new Error(`Kernel not found: ${id}`);
      return kernel;
    });

    let composed: ComposedKernel;

    switch (strategy) {
      case CompositionStrategy.SEQUENTIAL:
        composed = this.kernelComposer.composeSequential(kernels, name);
        break;
      case CompositionStrategy.PARALLEL:
        composed = this.kernelComposer.composeParallel(kernels, undefined, undefined, name);
        break;
      case CompositionStrategy.RESIDUAL:
        composed = this.kernelComposer.composeResidual(kernels[0], kernels.slice(1), 0.2, name);
        break;
      default:
        composed = this.kernelComposer.composeParallel(kernels);
    }

    this.composedKernels.set(composed.id, composed);
    return composed;
  }

  /**
   * Solve multi-domain problem
   */
  public solveMultiDomain(problem: MultiDomainProblem): ComposedKernel {
    const composed = this.kernelComposer.solveMultiDomain(problem);
    this.composedKernels.set(composed.id, composed);
    return composed;
  }

  // ==========================================================================
  // META-LEARNING
  // ==========================================================================

  /**
   * Create MAML learner
   */
  public createMAMLLearner(
    modelId: string,
    config?: { innerLr?: number; innerSteps?: number }
  ): MAMLLearner {
    const model = this.models.get(modelId);
    if (!model) throw new Error(`Model not found: ${modelId}`);

    const maml = new MAMLLearner(model, {
      inner_lr: config?.innerLr || this.config.innerLearningRate,
      inner_steps: config?.innerSteps || this.config.innerSteps,
      outer_lr: this.config.defaultLearningRate,
      first_order: false,
      meta_batch_size: 4
    });

    this.mamlLearners.set(modelId, maml);
    return maml;
  }

  /**
   * Create prototypical network
   */
  public createProtoNetwork(
    encoderId: string,
    embeddingDim?: number
  ): PrototypicalNetwork {
    const encoder = this.models.get(encoderId);
    if (!encoder) throw new Error(`Encoder not found: ${encoderId}`);

    const protoNet = new PrototypicalNetwork(
      encoder,
      embeddingDim || this.config.defaultEmbeddingDim
    );

    this.protoNetworks.set(encoderId, protoNet);
    return protoNet;
  }

  /**
   * Few-shot learning inference
   */
  public fewShotInference(
    learnerId: string,
    task: MetaTask
  ): EpisodeResult {
    const maml = this.mamlLearners.get(learnerId);
    if (maml) {
      return maml.fewShotInference(task);
    }

    const protoNet = this.protoNetworks.get(learnerId);
    if (protoNet) {
      const prototypes = protoNet.buildPrototypes(task.support_set);
      const { predictions, probabilities } = protoNet.classify(task.query_set, prototypes);

      // Compute accuracy
      let correct = 0;
      for (let i = 0; i < predictions.length; i++) {
        if (predictions[i] === task.query_set[i].label) correct++;
      }

      return {
        task_id: task.id,
        support_loss: 0,
        query_loss: 0,
        query_accuracy: correct / predictions.length,
        computation_time: 0
      };
    }

    throw new Error(`No meta-learner found for: ${learnerId}`);
  }

  // ==========================================================================
  // CODE SYNTHESIS
  // ==========================================================================

  /**
   * Generate code from specification
   */
  public synthesizeCode(spec: {
    name: string;
    description: string;
    inputs: { name: string; type: string }[];
    output: { type: string };
    examples: { input: unknown[]; output: unknown }[];
  }): { ast: FunctionNode | null; code: string } {
    const ast = this.codeSynthesizer.synthesize(spec);

    if (!ast) {
      return { ast: null, code: '' };
    }

    let optimizedAst = ast;
    if (this.config.optimizeCode) {
      optimizedAst = this.codeOptimizer.optimize(ast) as FunctionNode;
    }

    const program = this.astBuilder.program([optimizedAst]);
    let code: string;

    if (this.config.targetLanguage === 'python') {
      const generator = new PythonGenerator();
      code = generator.visit(program);
    } else {
      const generator = new TypeScriptGenerator();
      code = generator.visit(program);
    }

    return { ast: optimizedAst, code };
  }

  /**
   * Transform cognitive idea to code in multiple languages
   */
  public ideaToCode(idea: CognitiveIdea): Map<string, OperationalImplementation> {
    return this.gripFabric.transformIdea(idea);
  }

  /**
   * Analyze code complexity
   */
  public analyzeCode(ast: ProgramNode) {
    return {
      complexity: this.codeAnalyzer.analyzeComplexity(ast),
      issues: this.codeAnalyzer.findIssues(ast)
    };
  }

  // ==========================================================================
  // TASK EXECUTION
  // ==========================================================================

  /**
   * Submit a cognitive task
   */
  public submitTask(task: CognitiveTask): string {
    this.taskQueue.push(task);
    this.log('info', `Task submitted: ${task.id} (${task.type})`);
    return task.id;
  }

  /**
   * Execute a task
   */
  public async executeTask(task: CognitiveTask): Promise<TaskResult> {
    const startTime = Date.now();
    this.runningTasks.add(task.id);
    this.operationsCount++;

    try {
      let output: unknown;

      switch (task.type) {
        case TaskType.PATTERN_RECOGNITION:
          output = this.executePatternRecognition(task.input);
          break;

        case TaskType.LEARNING:
          output = this.executeLearning(task.input as LearningInput);
          break;

        case TaskType.CODE_GENERATION:
          output = this.executeCodeGeneration(task.input as CodeGenInput);
          break;

        case TaskType.KERNEL_COMPOSITION:
          output = this.executeKernelComposition(task.input as KernelCompInput);
          break;

        case TaskType.META_LEARNING:
          output = this.executeMetaLearning(task.input as MetaLearnInput);
          break;

        case TaskType.CROSS_DOMAIN:
          output = this.executeCrossDomain(task.input as CrossDomainInput);
          break;

        default:
          throw new Error(`Unknown task type: ${task.type}`);
      }

      const result: TaskResult = {
        taskId: task.id,
        success: true,
        output,
        metrics: {
          startTime,
          endTime: Date.now(),
          duration: Date.now() - startTime,
          memoryUsed: this.tensorKernel.getMemoryStats().used,
          operationsCount: this.operationsCount
        }
      };

      this.taskResults.set(task.id, result);
      this.runningTasks.delete(task.id);

      return result;

    } catch (error) {
      const result: TaskResult = {
        taskId: task.id,
        success: false,
        output: null,
        metrics: {
          startTime,
          endTime: Date.now(),
          duration: Date.now() - startTime,
          memoryUsed: this.tensorKernel.getMemoryStats().used,
          operationsCount: this.operationsCount
        },
        errors: [(error as Error).message]
      };

      this.taskResults.set(task.id, result);
      this.runningTasks.delete(task.id);

      return result;
    }
  }

  private executePatternRecognition(input: unknown): unknown {
    // Use kernel for pattern recognition
    const kernel = this.kernels.get('consciousness') || this.kernelGenerator.generateEchoKern();
    return {
      pattern: 'recognized',
      kernel_grip: kernel.grip.overall,
      coefficients: kernel.coefficients.slice(0, 5)
    };
  }

  private executeLearning(input: LearningInput): unknown {
    const model = this.models.get(input.modelId);
    if (!model) throw new Error(`Model not found: ${input.modelId}`);

    const optimizer = this.getOptimizer(input.modelId);
    const criterion = new MSECriterion();

    let totalLoss = 0;
    const numBatches = Math.ceil(input.data.length / this.config.defaultBatchSize);

    for (let batch = 0; batch < numBatches; batch++) {
      optimizer.zeroGrad();

      const batchData = input.data.slice(
        batch * this.config.defaultBatchSize,
        (batch + 1) * this.config.defaultBatchSize
      );

      for (const example of batchData) {
        const output = model.forward(example.input);
        const loss = criterion.forward(output, example.target);
        totalLoss += loss;

        const gradOutput = criterion.backward(output, example.target);
        model.backward(example.input, gradOutput);
      }

      optimizer.step();
    }

    return {
      averageLoss: totalLoss / input.data.length,
      batches: numBatches
    };
  }

  private executeCodeGeneration(input: CodeGenInput): unknown {
    const result = this.synthesizeCode(input.spec);

    if (input.generateMultiLanguage && result.ast) {
      const idea: CognitiveIdea = {
        id: input.spec.name,
        name: input.spec.name,
        description: input.spec.description,
        domain: 'code-generation',
        abstract_pattern: input.spec.inputs.map(i => i.type).join(' -> ') + ' -> ' + input.spec.output.type,
        dependencies: [],
        metadata: {}
      };

      const implementations = this.ideaToCode(idea);
      return {
        primaryCode: result.code,
        ast: result.ast,
        implementations: Object.fromEntries(implementations)
      };
    }

    return result;
  }

  private executeKernelComposition(input: KernelCompInput): unknown {
    if (input.multiDomain) {
      return this.solveMultiDomain(input.multiDomain);
    }

    return this.composeKernels(input.kernelIds, input.strategy, input.name);
  }

  private executeMetaLearning(input: MetaLearnInput): unknown {
    if (input.tasks.length === 0) {
      throw new Error('No tasks provided for meta-learning');
    }

    const maml = this.mamlLearners.get(input.learnerId);
    if (maml) {
      if (input.train) {
        const metaLoss = maml.metaTrain(input.tasks);
        return { type: 'training', metaLoss };
      } else {
        const results = input.tasks.map(task => maml.fewShotInference(task));
        return { type: 'inference', results };
      }
    }

    throw new Error(`Meta-learner not found: ${input.learnerId}`);
  }

  private executeCrossDomain(input: CrossDomainInput): unknown {
    // Generate kernels for each domain
    const kernels = input.domains.map(domain => {
      const existing = this.kernels.get(domain.name);
      if (existing) return existing;
      return this.generateKernel(domain);
    });

    // Compose for cross-domain operation
    const composed = this.kernelComposer.composeSequential(kernels, `cross_${input.operation}`);

    return {
      composed,
      domainsCovered: composed.domains_covered,
      grip: composed.combined_grip
    };
  }

  // ==========================================================================
  // SYSTEM STATE & MONITORING
  // ==========================================================================

  /**
   * Get current system state
   */
  public getSystemState(): SystemState {
    const memStats = this.tensorKernel.getMemoryStats();

    return {
      timestamp: Date.now(),
      activeModels: Array.from(this.models.entries()).map(([id, model]) => ({
        id,
        type: model.name,
        parameterCount: model.getParameters().weights.reduce((sum, w) => sum + w.data.length, 0),
        lastUsed: Date.now()
      })),
      activeKernels: Array.from(this.kernels.entries()).map(([id, kernel]) => ({
        id,
        domain: kernel.domain.name,
        gripQuality: kernel.grip.overall
      })),
      resourceUsage: {
        memoryUsedMB: memStats.used / (1024 * 1024),
        memoryTotalMB: memStats.total / (1024 * 1024),
        cpuUtilization: 0, // Would need platform-specific implementation
        activeOperations: this.runningTasks.size
      },
      recentTasks: Array.from(this.taskResults.values()).slice(-10).map(r => ({
        id: r.taskId,
        type: TaskType.PATTERN_RECOGNITION, // Would need to store task type
        status: r.success ? 'completed' : 'failed',
        duration: r.metrics.duration
      })),
      healthStatus: this.computeHealthStatus()
    };
  }

  private computeHealthStatus(): HealthStatus {
    const memStats = this.tensorKernel.getMemoryStats();
    const memoryHealthy = memStats.percentage < 80;

    const components = [
      { name: 'Memory', status: memoryHealthy ? 'healthy' : 'degraded' },
      { name: 'TensorKernel', status: 'healthy' },
      { name: 'GripFabric', status: 'healthy' },
      { name: 'KernelGenerator', status: 'healthy' },
      { name: 'CodeSynthesis', status: 'healthy' }
    ];

    const allHealthy = components.every(c => c.status === 'healthy');

    return {
      overall: allHealthy ? 'healthy' : 'degraded',
      components
    };
  }

  /**
   * Get available languages for code generation
   */
  public getAvailableLanguages(): string[] {
    return this.gripFabric.getRegisteredLanguages();
  }

  /**
   * Get registered kernels
   */
  public getKernels(): Map<string, GeneratedKernel> {
    return this.kernels;
  }

  /**
   * Get registered models
   */
  public getModels(): Map<string, NNModule> {
    return this.models;
  }

  // ==========================================================================
  // UTILITIES
  // ==========================================================================

  private log(level: string, message: string): void {
    const levels = ['debug', 'info', 'warn', 'error'];
    if (levels.indexOf(level) >= levels.indexOf(this.config.logLevel)) {
      console.log(`[${level.toUpperCase()}] ${new Date().toISOString()} - ${message}`);
    }
  }

  /**
   * Create a tensor
   */
  public createTensor(shape: number[], name?: string): GgmlTensor {
    return this.tensorKernel.createTensor(shape, 'f32', name, true);
  }

  /**
   * Cleanup resources
   */
  public cleanup(): void {
    this.models.clear();
    this.optimizers.clear();
    this.schedulers.clear();
    this.kernels.clear();
    this.composedKernels.clear();
    this.mamlLearners.clear();
    this.protoNetworks.clear();
    this.taskQueue = [];
    this.taskResults.clear();
    this.runningTasks.clear();

    this.log('info', 'Orchestrator resources cleaned up');
  }
}

// ============================================================================
// SUPPORTING TYPES
// ============================================================================

export interface ModelArchitecture {
  type: 'mlp' | 'cnn' | 'rnn' | 'transformer';
  inputDim?: number;
  outputDim?: number;
  hiddenDim?: number;
  embeddingDim?: number;
  numLayers?: number;
  numHeads?: number;
  layerDims?: number[];
  channelDims?: number[];
  batchNorm?: boolean;
  dropout?: number;
}

interface LearningInput {
  modelId: string;
  data: { input: GgmlTensor; target: GgmlTensor }[];
}

interface CodeGenInput {
  spec: {
    name: string;
    description: string;
    inputs: { name: string; type: string }[];
    output: { type: string };
    examples: { input: unknown[]; output: unknown }[];
  };
  generateMultiLanguage?: boolean;
}

interface KernelCompInput {
  kernelIds: string[];
  strategy?: CompositionStrategy;
  name?: string;
  multiDomain?: MultiDomainProblem;
}

interface MetaLearnInput {
  learnerId: string;
  tasks: MetaTask[];
  train?: boolean;
}

interface CrossDomainInput {
  domains: DomainSpecification[];
  operation: string;
}

// ============================================================================
// EXPORTS
// ============================================================================

export const CognitiveOrchestrator = {
  Orchestrator: UnifiedCognitiveOrchestrator,
  TaskType
};

// Create singleton instance
export const orchestrator = new UnifiedCognitiveOrchestrator();
