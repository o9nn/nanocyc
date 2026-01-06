/**
 * Advanced Optimizers - Phase 6
 *
 * Modern optimization algorithms for neural network training:
 * - SGD with Momentum
 * - Adam (Adaptive Moment Estimation)
 * - AdamW (Adam with Weight Decay)
 * - RMSprop
 * - Adagrad
 * - Learning Rate Schedulers
 */

import { GgmlTensor } from './GgmlTensorKernel';
import { NNModule } from './LearnabilityEmbeddings';

// ============================================================================
// OPTIMIZER INTERFACES
// ============================================================================

/**
 * Base optimizer interface
 */
export interface Optimizer {
  name: string;
  step(): void;
  zeroGrad(): void;
  getLearningRate(): number;
  setLearningRate(lr: number): void;
  getState(): OptimizerState;
  loadState(state: OptimizerState): void;
}

/**
 * Parameter group for optimizer
 */
export interface ParameterGroup {
  params: GgmlTensor[];
  grads: GgmlTensor[];
  lr?: number;
  weight_decay?: number;
  momentum?: number;
  // Additional per-group options
  [key: string]: unknown;
}

/**
 * Optimizer state for checkpointing
 */
export interface OptimizerState {
  name: string;
  step_count: number;
  learning_rate: number;
  parameter_states: Map<string, Record<string, Float32Array>>;
  hyperparameters: Record<string, unknown>;
}

// ============================================================================
// SGD WITH MOMENTUM
// ============================================================================

/**
 * Stochastic Gradient Descent with Momentum and Nesterov acceleration
 */
export class SGDOptimizer implements Optimizer {
  name = 'SGD';
  private stepCount = 0;
  private velocities: Map<string, Float32Array> = new Map();

  constructor(
    private paramGroups: ParameterGroup[],
    private lr: number = 0.01,
    private momentum: number = 0,
    private dampening: number = 0,
    private weightDecay: number = 0,
    private nesterov: boolean = false
  ) {
    if (nesterov && (momentum <= 0 || dampening !== 0)) {
      throw new Error('Nesterov momentum requires momentum > 0 and dampening = 0');
    }

    // Initialize velocities
    for (const group of paramGroups) {
      for (const param of group.params) {
        this.velocities.set(param.id, new Float32Array(param.data.length));
      }
    }
  }

  step(): void {
    this.stepCount++;

    for (let g = 0; g < this.paramGroups.length; g++) {
      const group = this.paramGroups[g];
      const groupLr = group.lr ?? this.lr;
      const groupMomentum = group.momentum ?? this.momentum;
      const groupWeightDecay = group.weight_decay ?? this.weightDecay;

      for (let p = 0; p < group.params.length; p++) {
        const param = group.params[p];
        const grad = group.grads[p];

        if (!grad || grad.data.length === 0) continue;

        // Apply weight decay
        let d_p = new Float32Array(grad.data);
        if (groupWeightDecay !== 0) {
          for (let i = 0; i < d_p.length; i++) {
            d_p[i] += groupWeightDecay * param.data[i];
          }
        }

        // Apply momentum
        if (groupMomentum !== 0) {
          const velocity = this.velocities.get(param.id)!;

          if (this.stepCount > 1) {
            for (let i = 0; i < velocity.length; i++) {
              velocity[i] = groupMomentum * velocity[i] + (1 - this.dampening) * d_p[i];
            }
          } else {
            velocity.set(d_p);
          }

          if (this.nesterov) {
            for (let i = 0; i < d_p.length; i++) {
              d_p[i] = d_p[i] + groupMomentum * velocity[i];
            }
          } else {
            d_p = velocity;
          }
        }

        // Update parameters
        for (let i = 0; i < param.data.length; i++) {
          param.data[i] -= groupLr * d_p[i];
        }
      }
    }
  }

  zeroGrad(): void {
    for (const group of this.paramGroups) {
      for (const grad of group.grads) {
        grad.data.fill(0);
      }
    }
  }

  getLearningRate(): number { return this.lr; }
  setLearningRate(lr: number): void { this.lr = lr; }

  getState(): OptimizerState {
    const paramStates = new Map<string, Record<string, Float32Array>>();
    for (const [id, velocity] of this.velocities) {
      paramStates.set(id, { velocity: new Float32Array(velocity) });
    }

    return {
      name: this.name,
      step_count: this.stepCount,
      learning_rate: this.lr,
      parameter_states: paramStates,
      hyperparameters: {
        momentum: this.momentum,
        dampening: this.dampening,
        weight_decay: this.weightDecay,
        nesterov: this.nesterov
      }
    };
  }

  loadState(state: OptimizerState): void {
    this.stepCount = state.step_count;
    this.lr = state.learning_rate;
    for (const [id, pState] of state.parameter_states) {
      if (pState.velocity) {
        this.velocities.set(id, new Float32Array(pState.velocity));
      }
    }
  }
}

// ============================================================================
// ADAM OPTIMIZER
// ============================================================================

/**
 * Adam optimizer (Adaptive Moment Estimation)
 * Combines momentum and RMSprop for efficient training
 */
export class AdamOptimizer implements Optimizer {
  name = 'Adam';
  private stepCount = 0;
  private m: Map<string, Float32Array> = new Map(); // First moment
  private v: Map<string, Float32Array> = new Map(); // Second moment

  constructor(
    private paramGroups: ParameterGroup[],
    private lr: number = 0.001,
    private beta1: number = 0.9,
    private beta2: number = 0.999,
    private eps: number = 1e-8,
    private weightDecay: number = 0,
    private amsgrad: boolean = false
  ) {
    // Initialize moment estimates
    for (const group of paramGroups) {
      for (const param of group.params) {
        this.m.set(param.id, new Float32Array(param.data.length));
        this.v.set(param.id, new Float32Array(param.data.length));
      }
    }
  }

  step(): void {
    this.stepCount++;

    for (let g = 0; g < this.paramGroups.length; g++) {
      const group = this.paramGroups[g];
      const groupLr = group.lr ?? this.lr;
      const groupWeightDecay = group.weight_decay ?? this.weightDecay;

      for (let p = 0; p < group.params.length; p++) {
        const param = group.params[p];
        const grad = group.grads[p];

        if (!grad || grad.data.length === 0) continue;

        const m = this.m.get(param.id)!;
        const v = this.v.get(param.id)!;

        // Bias correction
        const biasCorrection1 = 1 - Math.pow(this.beta1, this.stepCount);
        const biasCorrection2 = 1 - Math.pow(this.beta2, this.stepCount);

        for (let i = 0; i < param.data.length; i++) {
          let g_t = grad.data[i];

          // L2 regularization (not decoupled)
          if (groupWeightDecay !== 0) {
            g_t += groupWeightDecay * param.data[i];
          }

          // Update biased first moment estimate
          m[i] = this.beta1 * m[i] + (1 - this.beta1) * g_t;

          // Update biased second raw moment estimate
          v[i] = this.beta2 * v[i] + (1 - this.beta2) * g_t * g_t;

          // Compute bias-corrected estimates
          const m_hat = m[i] / biasCorrection1;
          const v_hat = v[i] / biasCorrection2;

          // Update parameters
          param.data[i] -= groupLr * m_hat / (Math.sqrt(v_hat) + this.eps);
        }
      }
    }
  }

  zeroGrad(): void {
    for (const group of this.paramGroups) {
      for (const grad of group.grads) {
        grad.data.fill(0);
      }
    }
  }

  getLearningRate(): number { return this.lr; }
  setLearningRate(lr: number): void { this.lr = lr; }

  getState(): OptimizerState {
    const paramStates = new Map<string, Record<string, Float32Array>>();
    for (const group of this.paramGroups) {
      for (const param of group.params) {
        paramStates.set(param.id, {
          m: new Float32Array(this.m.get(param.id)!),
          v: new Float32Array(this.v.get(param.id)!)
        });
      }
    }

    return {
      name: this.name,
      step_count: this.stepCount,
      learning_rate: this.lr,
      parameter_states: paramStates,
      hyperparameters: {
        beta1: this.beta1,
        beta2: this.beta2,
        eps: this.eps,
        weight_decay: this.weightDecay,
        amsgrad: this.amsgrad
      }
    };
  }

  loadState(state: OptimizerState): void {
    this.stepCount = state.step_count;
    this.lr = state.learning_rate;
    for (const [id, pState] of state.parameter_states) {
      if (pState.m) this.m.set(id, new Float32Array(pState.m));
      if (pState.v) this.v.set(id, new Float32Array(pState.v));
    }
  }
}

// ============================================================================
// ADAMW OPTIMIZER
// ============================================================================

/**
 * AdamW optimizer (Adam with decoupled weight decay)
 * Better regularization than standard Adam
 */
export class AdamWOptimizer implements Optimizer {
  name = 'AdamW';
  private stepCount = 0;
  private m: Map<string, Float32Array> = new Map();
  private v: Map<string, Float32Array> = new Map();

  constructor(
    private paramGroups: ParameterGroup[],
    private lr: number = 0.001,
    private beta1: number = 0.9,
    private beta2: number = 0.999,
    private eps: number = 1e-8,
    private weightDecay: number = 0.01
  ) {
    for (const group of paramGroups) {
      for (const param of group.params) {
        this.m.set(param.id, new Float32Array(param.data.length));
        this.v.set(param.id, new Float32Array(param.data.length));
      }
    }
  }

  step(): void {
    this.stepCount++;

    for (let g = 0; g < this.paramGroups.length; g++) {
      const group = this.paramGroups[g];
      const groupLr = group.lr ?? this.lr;
      const groupWeightDecay = group.weight_decay ?? this.weightDecay;

      for (let p = 0; p < group.params.length; p++) {
        const param = group.params[p];
        const grad = group.grads[p];

        if (!grad || grad.data.length === 0) continue;

        const m = this.m.get(param.id)!;
        const v = this.v.get(param.id)!;

        const biasCorrection1 = 1 - Math.pow(this.beta1, this.stepCount);
        const biasCorrection2 = 1 - Math.pow(this.beta2, this.stepCount);

        for (let i = 0; i < param.data.length; i++) {
          const g_t = grad.data[i];

          // Update moment estimates (without weight decay in gradient)
          m[i] = this.beta1 * m[i] + (1 - this.beta1) * g_t;
          v[i] = this.beta2 * v[i] + (1 - this.beta2) * g_t * g_t;

          const m_hat = m[i] / biasCorrection1;
          const v_hat = v[i] / biasCorrection2;

          // Decoupled weight decay - applied directly to parameters
          param.data[i] -= groupLr * (m_hat / (Math.sqrt(v_hat) + this.eps) + groupWeightDecay * param.data[i]);
        }
      }
    }
  }

  zeroGrad(): void {
    for (const group of this.paramGroups) {
      for (const grad of group.grads) {
        grad.data.fill(0);
      }
    }
  }

  getLearningRate(): number { return this.lr; }
  setLearningRate(lr: number): void { this.lr = lr; }

  getState(): OptimizerState {
    const paramStates = new Map<string, Record<string, Float32Array>>();
    for (const group of this.paramGroups) {
      for (const param of group.params) {
        paramStates.set(param.id, {
          m: new Float32Array(this.m.get(param.id)!),
          v: new Float32Array(this.v.get(param.id)!)
        });
      }
    }

    return {
      name: this.name,
      step_count: this.stepCount,
      learning_rate: this.lr,
      parameter_states: paramStates,
      hyperparameters: {
        beta1: this.beta1,
        beta2: this.beta2,
        eps: this.eps,
        weight_decay: this.weightDecay
      }
    };
  }

  loadState(state: OptimizerState): void {
    this.stepCount = state.step_count;
    this.lr = state.learning_rate;
    for (const [id, pState] of state.parameter_states) {
      if (pState.m) this.m.set(id, new Float32Array(pState.m));
      if (pState.v) this.v.set(id, new Float32Array(pState.v));
    }
  }
}

// ============================================================================
// RMSPROP OPTIMIZER
// ============================================================================

/**
 * RMSprop optimizer
 * Adaptive learning rate method
 */
export class RMSpropOptimizer implements Optimizer {
  name = 'RMSprop';
  private stepCount = 0;
  private squareAvg: Map<string, Float32Array> = new Map();
  private momentum_buffer: Map<string, Float32Array> = new Map();

  constructor(
    private paramGroups: ParameterGroup[],
    private lr: number = 0.01,
    private alpha: number = 0.99,
    private eps: number = 1e-8,
    private weightDecay: number = 0,
    private momentum: number = 0,
    private centered: boolean = false
  ) {
    for (const group of paramGroups) {
      for (const param of group.params) {
        this.squareAvg.set(param.id, new Float32Array(param.data.length));
        if (momentum > 0) {
          this.momentum_buffer.set(param.id, new Float32Array(param.data.length));
        }
      }
    }
  }

  step(): void {
    this.stepCount++;

    for (let g = 0; g < this.paramGroups.length; g++) {
      const group = this.paramGroups[g];
      const groupLr = group.lr ?? this.lr;
      const groupWeightDecay = group.weight_decay ?? this.weightDecay;
      const groupMomentum = group.momentum ?? this.momentum;

      for (let p = 0; p < group.params.length; p++) {
        const param = group.params[p];
        const grad = group.grads[p];

        if (!grad || grad.data.length === 0) continue;

        const squareAvg = this.squareAvg.get(param.id)!;

        for (let i = 0; i < param.data.length; i++) {
          let g_t = grad.data[i];

          if (groupWeightDecay !== 0) {
            g_t += groupWeightDecay * param.data[i];
          }

          // Update running average of squared gradients
          squareAvg[i] = this.alpha * squareAvg[i] + (1 - this.alpha) * g_t * g_t;

          let avg = Math.sqrt(squareAvg[i]) + this.eps;

          if (groupMomentum > 0) {
            const buf = this.momentum_buffer.get(param.id)!;
            buf[i] = groupMomentum * buf[i] + g_t / avg;
            param.data[i] -= groupLr * buf[i];
          } else {
            param.data[i] -= groupLr * g_t / avg;
          }
        }
      }
    }
  }

  zeroGrad(): void {
    for (const group of this.paramGroups) {
      for (const grad of group.grads) {
        grad.data.fill(0);
      }
    }
  }

  getLearningRate(): number { return this.lr; }
  setLearningRate(lr: number): void { this.lr = lr; }

  getState(): OptimizerState {
    const paramStates = new Map<string, Record<string, Float32Array>>();
    for (const group of this.paramGroups) {
      for (const param of group.params) {
        const state: Record<string, Float32Array> = {
          square_avg: new Float32Array(this.squareAvg.get(param.id)!)
        };
        if (this.momentum > 0) {
          state.momentum_buffer = new Float32Array(this.momentum_buffer.get(param.id)!);
        }
        paramStates.set(param.id, state);
      }
    }

    return {
      name: this.name,
      step_count: this.stepCount,
      learning_rate: this.lr,
      parameter_states: paramStates,
      hyperparameters: {
        alpha: this.alpha,
        eps: this.eps,
        weight_decay: this.weightDecay,
        momentum: this.momentum,
        centered: this.centered
      }
    };
  }

  loadState(state: OptimizerState): void {
    this.stepCount = state.step_count;
    this.lr = state.learning_rate;
    for (const [id, pState] of state.parameter_states) {
      if (pState.square_avg) this.squareAvg.set(id, new Float32Array(pState.square_avg));
      if (pState.momentum_buffer) this.momentum_buffer.set(id, new Float32Array(pState.momentum_buffer));
    }
  }
}

// ============================================================================
// ADAGRAD OPTIMIZER
// ============================================================================

/**
 * Adagrad optimizer
 * Adapts learning rate based on historical gradients
 */
export class AdagradOptimizer implements Optimizer {
  name = 'Adagrad';
  private stepCount = 0;
  private sumSquares: Map<string, Float32Array> = new Map();

  constructor(
    private paramGroups: ParameterGroup[],
    private lr: number = 0.01,
    private lrDecay: number = 0,
    private weightDecay: number = 0,
    private eps: number = 1e-10
  ) {
    for (const group of paramGroups) {
      for (const param of group.params) {
        this.sumSquares.set(param.id, new Float32Array(param.data.length));
      }
    }
  }

  step(): void {
    this.stepCount++;

    for (let g = 0; g < this.paramGroups.length; g++) {
      const group = this.paramGroups[g];
      const groupWeightDecay = group.weight_decay ?? this.weightDecay;

      // Apply learning rate decay
      const clr = this.lr / (1 + (this.stepCount - 1) * this.lrDecay);

      for (let p = 0; p < group.params.length; p++) {
        const param = group.params[p];
        const grad = group.grads[p];

        if (!grad || grad.data.length === 0) continue;

        const sumSq = this.sumSquares.get(param.id)!;

        for (let i = 0; i < param.data.length; i++) {
          let g_t = grad.data[i];

          if (groupWeightDecay !== 0) {
            g_t += groupWeightDecay * param.data[i];
          }

          // Accumulate squared gradients
          sumSq[i] += g_t * g_t;

          // Update parameters
          param.data[i] -= clr * g_t / (Math.sqrt(sumSq[i]) + this.eps);
        }
      }
    }
  }

  zeroGrad(): void {
    for (const group of this.paramGroups) {
      for (const grad of group.grads) {
        grad.data.fill(0);
      }
    }
  }

  getLearningRate(): number { return this.lr; }
  setLearningRate(lr: number): void { this.lr = lr; }

  getState(): OptimizerState {
    const paramStates = new Map<string, Record<string, Float32Array>>();
    for (const group of this.paramGroups) {
      for (const param of group.params) {
        paramStates.set(param.id, {
          sum_squares: new Float32Array(this.sumSquares.get(param.id)!)
        });
      }
    }

    return {
      name: this.name,
      step_count: this.stepCount,
      learning_rate: this.lr,
      parameter_states: paramStates,
      hyperparameters: {
        lr_decay: this.lrDecay,
        weight_decay: this.weightDecay,
        eps: this.eps
      }
    };
  }

  loadState(state: OptimizerState): void {
    this.stepCount = state.step_count;
    this.lr = state.learning_rate;
    for (const [id, pState] of state.parameter_states) {
      if (pState.sum_squares) this.sumSquares.set(id, new Float32Array(pState.sum_squares));
    }
  }
}

// ============================================================================
// LEARNING RATE SCHEDULERS
// ============================================================================

/**
 * Base learning rate scheduler interface
 */
export interface LRScheduler {
  name: string;
  step(epoch?: number): void;
  getLR(): number;
  getLastLR(): number;
}

/**
 * Step learning rate scheduler
 * Decays LR by gamma every step_size epochs
 */
export class StepLRScheduler implements LRScheduler {
  name = 'StepLR';
  private currentEpoch = 0;
  private lastLR: number;

  constructor(
    private optimizer: Optimizer,
    private stepSize: number,
    private gamma: number = 0.1
  ) {
    this.lastLR = optimizer.getLearningRate();
  }

  step(epoch?: number): void {
    if (epoch !== undefined) {
      this.currentEpoch = epoch;
    } else {
      this.currentEpoch++;
    }

    if (this.currentEpoch > 0 && this.currentEpoch % this.stepSize === 0) {
      const newLR = this.optimizer.getLearningRate() * this.gamma;
      this.optimizer.setLearningRate(newLR);
      this.lastLR = newLR;
    }
  }

  getLR(): number { return this.optimizer.getLearningRate(); }
  getLastLR(): number { return this.lastLR; }
}

/**
 * Exponential learning rate scheduler
 * Decays LR by gamma every epoch
 */
export class ExponentialLRScheduler implements LRScheduler {
  name = 'ExponentialLR';
  private currentEpoch = 0;
  private baseLR: number;
  private lastLR: number;

  constructor(
    private optimizer: Optimizer,
    private gamma: number = 0.95
  ) {
    this.baseLR = optimizer.getLearningRate();
    this.lastLR = this.baseLR;
  }

  step(epoch?: number): void {
    if (epoch !== undefined) {
      this.currentEpoch = epoch;
    } else {
      this.currentEpoch++;
    }

    const newLR = this.baseLR * Math.pow(this.gamma, this.currentEpoch);
    this.optimizer.setLearningRate(newLR);
    this.lastLR = newLR;
  }

  getLR(): number { return this.optimizer.getLearningRate(); }
  getLastLR(): number { return this.lastLR; }
}

/**
 * Cosine annealing learning rate scheduler
 */
export class CosineAnnealingLRScheduler implements LRScheduler {
  name = 'CosineAnnealingLR';
  private currentEpoch = 0;
  private baseLR: number;
  private lastLR: number;

  constructor(
    private optimizer: Optimizer,
    private T_max: number,
    private etaMin: number = 0
  ) {
    this.baseLR = optimizer.getLearningRate();
    this.lastLR = this.baseLR;
  }

  step(epoch?: number): void {
    if (epoch !== undefined) {
      this.currentEpoch = epoch;
    } else {
      this.currentEpoch++;
    }

    const newLR = this.etaMin + (this.baseLR - this.etaMin) *
      (1 + Math.cos(Math.PI * this.currentEpoch / this.T_max)) / 2;

    this.optimizer.setLearningRate(newLR);
    this.lastLR = newLR;
  }

  getLR(): number { return this.optimizer.getLearningRate(); }
  getLastLR(): number { return this.lastLR; }
}

/**
 * Reduce learning rate on plateau
 */
export class ReduceLROnPlateauScheduler implements LRScheduler {
  name = 'ReduceLROnPlateau';
  private lastLR: number;
  private bestMetric: number;
  private numBadEpochs = 0;
  private cooldownCounter = 0;

  constructor(
    private optimizer: Optimizer,
    private mode: 'min' | 'max' = 'min',
    private factor: number = 0.1,
    private patience: number = 10,
    private threshold: number = 1e-4,
    private cooldown: number = 0,
    private minLR: number = 0
  ) {
    this.lastLR = optimizer.getLearningRate();
    this.bestMetric = mode === 'min' ? Infinity : -Infinity;
  }

  step(metric?: number): void {
    if (metric === undefined) return;

    if (this.cooldownCounter > 0) {
      this.cooldownCounter--;
      return;
    }

    const isBetter = this.mode === 'min'
      ? metric < this.bestMetric - this.threshold
      : metric > this.bestMetric + this.threshold;

    if (isBetter) {
      this.bestMetric = metric;
      this.numBadEpochs = 0;
    } else {
      this.numBadEpochs++;
    }

    if (this.numBadEpochs > this.patience) {
      const currentLR = this.optimizer.getLearningRate();
      const newLR = Math.max(currentLR * this.factor, this.minLR);

      if (newLR < currentLR) {
        this.optimizer.setLearningRate(newLR);
        this.lastLR = newLR;
        this.cooldownCounter = this.cooldown;
        this.numBadEpochs = 0;
      }
    }
  }

  getLR(): number { return this.optimizer.getLearningRate(); }
  getLastLR(): number { return this.lastLR; }
}

/**
 * Warmup scheduler - linear warmup followed by another scheduler
 */
export class WarmupLRScheduler implements LRScheduler {
  name = 'WarmupLR';
  private currentStep = 0;
  private baseLR: number;
  private lastLR: number;

  constructor(
    private optimizer: Optimizer,
    private warmupSteps: number,
    private baseScheduler?: LRScheduler
  ) {
    this.baseLR = optimizer.getLearningRate();
    this.lastLR = 0;
    // Start with zero learning rate
    optimizer.setLearningRate(0);
  }

  step(epoch?: number): void {
    this.currentStep++;

    if (this.currentStep <= this.warmupSteps) {
      // Linear warmup
      const warmupFactor = this.currentStep / this.warmupSteps;
      const newLR = this.baseLR * warmupFactor;
      this.optimizer.setLearningRate(newLR);
      this.lastLR = newLR;
    } else if (this.baseScheduler) {
      // Delegate to base scheduler
      this.baseScheduler.step(epoch);
      this.lastLR = this.baseScheduler.getLastLR();
    }
  }

  getLR(): number { return this.optimizer.getLearningRate(); }
  getLastLR(): number { return this.lastLR; }
}

/**
 * One Cycle learning rate scheduler
 * Implements the 1cycle policy from fastai
 */
export class OneCycleLRScheduler implements LRScheduler {
  name = 'OneCycleLR';
  private currentStep = 0;
  private lastLR: number;
  private totalSteps: number;
  private stepSizeUp: number;
  private stepSizeDown: number;
  private baseLR: number;

  constructor(
    private optimizer: Optimizer,
    private maxLR: number,
    totalSteps: number,
    private pctStart: number = 0.3,
    private divFactor: number = 25,
    private finalDivFactor: number = 1e4
  ) {
    this.totalSteps = totalSteps;
    this.stepSizeUp = Math.floor(totalSteps * pctStart);
    this.stepSizeDown = totalSteps - this.stepSizeUp;
    this.baseLR = maxLR / divFactor;
    this.lastLR = this.baseLR;
    optimizer.setLearningRate(this.baseLR);
  }

  step(): void {
    this.currentStep++;

    let newLR: number;

    if (this.currentStep <= this.stepSizeUp) {
      // Warmup phase: linear increase
      const progress = this.currentStep / this.stepSizeUp;
      newLR = this.baseLR + (this.maxLR - this.baseLR) * progress;
    } else {
      // Annealing phase: cosine decrease
      const progress = (this.currentStep - this.stepSizeUp) / this.stepSizeDown;
      const minLR = this.maxLR / this.finalDivFactor;
      newLR = minLR + (this.maxLR - minLR) * (1 + Math.cos(Math.PI * progress)) / 2;
    }

    this.optimizer.setLearningRate(newLR);
    this.lastLR = newLR;
  }

  getLR(): number { return this.optimizer.getLearningRate(); }
  getLastLR(): number { return this.lastLR; }
}

// ============================================================================
// OPTIMIZER FACTORY
// ============================================================================

/**
 * Create optimizer from model
 */
export function createOptimizer(
  model: NNModule,
  type: 'sgd' | 'adam' | 'adamw' | 'rmsprop' | 'adagrad' = 'adam',
  config: Record<string, unknown> = {}
): Optimizer {
  const { weights, gradients } = model.getParameters();
  const paramGroups: ParameterGroup[] = [{ params: weights, grads: gradients }];

  switch (type) {
    case 'sgd':
      return new SGDOptimizer(
        paramGroups,
        (config.lr as number) ?? 0.01,
        (config.momentum as number) ?? 0,
        (config.dampening as number) ?? 0,
        (config.weight_decay as number) ?? 0,
        (config.nesterov as boolean) ?? false
      );

    case 'adam':
      return new AdamOptimizer(
        paramGroups,
        (config.lr as number) ?? 0.001,
        (config.beta1 as number) ?? 0.9,
        (config.beta2 as number) ?? 0.999,
        (config.eps as number) ?? 1e-8,
        (config.weight_decay as number) ?? 0
      );

    case 'adamw':
      return new AdamWOptimizer(
        paramGroups,
        (config.lr as number) ?? 0.001,
        (config.beta1 as number) ?? 0.9,
        (config.beta2 as number) ?? 0.999,
        (config.eps as number) ?? 1e-8,
        (config.weight_decay as number) ?? 0.01
      );

    case 'rmsprop':
      return new RMSpropOptimizer(
        paramGroups,
        (config.lr as number) ?? 0.01,
        (config.alpha as number) ?? 0.99,
        (config.eps as number) ?? 1e-8,
        (config.weight_decay as number) ?? 0,
        (config.momentum as number) ?? 0
      );

    case 'adagrad':
      return new AdagradOptimizer(
        paramGroups,
        (config.lr as number) ?? 0.01,
        (config.lr_decay as number) ?? 0,
        (config.weight_decay as number) ?? 0,
        (config.eps as number) ?? 1e-10
      );

    default:
      throw new Error(`Unknown optimizer type: ${type}`);
  }
}

/**
 * Create learning rate scheduler
 */
export function createScheduler(
  optimizer: Optimizer,
  type: 'step' | 'exponential' | 'cosine' | 'plateau' | 'warmup' | 'onecycle' = 'step',
  config: Record<string, unknown> = {}
): LRScheduler {
  switch (type) {
    case 'step':
      return new StepLRScheduler(
        optimizer,
        (config.step_size as number) ?? 10,
        (config.gamma as number) ?? 0.1
      );

    case 'exponential':
      return new ExponentialLRScheduler(
        optimizer,
        (config.gamma as number) ?? 0.95
      );

    case 'cosine':
      return new CosineAnnealingLRScheduler(
        optimizer,
        (config.T_max as number) ?? 100,
        (config.eta_min as number) ?? 0
      );

    case 'plateau':
      return new ReduceLROnPlateauScheduler(
        optimizer,
        (config.mode as 'min' | 'max') ?? 'min',
        (config.factor as number) ?? 0.1,
        (config.patience as number) ?? 10,
        (config.threshold as number) ?? 1e-4,
        (config.cooldown as number) ?? 0,
        (config.min_lr as number) ?? 0
      );

    case 'warmup':
      return new WarmupLRScheduler(
        optimizer,
        (config.warmup_steps as number) ?? 100
      );

    case 'onecycle':
      return new OneCycleLRScheduler(
        optimizer,
        (config.max_lr as number) ?? 0.01,
        (config.total_steps as number) ?? 1000,
        (config.pct_start as number) ?? 0.3
      );

    default:
      throw new Error(`Unknown scheduler type: ${type}`);
  }
}

// ============================================================================
// EXPORTS
// ============================================================================

export const Optimizers = {
  SGD: SGDOptimizer,
  Adam: AdamOptimizer,
  AdamW: AdamWOptimizer,
  RMSprop: RMSpropOptimizer,
  Adagrad: AdagradOptimizer
};

export const Schedulers = {
  StepLR: StepLRScheduler,
  ExponentialLR: ExponentialLRScheduler,
  CosineAnnealingLR: CosineAnnealingLRScheduler,
  ReduceLROnPlateau: ReduceLROnPlateauScheduler,
  WarmupLR: WarmupLRScheduler,
  OneCycleLR: OneCycleLRScheduler
};
