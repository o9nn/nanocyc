/**
 * Meta-Learning Engine - Phase 6
 *
 * Advanced meta-learning capabilities for the cognitive architecture:
 * - Few-shot learning (MAML, Prototypical Networks)
 * - Transfer learning with domain adaptation
 * - Multi-task learning
 * - Continual/Lifelong learning
 * - Neural Architecture Search (NAS)
 */

import { GgmlTensor } from './GgmlTensorKernel';
import { NNModule, LinearModule, SequentialModule } from './LearnabilityEmbeddings';
import { AdamOptimizer, ParameterGroup } from './AdvancedOptimizers';

// ============================================================================
// META-LEARNING INTERFACES
// ============================================================================

/**
 * Task representation for meta-learning
 */
export interface MetaTask {
  id: string;
  name: string;
  support_set: TaskExample[];  // Training examples (few-shot)
  query_set: TaskExample[];    // Test examples
  domain: string;
  metadata: Record<string, unknown>;
}

/**
 * Single example in a task
 */
export interface TaskExample {
  input: GgmlTensor;
  target: GgmlTensor;
  label?: number;
}

/**
 * Meta-learning episode result
 */
export interface EpisodeResult {
  task_id: string;
  support_loss: number;
  query_loss: number;
  query_accuracy: number;
  adapted_params?: Map<string, Float32Array>;
  computation_time: number;
}

/**
 * Meta-learner configuration
 */
export interface MetaLearnerConfig {
  inner_lr: number;           // Learning rate for task adaptation
  outer_lr: number;           // Learning rate for meta-update
  inner_steps: number;        // Number of gradient steps for adaptation
  first_order: boolean;       // Use first-order approximation (FOMAML)
  meta_batch_size: number;    // Number of tasks per meta-update
}

/**
 * Prototype for prototypical networks
 */
export interface ClassPrototype {
  class_id: number;
  embedding: Float32Array;
  support_count: number;
}

// ============================================================================
// MAML (Model-Agnostic Meta-Learning)
// ============================================================================

/**
 * MAML implementation for few-shot learning
 */
export class MAMLLearner {
  private config: MetaLearnerConfig;
  private metaOptimizer?: AdamOptimizer;

  constructor(
    private model: NNModule,
    config?: Partial<MetaLearnerConfig>
  ) {
    this.config = {
      inner_lr: config?.inner_lr ?? 0.01,
      outer_lr: config?.outer_lr ?? 0.001,
      inner_steps: config?.inner_steps ?? 5,
      first_order: config?.first_order ?? false,
      meta_batch_size: config?.meta_batch_size ?? 4
    };
  }

  /**
   * Perform meta-training on a batch of tasks
   */
  public metaTrain(tasks: MetaTask[]): number {
    const { weights, gradients } = this.model.getParameters();

    // Initialize meta-optimizer if needed
    if (!this.metaOptimizer) {
      const paramGroups: ParameterGroup[] = [{ params: weights, grads: gradients }];
      this.metaOptimizer = new AdamOptimizer(paramGroups, this.config.outer_lr);
    }

    // Zero meta-gradients
    this.metaOptimizer.zeroGrad();

    let totalMetaLoss = 0;

    // Process each task
    for (const task of tasks.slice(0, this.config.meta_batch_size)) {
      const result = this.adaptAndEvaluate(task);
      totalMetaLoss += result.query_loss;
    }

    // Average meta-loss
    const avgMetaLoss = totalMetaLoss / Math.min(tasks.length, this.config.meta_batch_size);

    // Meta-update (outer loop)
    this.metaOptimizer.step();

    return avgMetaLoss;
  }

  /**
   * Adapt to a new task and evaluate
   */
  public adaptAndEvaluate(task: MetaTask): EpisodeResult {
    const startTime = Date.now();

    // Clone parameters for task-specific adaptation
    const originalParams = this.cloneParameters();

    // Inner loop: adapt to support set
    let supportLoss = 0;
    for (let step = 0; step < this.config.inner_steps; step++) {
      supportLoss = this.computeLossOnSet(task.support_set);
      this.innerUpdate();
    }

    // Evaluate on query set
    const queryLoss = this.computeLossOnSet(task.query_set);
    const queryAccuracy = this.computeAccuracyOnSet(task.query_set);

    // Save adapted parameters
    const adaptedParams = this.cloneParameters();

    // Restore original parameters (for meta-gradient computation in non-first-order)
    if (!this.config.first_order) {
      this.restoreParameters(originalParams);
    }

    return {
      task_id: task.id,
      support_loss: supportLoss,
      query_loss: queryLoss,
      query_accuracy: queryAccuracy,
      adapted_params: adaptedParams,
      computation_time: Date.now() - startTime
    };
  }

  /**
   * Few-shot inference on a new task
   */
  public fewShotInference(task: MetaTask): EpisodeResult {
    // Adapt to support set
    for (let step = 0; step < this.config.inner_steps; step++) {
      this.computeLossOnSet(task.support_set);
      this.innerUpdate();
    }

    // Evaluate on query set
    return {
      task_id: task.id,
      support_loss: 0,
      query_loss: this.computeLossOnSet(task.query_set),
      query_accuracy: this.computeAccuracyOnSet(task.query_set),
      computation_time: 0
    };
  }

  private computeLossOnSet(examples: TaskExample[]): number {
    let totalLoss = 0;

    for (const example of examples) {
      const output = this.model.forward(example.input);
      totalLoss += this.mseLoss(output, example.target);

      // Backward pass
      const gradOutput = this.mseGrad(output, example.target);
      this.model.backward(example.input, gradOutput);
    }

    return totalLoss / examples.length;
  }

  private computeAccuracyOnSet(examples: TaskExample[]): number {
    let correct = 0;

    for (const example of examples) {
      const output = this.model.forward(example.input);
      const predicted = this.argmax(output.data);
      const target = example.label ?? this.argmax(example.target.data);

      if (predicted === target) correct++;
    }

    return correct / examples.length;
  }

  private innerUpdate(): void {
    this.model.updateParameters(this.config.inner_lr);
    this.model.zeroGradParameters();
  }

  private cloneParameters(): Map<string, Float32Array> {
    const { weights } = this.model.getParameters();
    const cloned = new Map<string, Float32Array>();

    for (const w of weights) {
      cloned.set(w.id, new Float32Array(w.data));
    }

    return cloned;
  }

  private restoreParameters(saved: Map<string, Float32Array>): void {
    const { weights } = this.model.getParameters();

    for (const w of weights) {
      const savedData = saved.get(w.id);
      if (savedData) {
        w.data.set(savedData);
      }
    }
  }

  private mseLoss(output: GgmlTensor, target: GgmlTensor): number {
    let loss = 0;
    for (let i = 0; i < output.data.length; i++) {
      const diff = output.data[i] - target.data[i];
      loss += diff * diff;
    }
    return loss / output.data.length;
  }

  private mseGrad(output: GgmlTensor, target: GgmlTensor): GgmlTensor {
    const grad: GgmlTensor = {
      id: `grad_${output.id}`,
      shape: output.shape,
      data: new Float32Array(output.data.length),
      dtype: 'f32',
      requires_grad: false
    };

    const scale = 2 / output.data.length;
    for (let i = 0; i < output.data.length; i++) {
      grad.data[i] = scale * (output.data[i] - target.data[i]);
    }

    return grad;
  }

  private argmax(data: Float32Array): number {
    let maxIdx = 0;
    let maxVal = data[0];
    for (let i = 1; i < data.length; i++) {
      if (data[i] > maxVal) {
        maxVal = data[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }
}

// ============================================================================
// PROTOTYPICAL NETWORKS
// ============================================================================

/**
 * Prototypical Networks for few-shot classification
 */
export class PrototypicalNetwork {
  private prototypes: Map<string, ClassPrototype[]> = new Map();

  constructor(
    private encoder: NNModule,
    private embeddingDim: number
  ) {}

  /**
   * Build prototypes from support set
   */
  public buildPrototypes(supportSet: TaskExample[]): ClassPrototype[] {
    // Group examples by class
    const classSamples = new Map<number, GgmlTensor[]>();

    for (const example of supportSet) {
      const label = example.label ?? 0;
      if (!classSamples.has(label)) {
        classSamples.set(label, []);
      }

      // Get embedding
      const embedding = this.encoder.forward(example.input);
      classSamples.get(label)!.push(embedding);
    }

    // Compute prototype for each class (mean of embeddings)
    const prototypes: ClassPrototype[] = [];

    for (const [classId, embeddings] of classSamples) {
      const prototype = new Float32Array(this.embeddingDim);

      for (const emb of embeddings) {
        for (let i = 0; i < this.embeddingDim; i++) {
          prototype[i] += emb.data[i];
        }
      }

      for (let i = 0; i < this.embeddingDim; i++) {
        prototype[i] /= embeddings.length;
      }

      prototypes.push({
        class_id: classId,
        embedding: prototype,
        support_count: embeddings.length
      });
    }

    return prototypes;
  }

  /**
   * Classify query examples using prototypes
   */
  public classify(
    querySet: TaskExample[],
    prototypes: ClassPrototype[]
  ): { predictions: number[]; probabilities: number[][] } {
    const predictions: number[] = [];
    const probabilities: number[][] = [];

    for (const example of querySet) {
      // Get query embedding
      const queryEmb = this.encoder.forward(example.input);

      // Compute distances to all prototypes
      const distances = prototypes.map(proto =>
        this.euclideanDistance(queryEmb.data, proto.embedding)
      );

      // Convert to probabilities using softmax of negative distances
      const negDist = distances.map(d => -d);
      const probs = this.softmax(negDist);

      probabilities.push(probs);
      predictions.push(this.argmax(probs));
    }

    return { predictions, probabilities };
  }

  /**
   * Train encoder using episodic training
   */
  public trainEpisode(task: MetaTask, lr: number = 0.001): number {
    // Build prototypes from support set
    const prototypes = this.buildPrototypes(task.support_set);

    // Classify query set
    let totalLoss = 0;

    for (const example of task.query_set) {
      const queryEmb = this.encoder.forward(example.input);
      const targetClass = example.label ?? 0;

      // Compute loss: negative log probability of correct class
      const distances = prototypes.map(proto =>
        this.euclideanDistance(queryEmb.data, proto.embedding)
      );
      const negDist = distances.map(d => -d);
      const probs = this.softmax(negDist);

      const targetIdx = prototypes.findIndex(p => p.class_id === targetClass);
      const loss = -Math.log(probs[targetIdx] + 1e-10);
      totalLoss += loss;

      // Backward pass (simplified)
      const gradOutput = this.computeProtoGrad(queryEmb, prototypes, targetIdx, probs);
      this.encoder.backward(example.input, gradOutput);
    }

    // Update encoder
    this.encoder.updateParameters(lr);
    this.encoder.zeroGradParameters();

    return totalLoss / task.query_set.length;
  }

  private euclideanDistance(a: Float32Array, b: Float32Array): number {
    let sum = 0;
    for (let i = 0; i < a.length; i++) {
      const diff = a[i] - b[i];
      sum += diff * diff;
    }
    return Math.sqrt(sum);
  }

  private softmax(values: number[]): number[] {
    const max = Math.max(...values);
    const exp = values.map(v => Math.exp(v - max));
    const sum = exp.reduce((a, b) => a + b, 0);
    return exp.map(e => e / sum);
  }

  private argmax(values: number[]): number {
    let maxIdx = 0;
    for (let i = 1; i < values.length; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }
    return maxIdx;
  }

  private computeProtoGrad(
    queryEmb: GgmlTensor,
    prototypes: ClassPrototype[],
    targetIdx: number,
    probs: number[]
  ): GgmlTensor {
    const grad: GgmlTensor = {
      id: `grad_proto_${queryEmb.id}`,
      shape: queryEmb.shape,
      data: new Float32Array(queryEmb.data.length),
      dtype: 'f32',
      requires_grad: false
    };

    // Gradient of cross-entropy loss w.r.t. query embedding
    for (let i = 0; i < this.embeddingDim; i++) {
      for (let p = 0; p < prototypes.length; p++) {
        const weight = p === targetIdx ? (probs[p] - 1) : probs[p];
        grad.data[i] += weight * (queryEmb.data[i] - prototypes[p].embedding[i]);
      }
    }

    return grad;
  }
}

// ============================================================================
// MULTI-TASK LEARNING
// ============================================================================

/**
 * Multi-Task Learning with shared representations
 */
export class MultiTaskLearner {
  private taskHeads: Map<string, NNModule> = new Map();
  private taskWeights: Map<string, number> = new Map();

  constructor(
    private sharedEncoder: NNModule,
    private encoderOutputDim: number
  ) {}

  /**
   * Add a task-specific head
   */
  public addTask(
    taskId: string,
    outputDim: number,
    weight: number = 1.0
  ): void {
    const head = new SequentialModule(
      new LinearModule(this.encoderOutputDim, 64),
      new LinearModule(64, outputDim)
    );

    this.taskHeads.set(taskId, head);
    this.taskWeights.set(taskId, weight);
  }

  /**
   * Forward pass for a specific task
   */
  public forward(input: GgmlTensor, taskId: string): GgmlTensor {
    const head = this.taskHeads.get(taskId);
    if (!head) {
      throw new Error(`Unknown task: ${taskId}`);
    }

    // Shared encoding
    const encoded = this.sharedEncoder.forward(input);

    // Task-specific head
    return head.forward(encoded);
  }

  /**
   * Train on multiple tasks simultaneously
   */
  public trainStep(
    taskBatches: Map<string, TaskExample[]>,
    lr: number = 0.001
  ): Map<string, number> {
    const losses = new Map<string, number>();
    let totalWeightedLoss = 0;

    // Compute loss for each task
    for (const [taskId, examples] of taskBatches) {
      const head = this.taskHeads.get(taskId);
      const weight = this.taskWeights.get(taskId) ?? 1.0;

      if (!head) continue;

      let taskLoss = 0;

      for (const example of examples) {
        // Forward pass
        const encoded = this.sharedEncoder.forward(example.input);
        const output = head.forward(encoded);

        // Compute loss
        const loss = this.mseLoss(output, example.target);
        taskLoss += loss;

        // Backward pass
        const gradOutput = this.mseGrad(output, example.target);
        const gradEncoded = head.backward(encoded, gradOutput);
        this.sharedEncoder.backward(example.input, gradEncoded);
      }

      taskLoss /= examples.length;
      losses.set(taskId, taskLoss);
      totalWeightedLoss += weight * taskLoss;
    }

    // Update all parameters
    this.sharedEncoder.updateParameters(lr);
    this.sharedEncoder.zeroGradParameters();

    for (const head of this.taskHeads.values()) {
      head.updateParameters(lr);
      head.zeroGradParameters();
    }

    return losses;
  }

  /**
   * Compute task-specific gradients for gradient-based task weighting
   */
  public computeTaskGradients(
    taskBatches: Map<string, TaskExample[]>
  ): Map<string, Float32Array[]> {
    const gradients = new Map<string, Float32Array[]>();

    for (const [taskId, examples] of taskBatches) {
      const head = this.taskHeads.get(taskId);
      if (!head) continue;

      // Zero gradients
      this.sharedEncoder.zeroGradParameters();

      for (const example of examples) {
        const encoded = this.sharedEncoder.forward(example.input);
        const output = head.forward(encoded);
        const gradOutput = this.mseGrad(output, example.target);
        const gradEncoded = head.backward(encoded, gradOutput);
        this.sharedEncoder.backward(example.input, gradEncoded);
      }

      // Store gradients
      const { gradients: grads } = this.sharedEncoder.getParameters();
      gradients.set(taskId, grads.map(g => new Float32Array(g.data)));
    }

    return gradients;
  }

  private mseLoss(output: GgmlTensor, target: GgmlTensor): number {
    let loss = 0;
    for (let i = 0; i < output.data.length; i++) {
      const diff = output.data[i] - target.data[i];
      loss += diff * diff;
    }
    return loss / output.data.length;
  }

  private mseGrad(output: GgmlTensor, target: GgmlTensor): GgmlTensor {
    const grad: GgmlTensor = {
      id: `grad_mse`,
      shape: output.shape,
      data: new Float32Array(output.data.length),
      dtype: 'f32',
      requires_grad: false
    };

    const scale = 2 / output.data.length;
    for (let i = 0; i < output.data.length; i++) {
      grad.data[i] = scale * (output.data[i] - target.data[i]);
    }

    return grad;
  }
}

// ============================================================================
// CONTINUAL LEARNING
// ============================================================================

/**
 * Elastic Weight Consolidation (EWC) for continual learning
 */
export class EWCLearner {
  private fisherDiagonals: Map<string, Float32Array> = new Map();
  private savedParams: Map<string, Float32Array> = new Map();
  private taskCount = 0;

  constructor(
    private model: NNModule,
    private ewcLambda: number = 1000
  ) {}

  /**
   * Compute Fisher Information after learning a task
   */
  public consolidate(examples: TaskExample[]): void {
    this.taskCount++;

    const { weights, gradients } = this.model.getParameters();

    // Initialize or accumulate Fisher diagonal
    for (const w of weights) {
      if (!this.fisherDiagonals.has(w.id)) {
        this.fisherDiagonals.set(w.id, new Float32Array(w.data.length));
      }
    }

    // Compute empirical Fisher Information
    for (const example of examples) {
      // Forward and backward
      this.model.zeroGradParameters();
      const output = this.model.forward(example.input);
      const gradOutput = this.logLikelihoodGrad(output, example.target);
      this.model.backward(example.input, gradOutput);

      // Accumulate squared gradients
      for (let i = 0; i < weights.length; i++) {
        const fisher = this.fisherDiagonals.get(weights[i].id)!;
        const grad = gradients[i];

        for (let j = 0; j < grad.data.length; j++) {
          fisher[j] += grad.data[j] * grad.data[j];
        }
      }
    }

    // Normalize
    for (const fisher of this.fisherDiagonals.values()) {
      for (let i = 0; i < fisher.length; i++) {
        fisher[i] /= examples.length;
      }
    }

    // Save current parameters as optimal for this task
    for (const w of weights) {
      this.savedParams.set(w.id, new Float32Array(w.data));
    }
  }

  /**
   * Compute EWC regularization loss
   */
  public ewcLoss(): number {
    if (this.taskCount === 0) return 0;

    const { weights } = this.model.getParameters();
    let loss = 0;

    for (const w of weights) {
      const fisher = this.fisherDiagonals.get(w.id);
      const savedParam = this.savedParams.get(w.id);

      if (fisher && savedParam) {
        for (let i = 0; i < w.data.length; i++) {
          const diff = w.data[i] - savedParam[i];
          loss += fisher[i] * diff * diff;
        }
      }
    }

    return (this.ewcLambda / 2) * loss;
  }

  /**
   * Compute gradient of EWC loss
   */
  public ewcGradient(): void {
    if (this.taskCount === 0) return;

    const { weights, gradients } = this.model.getParameters();

    for (let i = 0; i < weights.length; i++) {
      const w = weights[i];
      const grad = gradients[i];
      const fisher = this.fisherDiagonals.get(w.id);
      const savedParam = this.savedParams.get(w.id);

      if (fisher && savedParam) {
        for (let j = 0; j < w.data.length; j++) {
          grad.data[j] += this.ewcLambda * fisher[j] * (w.data[j] - savedParam[j]);
        }
      }
    }
  }

  /**
   * Train with EWC regularization
   */
  public trainStep(
    examples: TaskExample[],
    lr: number = 0.001
  ): { task_loss: number; ewc_loss: number } {
    this.model.zeroGradParameters();

    // Task loss
    let taskLoss = 0;
    for (const example of examples) {
      const output = this.model.forward(example.input);
      taskLoss += this.mseLoss(output, example.target);

      const gradOutput = this.mseGrad(output, example.target);
      this.model.backward(example.input, gradOutput);
    }
    taskLoss /= examples.length;

    // EWC loss and gradient
    const ewcLoss = this.ewcLoss();
    this.ewcGradient();

    // Update
    this.model.updateParameters(lr);

    return { task_loss: taskLoss, ewc_loss: ewcLoss };
  }

  private logLikelihoodGrad(output: GgmlTensor, target: GgmlTensor): GgmlTensor {
    // Using MSE gradient as approximation
    return this.mseGrad(output, target);
  }

  private mseLoss(output: GgmlTensor, target: GgmlTensor): number {
    let loss = 0;
    for (let i = 0; i < output.data.length; i++) {
      const diff = output.data[i] - target.data[i];
      loss += diff * diff;
    }
    return loss / output.data.length;
  }

  private mseGrad(output: GgmlTensor, target: GgmlTensor): GgmlTensor {
    const grad: GgmlTensor = {
      id: `grad_ewc`,
      shape: output.shape,
      data: new Float32Array(output.data.length),
      dtype: 'f32',
      requires_grad: false
    };

    const scale = 2 / output.data.length;
    for (let i = 0; i < output.data.length; i++) {
      grad.data[i] = scale * (output.data[i] - target.data[i]);
    }

    return grad;
  }
}

// ============================================================================
// NEURAL ARCHITECTURE SEARCH (NAS)
// ============================================================================

/**
 * Architecture specification for NAS
 */
export interface ArchitectureSpec {
  id: string;
  layers: LayerSpec[];
  connections: ConnectionSpec[];
  fitness?: number;
}

export interface LayerSpec {
  type: 'linear' | 'conv1d' | 'conv2d' | 'lstm' | 'attention' | 'norm' | 'activation';
  params: Record<string, number>;
}

export interface ConnectionSpec {
  from: number;
  to: number;
  weight: number;
}

/**
 * Simple evolutionary NAS
 */
export class EvolutionaryNAS {
  private population: ArchitectureSpec[] = [];
  private generation = 0;

  constructor(
    private populationSize: number = 20,
    private mutationRate: number = 0.1,
    private crossoverRate: number = 0.5
  ) {}

  /**
   * Initialize random population
   */
  public initializePopulation(
    minLayers: number = 2,
    maxLayers: number = 6
  ): void {
    this.population = [];

    for (let i = 0; i < this.populationSize; i++) {
      const numLayers = minLayers + Math.floor(Math.random() * (maxLayers - minLayers + 1));
      const layers: LayerSpec[] = [];

      for (let l = 0; l < numLayers; l++) {
        layers.push(this.randomLayer());
      }

      this.population.push({
        id: `arch_${i}_gen_${this.generation}`,
        layers,
        connections: this.generateConnections(numLayers)
      });
    }
  }

  /**
   * Generate a random layer
   */
  private randomLayer(): LayerSpec {
    const types: LayerSpec['type'][] = ['linear', 'conv1d', 'lstm', 'attention', 'norm', 'activation'];
    const type = types[Math.floor(Math.random() * types.length)];

    switch (type) {
      case 'linear':
        return { type, params: { in_features: 64, out_features: 64 + Math.floor(Math.random() * 192) } };
      case 'conv1d':
        return { type, params: { in_channels: 32, out_channels: 32 + Math.floor(Math.random() * 96), kernel_size: 3 + Math.floor(Math.random() * 4) } };
      case 'lstm':
        return { type, params: { input_size: 64, hidden_size: 64 + Math.floor(Math.random() * 192) } };
      case 'attention':
        return { type, params: { embed_dim: 64 + Math.floor(Math.random() * 192), num_heads: 1 << Math.floor(Math.random() * 4) } };
      case 'norm':
        return { type, params: { num_features: 64 } };
      case 'activation':
        return { type, params: { activation: Math.floor(Math.random() * 4) } }; // 0=relu, 1=gelu, 2=swish, 3=tanh
    }
  }

  /**
   * Generate sequential connections
   */
  private generateConnections(numLayers: number): ConnectionSpec[] {
    const connections: ConnectionSpec[] = [];

    for (let i = 0; i < numLayers - 1; i++) {
      connections.push({ from: i, to: i + 1, weight: 1 });

      // Occasional skip connection
      if (Math.random() < 0.3 && i + 2 < numLayers) {
        connections.push({ from: i, to: i + 2, weight: 0.5 });
      }
    }

    return connections;
  }

  /**
   * Evolve population based on fitness
   */
  public evolve(evaluator: (arch: ArchitectureSpec) => number): void {
    // Evaluate all architectures
    for (const arch of this.population) {
      if (arch.fitness === undefined) {
        arch.fitness = evaluator(arch);
      }
    }

    // Sort by fitness (descending)
    this.population.sort((a, b) => (b.fitness ?? 0) - (a.fitness ?? 0));

    // Selection: keep top half
    const survivors = this.population.slice(0, Math.floor(this.populationSize / 2));

    // Create new generation through crossover and mutation
    const newPopulation: ArchitectureSpec[] = [...survivors];

    while (newPopulation.length < this.populationSize) {
      if (Math.random() < this.crossoverRate && survivors.length >= 2) {
        // Crossover
        const parent1 = survivors[Math.floor(Math.random() * survivors.length)];
        const parent2 = survivors[Math.floor(Math.random() * survivors.length)];
        const child = this.crossover(parent1, parent2);
        newPopulation.push(child);
      } else {
        // Mutation
        const parent = survivors[Math.floor(Math.random() * survivors.length)];
        const mutant = this.mutate(parent);
        newPopulation.push(mutant);
      }
    }

    this.population = newPopulation;
    this.generation++;
  }

  /**
   * Crossover two architectures
   */
  private crossover(parent1: ArchitectureSpec, parent2: ArchitectureSpec): ArchitectureSpec {
    const crossoverPoint = Math.floor(Math.random() * Math.min(parent1.layers.length, parent2.layers.length));

    const layers = [
      ...parent1.layers.slice(0, crossoverPoint),
      ...parent2.layers.slice(crossoverPoint)
    ];

    return {
      id: `arch_cross_gen_${this.generation}`,
      layers,
      connections: this.generateConnections(layers.length),
      fitness: undefined
    };
  }

  /**
   * Mutate an architecture
   */
  private mutate(parent: ArchitectureSpec): ArchitectureSpec {
    const layers = [...parent.layers];

    for (let i = 0; i < layers.length; i++) {
      if (Math.random() < this.mutationRate) {
        // Replace with random layer
        layers[i] = this.randomLayer();
      } else if (Math.random() < this.mutationRate) {
        // Mutate parameters
        layers[i] = this.mutateLayer(layers[i]);
      }
    }

    // Possibly add or remove layer
    if (Math.random() < this.mutationRate && layers.length < 8) {
      const insertIdx = Math.floor(Math.random() * (layers.length + 1));
      layers.splice(insertIdx, 0, this.randomLayer());
    } else if (Math.random() < this.mutationRate && layers.length > 2) {
      const removeIdx = Math.floor(Math.random() * layers.length);
      layers.splice(removeIdx, 1);
    }

    return {
      id: `arch_mut_gen_${this.generation}`,
      layers,
      connections: this.generateConnections(layers.length),
      fitness: undefined
    };
  }

  /**
   * Mutate layer parameters
   */
  private mutateLayer(layer: LayerSpec): LayerSpec {
    const mutated = { ...layer, params: { ...layer.params } };

    for (const key in mutated.params) {
      if (Math.random() < 0.5) {
        // Perturb parameter
        mutated.params[key] = Math.max(1, Math.floor(mutated.params[key] * (0.8 + Math.random() * 0.4)));
      }
    }

    return mutated;
  }

  /**
   * Get best architecture
   */
  public getBest(): ArchitectureSpec | undefined {
    return this.population.reduce((best, current) =>
      (current.fitness ?? 0) > (best.fitness ?? 0) ? current : best
    , this.population[0]);
  }

  /**
   * Get current generation
   */
  public getGeneration(): number {
    return this.generation;
  }

  /**
   * Get population
   */
  public getPopulation(): ArchitectureSpec[] {
    return this.population;
  }
}

// ============================================================================
// META-LEARNING TASK GENERATOR
// ============================================================================

/**
 * Generate synthetic meta-learning tasks for testing
 */
export class MetaTaskGenerator {
  /**
   * Generate sinusoid regression tasks (common MAML benchmark)
   */
  public generateSinusoidTasks(
    numTasks: number,
    supportSize: number = 5,
    querySize: number = 10
  ): MetaTask[] {
    const tasks: MetaTask[] = [];

    for (let t = 0; t < numTasks; t++) {
      // Random amplitude and phase
      const amplitude = 0.1 + Math.random() * 4.9;
      const phase = Math.random() * Math.PI;

      const supportSet = this.generateSinusoidExamples(amplitude, phase, supportSize);
      const querySet = this.generateSinusoidExamples(amplitude, phase, querySize);

      tasks.push({
        id: `sinusoid_${t}`,
        name: `Sinusoid(A=${amplitude.toFixed(2)}, φ=${phase.toFixed(2)})`,
        support_set: supportSet,
        query_set: querySet,
        domain: 'regression',
        metadata: { amplitude, phase }
      });
    }

    return tasks;
  }

  private generateSinusoidExamples(
    amplitude: number,
    phase: number,
    count: number
  ): TaskExample[] {
    const examples: TaskExample[] = [];

    for (let i = 0; i < count; i++) {
      const x = -5 + Math.random() * 10;
      const y = amplitude * Math.sin(x + phase);

      examples.push({
        input: this.createTensor([1, 1], [x]),
        target: this.createTensor([1, 1], [y])
      });
    }

    return examples;
  }

  /**
   * Generate N-way K-shot classification tasks
   */
  public generateClassificationTasks(
    numTasks: number,
    numClasses: number = 5,
    supportPerClass: number = 1,
    queryPerClass: number = 5,
    inputDim: number = 64
  ): MetaTask[] {
    const tasks: MetaTask[] = [];

    for (let t = 0; t < numTasks; t++) {
      const supportSet: TaskExample[] = [];
      const querySet: TaskExample[] = [];

      // Generate class centroids
      const centroids: Float32Array[] = [];
      for (let c = 0; c < numClasses; c++) {
        centroids.push(this.randomVector(inputDim));
      }

      // Generate examples for each class
      for (let c = 0; c < numClasses; c++) {
        // Support examples
        for (let s = 0; s < supportPerClass; s++) {
          supportSet.push({
            input: this.createTensor([1, inputDim], this.noisyVector(centroids[c], 0.1)),
            target: this.createTensor([1, numClasses], this.oneHot(c, numClasses)),
            label: c
          });
        }

        // Query examples
        for (let q = 0; q < queryPerClass; q++) {
          querySet.push({
            input: this.createTensor([1, inputDim], this.noisyVector(centroids[c], 0.1)),
            target: this.createTensor([1, numClasses], this.oneHot(c, numClasses)),
            label: c
          });
        }
      }

      tasks.push({
        id: `classification_${t}`,
        name: `${numClasses}-way ${supportPerClass}-shot`,
        support_set: this.shuffle(supportSet),
        query_set: this.shuffle(querySet),
        domain: 'classification',
        metadata: { num_classes: numClasses, support_per_class: supportPerClass }
      });
    }

    return tasks;
  }

  private createTensor(shape: number[], data: number[] | Float32Array): GgmlTensor {
    const arr = data instanceof Float32Array ? data : new Float32Array(data);
    return {
      id: `tensor_${Math.random().toString(36).substr(2, 9)}`,
      shape,
      data: arr,
      dtype: 'f32',
      requires_grad: false
    };
  }

  private randomVector(dim: number): Float32Array {
    const vec = new Float32Array(dim);
    for (let i = 0; i < dim; i++) {
      vec[i] = (Math.random() - 0.5) * 2;
    }
    return vec;
  }

  private noisyVector(base: Float32Array, noise: number): Float32Array {
    const vec = new Float32Array(base.length);
    for (let i = 0; i < base.length; i++) {
      vec[i] = base[i] + (Math.random() - 0.5) * 2 * noise;
    }
    return vec;
  }

  private oneHot(index: number, size: number): Float32Array {
    const vec = new Float32Array(size);
    vec[index] = 1;
    return vec;
  }

  private shuffle<T>(array: T[]): T[] {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }
}

// ============================================================================
// EXPORTS
// ============================================================================

export const MetaLearning = {
  MAML: MAMLLearner,
  PrototypicalNetwork,
  MultiTask: MultiTaskLearner,
  EWC: EWCLearner,
  NAS: EvolutionaryNAS,
  TaskGenerator: MetaTaskGenerator
};
