/**
 * Extended Neural Architectures - Phase 6
 *
 * Advanced neural network components building on LearnabilityEmbeddings:
 * - Convolutional layers (Conv1D, Conv2D)
 * - Recurrent layers (LSTM, GRU)
 * - Attention mechanisms (Multi-head, Self-attention)
 * - Normalization layers (BatchNorm, LayerNorm)
 * - Regularization (Dropout)
 * - Advanced activations (LeakyReLU, ELU, GELU, Swish)
 */

import { GgmlTensor } from './GgmlTensorKernel';
import { NNModule } from './LearnabilityEmbeddings';

// ============================================================================
// ADVANCED ACTIVATION FUNCTIONS
// ============================================================================

/**
 * Leaky ReLU activation: f(x) = max(alpha * x, x)
 */
export class LeakyReLUModule implements NNModule {
  name = 'LeakyReLU';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  private inputCache?: GgmlTensor;

  constructor(private alpha: number = 0.01) {}

  forward(input: GgmlTensor): GgmlTensor {
    if (this.training) this.inputCache = input;

    const output = this.createTensor(input.shape, `leaky_relu_${input.id}`);
    for (let i = 0; i < input.data.length; i++) {
      output.data[i] = input.data[i] > 0 ? input.data[i] : this.alpha * input.data[i];
    }
    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const gradInput = this.createTensor(input.shape, `grad_leaky_relu_${input.id}`);
    const inputVal = this.inputCache || input;

    for (let i = 0; i < gradOutput.data.length; i++) {
      gradInput.data[i] = inputVal.data[i] > 0 ? gradOutput.data[i] : this.alpha * gradOutput.data[i];
    }
    return gradInput;
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }

  private createTensor(shape: number[], name: string): GgmlTensor {
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data: new Float32Array(shape.reduce((a, b) => a * b, 1)),
      dtype: 'f32', requires_grad: true, name
    };
  }
}

/**
 * ELU activation: f(x) = x if x > 0, alpha * (exp(x) - 1) otherwise
 */
export class ELUModule implements NNModule {
  name = 'ELU';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  private inputCache?: GgmlTensor;
  private outputCache?: GgmlTensor;

  constructor(private alpha: number = 1.0) {}

  forward(input: GgmlTensor): GgmlTensor {
    if (this.training) this.inputCache = input;

    const output = this.createTensor(input.shape, `elu_${input.id}`);
    for (let i = 0; i < input.data.length; i++) {
      output.data[i] = input.data[i] > 0
        ? input.data[i]
        : this.alpha * (Math.exp(input.data[i]) - 1);
    }

    if (this.training) this.outputCache = output;
    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const gradInput = this.createTensor(input.shape, `grad_elu_${input.id}`);
    const inputVal = this.inputCache || input;
    const outputVal = this.outputCache;

    for (let i = 0; i < gradOutput.data.length; i++) {
      if (inputVal.data[i] > 0) {
        gradInput.data[i] = gradOutput.data[i];
      } else {
        const eluVal = outputVal ? outputVal.data[i] : this.alpha * (Math.exp(inputVal.data[i]) - 1);
        gradInput.data[i] = gradOutput.data[i] * (eluVal + this.alpha);
      }
    }
    return gradInput;
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }

  private createTensor(shape: number[], name: string): GgmlTensor {
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data: new Float32Array(shape.reduce((a, b) => a * b, 1)),
      dtype: 'f32', requires_grad: true, name
    };
  }
}

/**
 * GELU activation: Gaussian Error Linear Unit
 * f(x) = x * Φ(x) where Φ is the CDF of standard normal
 */
export class GELUModule implements NNModule {
  name = 'GELU';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  private inputCache?: GgmlTensor;

  forward(input: GgmlTensor): GgmlTensor {
    if (this.training) this.inputCache = input;

    const output = this.createTensor(input.shape, `gelu_${input.id}`);
    for (let i = 0; i < input.data.length; i++) {
      const x = input.data[i];
      // Approximation: 0.5 * x * (1 + tanh(sqrt(2/π) * (x + 0.044715 * x^3)))
      const cdf = 0.5 * (1 + Math.tanh(Math.sqrt(2 / Math.PI) * (x + 0.044715 * x * x * x)));
      output.data[i] = x * cdf;
    }
    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const gradInput = this.createTensor(input.shape, `grad_gelu_${input.id}`);
    const inputVal = this.inputCache || input;

    for (let i = 0; i < gradOutput.data.length; i++) {
      const x = inputVal.data[i];
      const cdf = 0.5 * (1 + Math.tanh(Math.sqrt(2 / Math.PI) * (x + 0.044715 * x * x * x)));
      const pdf = Math.exp(-0.5 * x * x) / Math.sqrt(2 * Math.PI);
      gradInput.data[i] = gradOutput.data[i] * (cdf + x * pdf);
    }
    return gradInput;
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }

  private createTensor(shape: number[], name: string): GgmlTensor {
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data: new Float32Array(shape.reduce((a, b) => a * b, 1)),
      dtype: 'f32', requires_grad: true, name
    };
  }
}

/**
 * Swish/SiLU activation: f(x) = x * sigmoid(x)
 */
export class SwishModule implements NNModule {
  name = 'Swish';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  private inputCache?: GgmlTensor;
  private sigmoidCache?: Float32Array;

  forward(input: GgmlTensor): GgmlTensor {
    if (this.training) this.inputCache = input;

    const output = this.createTensor(input.shape, `swish_${input.id}`);
    this.sigmoidCache = new Float32Array(input.data.length);

    for (let i = 0; i < input.data.length; i++) {
      const sig = 1 / (1 + Math.exp(-input.data[i]));
      this.sigmoidCache[i] = sig;
      output.data[i] = input.data[i] * sig;
    }
    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const gradInput = this.createTensor(input.shape, `grad_swish_${input.id}`);
    const inputVal = this.inputCache || input;

    for (let i = 0; i < gradOutput.data.length; i++) {
      const x = inputVal.data[i];
      const sig = this.sigmoidCache?.[i] ?? (1 / (1 + Math.exp(-x)));
      const swish = x * sig;
      // d/dx (x * sigmoid(x)) = sigmoid(x) + x * sigmoid(x) * (1 - sigmoid(x))
      //                       = sigmoid(x) * (1 + x * (1 - sigmoid(x)))
      //                       = swish + sigmoid(x) * (1 - swish)
      gradInput.data[i] = gradOutput.data[i] * (swish + sig * (1 - swish));
    }
    return gradInput;
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }

  private createTensor(shape: number[], name: string): GgmlTensor {
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data: new Float32Array(shape.reduce((a, b) => a * b, 1)),
      dtype: 'f32', requires_grad: true, name
    };
  }
}

// ============================================================================
// NORMALIZATION LAYERS
// ============================================================================

/**
 * Batch Normalization
 * Normalizes across batch dimension with learnable scale (gamma) and shift (beta)
 */
export class BatchNormModule implements NNModule {
  name = 'BatchNorm';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training = true;

  private gamma: GgmlTensor;
  private beta: GgmlTensor;
  private runningMean: Float32Array;
  private runningVar: Float32Array;
  private momentum: number;
  private eps: number;

  private inputCache?: GgmlTensor;
  private normalizedCache?: Float32Array;
  private meanCache?: Float32Array;
  private varCache?: Float32Array;

  constructor(
    private numFeatures: number,
    eps: number = 1e-5,
    momentum: number = 0.1
  ) {
    this.eps = eps;
    this.momentum = momentum;

    // Learnable parameters
    this.gamma = this.createTensor([numFeatures], 'gamma', () => 1);
    this.beta = this.createTensor([numFeatures], 'beta', () => 0);

    // Running statistics
    this.runningMean = new Float32Array(numFeatures);
    this.runningVar = new Float32Array(numFeatures).fill(1);

    this.parameters = [this.gamma, this.beta];
    this.gradients = [
      this.createTensor([numFeatures], 'grad_gamma', () => 0),
      this.createTensor([numFeatures], 'grad_beta', () => 0)
    ];
  }

  forward(input: GgmlTensor): GgmlTensor {
    // Input shape: [batch, features] or [batch, features, ...]
    const batchSize = input.shape[0];
    const output = this.createTensor(input.shape, `bn_${input.id}`);

    if (this.training) {
      this.inputCache = input;
      this.normalizedCache = new Float32Array(input.data.length);
      this.meanCache = new Float32Array(this.numFeatures);
      this.varCache = new Float32Array(this.numFeatures);

      // Compute batch mean and variance
      for (let f = 0; f < this.numFeatures; f++) {
        let mean = 0;
        for (let b = 0; b < batchSize; b++) {
          mean += input.data[b * this.numFeatures + f];
        }
        mean /= batchSize;
        this.meanCache[f] = mean;

        let variance = 0;
        for (let b = 0; b < batchSize; b++) {
          const diff = input.data[b * this.numFeatures + f] - mean;
          variance += diff * diff;
        }
        variance /= batchSize;
        this.varCache[f] = variance;

        // Update running statistics
        this.runningMean[f] = (1 - this.momentum) * this.runningMean[f] + this.momentum * mean;
        this.runningVar[f] = (1 - this.momentum) * this.runningVar[f] + this.momentum * variance;

        // Normalize and scale
        const std = Math.sqrt(variance + this.eps);
        for (let b = 0; b < batchSize; b++) {
          const idx = b * this.numFeatures + f;
          const normalized = (input.data[idx] - mean) / std;
          this.normalizedCache[idx] = normalized;
          output.data[idx] = this.gamma.data[f] * normalized + this.beta.data[f];
        }
      }
    } else {
      // Use running statistics during inference
      for (let f = 0; f < this.numFeatures; f++) {
        const std = Math.sqrt(this.runningVar[f] + this.eps);
        for (let b = 0; b < batchSize; b++) {
          const idx = b * this.numFeatures + f;
          const normalized = (input.data[idx] - this.runningMean[f]) / std;
          output.data[idx] = this.gamma.data[f] * normalized + this.beta.data[f];
        }
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const gradInput = this.createTensor(input.shape, `grad_bn_${input.id}`);

    const gradGamma = this.gradients[0];
    const gradBeta = this.gradients[1];

    for (let f = 0; f < this.numFeatures; f++) {
      const mean = this.meanCache?.[f] ?? 0;
      const variance = this.varCache?.[f] ?? 1;
      const std = Math.sqrt(variance + this.eps);

      let dGamma = 0;
      let dBeta = 0;
      let dMean = 0;
      let dVar = 0;

      // Compute gradients for gamma and beta
      for (let b = 0; b < batchSize; b++) {
        const idx = b * this.numFeatures + f;
        const normalized = this.normalizedCache?.[idx] ?? 0;
        dGamma += gradOutput.data[idx] * normalized;
        dBeta += gradOutput.data[idx];
      }

      gradGamma.data[f] += dGamma;
      gradBeta.data[f] += dBeta;

      // Compute gradient for variance
      for (let b = 0; b < batchSize; b++) {
        const idx = b * this.numFeatures + f;
        const xMinusMean = input.data[idx] - mean;
        dVar += gradOutput.data[idx] * this.gamma.data[f] * xMinusMean * -0.5 * Math.pow(variance + this.eps, -1.5);
      }

      // Compute gradient for mean
      for (let b = 0; b < batchSize; b++) {
        const idx = b * this.numFeatures + f;
        dMean += gradOutput.data[idx] * this.gamma.data[f] * (-1 / std);
      }
      dMean += dVar * (-2 / batchSize) * this.sumXMinusMean(input, f, mean, batchSize);

      // Compute gradient for input
      for (let b = 0; b < batchSize; b++) {
        const idx = b * this.numFeatures + f;
        const xMinusMean = input.data[idx] - mean;
        gradInput.data[idx] = gradOutput.data[idx] * this.gamma.data[f] / std +
          dVar * 2 * xMinusMean / batchSize +
          dMean / batchSize;
      }
    }

    return gradInput;
  }

  private sumXMinusMean(input: GgmlTensor, f: number, mean: number, batchSize: number): number {
    let sum = 0;
    for (let b = 0; b < batchSize; b++) {
      sum += input.data[b * this.numFeatures + f] - mean;
    }
    return sum;
  }

  updateParameters(learningRate: number): void {
    for (let i = 0; i < this.parameters.length; i++) {
      const param = this.parameters[i];
      const grad = this.gradients[i];
      for (let j = 0; j < param.data.length; j++) {
        param.data[j] -= learningRate * grad.data[j];
      }
    }
  }

  zeroGradParameters(): void {
    this.gradients.forEach(grad => grad.data.fill(0));
  }

  getParameters() { return { weights: this.parameters, gradients: this.gradients }; }

  private createTensor(shape: number[], name: string, init?: () => number): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (init) for (let i = 0; i < size; i++) data[i] = init();
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data, dtype: 'f32', requires_grad: true, name
    };
  }
}

/**
 * Layer Normalization
 * Normalizes across feature dimension (used in Transformers)
 */
export class LayerNormModule implements NNModule {
  name = 'LayerNorm';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training = true;

  private gamma: GgmlTensor;
  private beta: GgmlTensor;
  private eps: number;

  private inputCache?: GgmlTensor;
  private meanCache?: Float32Array;
  private varCache?: Float32Array;

  constructor(private normalizedShape: number[], eps: number = 1e-5) {
    this.eps = eps;
    const size = normalizedShape.reduce((a, b) => a * b, 1);

    this.gamma = this.createTensor([size], 'gamma', () => 1);
    this.beta = this.createTensor([size], 'beta', () => 0);

    this.parameters = [this.gamma, this.beta];
    this.gradients = [
      this.createTensor([size], 'grad_gamma', () => 0),
      this.createTensor([size], 'grad_beta', () => 0)
    ];
  }

  forward(input: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const featureSize = input.data.length / batchSize;
    const output = this.createTensor(input.shape, `ln_${input.id}`);

    if (this.training) {
      this.inputCache = input;
      this.meanCache = new Float32Array(batchSize);
      this.varCache = new Float32Array(batchSize);
    }

    for (let b = 0; b < batchSize; b++) {
      // Compute mean
      let mean = 0;
      for (let f = 0; f < featureSize; f++) {
        mean += input.data[b * featureSize + f];
      }
      mean /= featureSize;

      // Compute variance
      let variance = 0;
      for (let f = 0; f < featureSize; f++) {
        const diff = input.data[b * featureSize + f] - mean;
        variance += diff * diff;
      }
      variance /= featureSize;

      if (this.training) {
        this.meanCache![b] = mean;
        this.varCache![b] = variance;
      }

      // Normalize and scale
      const std = Math.sqrt(variance + this.eps);
      for (let f = 0; f < featureSize; f++) {
        const idx = b * featureSize + f;
        const normalized = (input.data[idx] - mean) / std;
        output.data[idx] = this.gamma.data[f] * normalized + this.beta.data[f];
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const featureSize = input.data.length / batchSize;
    const gradInput = this.createTensor(input.shape, `grad_ln_${input.id}`);

    const gradGamma = this.gradients[0];
    const gradBeta = this.gradients[1];

    for (let b = 0; b < batchSize; b++) {
      const mean = this.meanCache?.[b] ?? 0;
      const variance = this.varCache?.[b] ?? 1;
      const std = Math.sqrt(variance + this.eps);

      // Accumulate gradients for gamma and beta
      for (let f = 0; f < featureSize; f++) {
        const idx = b * featureSize + f;
        const normalized = (input.data[idx] - mean) / std;
        gradGamma.data[f] += gradOutput.data[idx] * normalized;
        gradBeta.data[f] += gradOutput.data[idx];
      }

      // Compute gradient for input (simplified)
      let dMean = 0;
      let dVar = 0;

      for (let f = 0; f < featureSize; f++) {
        const idx = b * featureSize + f;
        const xMinusMean = input.data[idx] - mean;
        dVar += gradOutput.data[idx] * this.gamma.data[f] * xMinusMean * -0.5 * Math.pow(variance + this.eps, -1.5);
        dMean += gradOutput.data[idx] * this.gamma.data[f] * (-1 / std);
      }

      for (let f = 0; f < featureSize; f++) {
        const idx = b * featureSize + f;
        const xMinusMean = input.data[idx] - mean;
        gradInput.data[idx] = gradOutput.data[idx] * this.gamma.data[f] / std +
          dVar * 2 * xMinusMean / featureSize +
          dMean / featureSize;
      }
    }

    return gradInput;
  }

  updateParameters(learningRate: number): void {
    for (let i = 0; i < this.parameters.length; i++) {
      const param = this.parameters[i];
      const grad = this.gradients[i];
      for (let j = 0; j < param.data.length; j++) {
        param.data[j] -= learningRate * grad.data[j];
      }
    }
  }

  zeroGradParameters(): void {
    this.gradients.forEach(grad => grad.data.fill(0));
  }

  getParameters() { return { weights: this.parameters, gradients: this.gradients }; }

  private createTensor(shape: number[], name: string, init?: () => number): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (init) for (let i = 0; i < size; i++) data[i] = init();
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data, dtype: 'f32', requires_grad: true, name
    };
  }
}

// ============================================================================
// REGULARIZATION LAYERS
// ============================================================================

/**
 * Dropout layer for regularization
 */
export class DropoutModule implements NNModule {
  name = 'Dropout';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  private mask?: Float32Array;

  constructor(private p: number = 0.5) {
    if (p < 0 || p > 1) throw new Error('Dropout probability must be between 0 and 1');
  }

  forward(input: GgmlTensor): GgmlTensor {
    if (!this.training || this.p === 0) {
      return input;
    }

    const output = this.createTensor(input.shape, `dropout_${input.id}`);
    this.mask = new Float32Array(input.data.length);

    const scale = 1 / (1 - this.p);
    for (let i = 0; i < input.data.length; i++) {
      if (Math.random() > this.p) {
        this.mask[i] = 1;
        output.data[i] = input.data[i] * scale;
      } else {
        this.mask[i] = 0;
        output.data[i] = 0;
      }
    }

    return output;
  }

  backward(_input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    if (!this.training || this.p === 0) {
      return gradOutput;
    }

    const gradInput = this.createTensor(gradOutput.shape, `grad_dropout`);
    const scale = 1 / (1 - this.p);

    for (let i = 0; i < gradOutput.data.length; i++) {
      gradInput.data[i] = this.mask?.[i] ? gradOutput.data[i] * scale : 0;
    }

    return gradInput;
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }

  private createTensor(shape: number[], name: string): GgmlTensor {
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data: new Float32Array(shape.reduce((a, b) => a * b, 1)),
      dtype: 'f32', requires_grad: true, name
    };
  }
}

// ============================================================================
// CONVOLUTIONAL LAYERS
// ============================================================================

/**
 * 1D Convolution layer
 */
export class Conv1DModule implements NNModule {
  name = 'Conv1D';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training = true;

  private weight: GgmlTensor;
  private bias: GgmlTensor | null;
  private inputCache?: GgmlTensor;

  constructor(
    private inChannels: number,
    private outChannels: number,
    private kernelSize: number,
    private stride: number = 1,
    private padding: number = 0,
    private useBias: boolean = true
  ) {
    // Weight shape: [outChannels, inChannels, kernelSize]
    const weightSize = outChannels * inChannels * kernelSize;
    const stdv = 1 / Math.sqrt(inChannels * kernelSize);

    this.weight = this.createTensor(
      [outChannels, inChannels, kernelSize],
      'conv1d_weight',
      () => (Math.random() - 0.5) * 2 * stdv
    );

    this.bias = useBias
      ? this.createTensor([outChannels], 'conv1d_bias', () => 0)
      : null;

    this.parameters = useBias ? [this.weight, this.bias!] : [this.weight];
    this.gradients = this.parameters.map(p =>
      this.createTensor(p.shape, `grad_${p.name}`, () => 0)
    );
  }

  forward(input: GgmlTensor): GgmlTensor {
    // Input shape: [batch, inChannels, length]
    if (this.training) this.inputCache = input;

    const batchSize = input.shape[0];
    const inputLength = input.shape[2];
    const outputLength = Math.floor((inputLength + 2 * this.padding - this.kernelSize) / this.stride) + 1;

    const output = this.createTensor(
      [batchSize, this.outChannels, outputLength],
      `conv1d_out_${input.id}`
    );

    // Perform convolution
    for (let b = 0; b < batchSize; b++) {
      for (let oc = 0; oc < this.outChannels; oc++) {
        for (let o = 0; o < outputLength; o++) {
          let sum = this.bias ? this.bias.data[oc] : 0;

          for (let ic = 0; ic < this.inChannels; ic++) {
            for (let k = 0; k < this.kernelSize; k++) {
              const inputIdx = o * this.stride + k - this.padding;
              if (inputIdx >= 0 && inputIdx < inputLength) {
                const inVal = input.data[b * this.inChannels * inputLength + ic * inputLength + inputIdx];
                const wVal = this.weight.data[oc * this.inChannels * this.kernelSize + ic * this.kernelSize + k];
                sum += inVal * wVal;
              }
            }
          }

          output.data[b * this.outChannels * outputLength + oc * outputLength + o] = sum;
        }
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const inputLength = input.shape[2];
    const outputLength = gradOutput.shape[2];

    const gradInput = this.createTensor(input.shape, `grad_conv1d_input`);
    const gradWeight = this.gradients[0];
    const gradBias = this.useBias ? this.gradients[1] : null;

    // Compute gradients
    for (let b = 0; b < batchSize; b++) {
      for (let oc = 0; oc < this.outChannels; oc++) {
        for (let o = 0; o < outputLength; o++) {
          const gradOut = gradOutput.data[b * this.outChannels * outputLength + oc * outputLength + o];

          if (gradBias) gradBias.data[oc] += gradOut;

          for (let ic = 0; ic < this.inChannels; ic++) {
            for (let k = 0; k < this.kernelSize; k++) {
              const inputIdx = o * this.stride + k - this.padding;
              if (inputIdx >= 0 && inputIdx < inputLength) {
                // Gradient for weight
                const inVal = input.data[b * this.inChannels * inputLength + ic * inputLength + inputIdx];
                gradWeight.data[oc * this.inChannels * this.kernelSize + ic * this.kernelSize + k] += gradOut * inVal;

                // Gradient for input
                const wVal = this.weight.data[oc * this.inChannels * this.kernelSize + ic * this.kernelSize + k];
                gradInput.data[b * this.inChannels * inputLength + ic * inputLength + inputIdx] += gradOut * wVal;
              }
            }
          }
        }
      }
    }

    return gradInput;
  }

  updateParameters(learningRate: number): void {
    for (let i = 0; i < this.parameters.length; i++) {
      const param = this.parameters[i];
      const grad = this.gradients[i];
      for (let j = 0; j < param.data.length; j++) {
        param.data[j] -= learningRate * grad.data[j];
      }
    }
  }

  zeroGradParameters(): void {
    this.gradients.forEach(grad => grad.data.fill(0));
  }

  getParameters() { return { weights: this.parameters, gradients: this.gradients }; }

  private createTensor(shape: number[], name: string, init?: () => number): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (init) for (let i = 0; i < size; i++) data[i] = init();
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data, dtype: 'f32', requires_grad: true, name
    };
  }
}

/**
 * 2D Convolution layer
 */
export class Conv2DModule implements NNModule {
  name = 'Conv2D';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training = true;

  private weight: GgmlTensor;
  private bias: GgmlTensor | null;
  private inputCache?: GgmlTensor;

  constructor(
    private inChannels: number,
    private outChannels: number,
    private kernelSize: [number, number] | number,
    private stride: [number, number] | number = 1,
    private padding: [number, number] | number = 0,
    private useBias: boolean = true
  ) {
    const kH = typeof kernelSize === 'number' ? kernelSize : kernelSize[0];
    const kW = typeof kernelSize === 'number' ? kernelSize : kernelSize[1];

    const stdv = 1 / Math.sqrt(inChannels * kH * kW);

    this.weight = this.createTensor(
      [outChannels, inChannels, kH, kW],
      'conv2d_weight',
      () => (Math.random() - 0.5) * 2 * stdv
    );

    this.bias = useBias
      ? this.createTensor([outChannels], 'conv2d_bias', () => 0)
      : null;

    this.parameters = useBias ? [this.weight, this.bias!] : [this.weight];
    this.gradients = this.parameters.map(p =>
      this.createTensor(p.shape, `grad_${p.name}`, () => 0)
    );
  }

  forward(input: GgmlTensor): GgmlTensor {
    // Input shape: [batch, inChannels, height, width]
    if (this.training) this.inputCache = input;

    const kH = typeof this.kernelSize === 'number' ? this.kernelSize : this.kernelSize[0];
    const kW = typeof this.kernelSize === 'number' ? this.kernelSize : this.kernelSize[1];
    const sH = typeof this.stride === 'number' ? this.stride : this.stride[0];
    const sW = typeof this.stride === 'number' ? this.stride : this.stride[1];
    const pH = typeof this.padding === 'number' ? this.padding : this.padding[0];
    const pW = typeof this.padding === 'number' ? this.padding : this.padding[1];

    const batchSize = input.shape[0];
    const inputHeight = input.shape[2];
    const inputWidth = input.shape[3];
    const outputHeight = Math.floor((inputHeight + 2 * pH - kH) / sH) + 1;
    const outputWidth = Math.floor((inputWidth + 2 * pW - kW) / sW) + 1;

    const output = this.createTensor(
      [batchSize, this.outChannels, outputHeight, outputWidth],
      `conv2d_out_${input.id}`
    );

    // Perform 2D convolution
    for (let b = 0; b < batchSize; b++) {
      for (let oc = 0; oc < this.outChannels; oc++) {
        for (let oh = 0; oh < outputHeight; oh++) {
          for (let ow = 0; ow < outputWidth; ow++) {
            let sum = this.bias ? this.bias.data[oc] : 0;

            for (let ic = 0; ic < this.inChannels; ic++) {
              for (let kh = 0; kh < kH; kh++) {
                for (let kw = 0; kw < kW; kw++) {
                  const ih = oh * sH + kh - pH;
                  const iw = ow * sW + kw - pW;

                  if (ih >= 0 && ih < inputHeight && iw >= 0 && iw < inputWidth) {
                    const inIdx = b * this.inChannels * inputHeight * inputWidth +
                      ic * inputHeight * inputWidth + ih * inputWidth + iw;
                    const wIdx = oc * this.inChannels * kH * kW +
                      ic * kH * kW + kh * kW + kw;
                    sum += input.data[inIdx] * this.weight.data[wIdx];
                  }
                }
              }
            }

            const outIdx = b * this.outChannels * outputHeight * outputWidth +
              oc * outputHeight * outputWidth + oh * outputWidth + ow;
            output.data[outIdx] = sum;
          }
        }
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const kH = typeof this.kernelSize === 'number' ? this.kernelSize : this.kernelSize[0];
    const kW = typeof this.kernelSize === 'number' ? this.kernelSize : this.kernelSize[1];
    const sH = typeof this.stride === 'number' ? this.stride : this.stride[0];
    const sW = typeof this.stride === 'number' ? this.stride : this.stride[1];
    const pH = typeof this.padding === 'number' ? this.padding : this.padding[0];
    const pW = typeof this.padding === 'number' ? this.padding : this.padding[1];

    const batchSize = input.shape[0];
    const inputHeight = input.shape[2];
    const inputWidth = input.shape[3];
    const outputHeight = gradOutput.shape[2];
    const outputWidth = gradOutput.shape[3];

    const gradInput = this.createTensor(input.shape, `grad_conv2d_input`);
    const gradWeight = this.gradients[0];
    const gradBias = this.useBias ? this.gradients[1] : null;

    for (let b = 0; b < batchSize; b++) {
      for (let oc = 0; oc < this.outChannels; oc++) {
        for (let oh = 0; oh < outputHeight; oh++) {
          for (let ow = 0; ow < outputWidth; ow++) {
            const outIdx = b * this.outChannels * outputHeight * outputWidth +
              oc * outputHeight * outputWidth + oh * outputWidth + ow;
            const gradOut = gradOutput.data[outIdx];

            if (gradBias) gradBias.data[oc] += gradOut;

            for (let ic = 0; ic < this.inChannels; ic++) {
              for (let kh = 0; kh < kH; kh++) {
                for (let kw = 0; kw < kW; kw++) {
                  const ih = oh * sH + kh - pH;
                  const iw = ow * sW + kw - pW;

                  if (ih >= 0 && ih < inputHeight && iw >= 0 && iw < inputWidth) {
                    const inIdx = b * this.inChannels * inputHeight * inputWidth +
                      ic * inputHeight * inputWidth + ih * inputWidth + iw;
                    const wIdx = oc * this.inChannels * kH * kW +
                      ic * kH * kW + kh * kW + kw;

                    gradWeight.data[wIdx] += gradOut * input.data[inIdx];
                    gradInput.data[inIdx] += gradOut * this.weight.data[wIdx];
                  }
                }
              }
            }
          }
        }
      }
    }

    return gradInput;
  }

  updateParameters(learningRate: number): void {
    for (let i = 0; i < this.parameters.length; i++) {
      const param = this.parameters[i];
      const grad = this.gradients[i];
      for (let j = 0; j < param.data.length; j++) {
        param.data[j] -= learningRate * grad.data[j];
      }
    }
  }

  zeroGradParameters(): void {
    this.gradients.forEach(grad => grad.data.fill(0));
  }

  getParameters() { return { weights: this.parameters, gradients: this.gradients }; }

  private createTensor(shape: number[], name: string, init?: () => number): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (init) for (let i = 0; i < size; i++) data[i] = init();
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data, dtype: 'f32', requires_grad: true, name
    };
  }
}

// ============================================================================
// RECURRENT LAYERS
// ============================================================================

/**
 * LSTM (Long Short-Term Memory) layer
 */
export class LSTMModule implements NNModule {
  name = 'LSTM';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training = true;

  // Weight matrices for input, forget, cell, output gates
  private Wii: GgmlTensor; private Wif: GgmlTensor; private Wig: GgmlTensor; private Wio: GgmlTensor;
  private Whi: GgmlTensor; private Whf: GgmlTensor; private Whg: GgmlTensor; private Who: GgmlTensor;
  private bi: GgmlTensor; private bf: GgmlTensor; private bg: GgmlTensor; private bo: GgmlTensor;

  private hiddenCache: GgmlTensor[] = [];
  private cellCache: GgmlTensor[] = [];
  private gateCache: { i: Float32Array, f: Float32Array, g: Float32Array, o: Float32Array }[] = [];

  constructor(
    private inputSize: number,
    private hiddenSize: number,
    private numLayers: number = 1
  ) {
    const stdv = 1 / Math.sqrt(hiddenSize);

    // Initialize weights
    this.Wii = this.createTensor([hiddenSize, inputSize], 'Wii', () => (Math.random() - 0.5) * 2 * stdv);
    this.Wif = this.createTensor([hiddenSize, inputSize], 'Wif', () => (Math.random() - 0.5) * 2 * stdv);
    this.Wig = this.createTensor([hiddenSize, inputSize], 'Wig', () => (Math.random() - 0.5) * 2 * stdv);
    this.Wio = this.createTensor([hiddenSize, inputSize], 'Wio', () => (Math.random() - 0.5) * 2 * stdv);

    this.Whi = this.createTensor([hiddenSize, hiddenSize], 'Whi', () => (Math.random() - 0.5) * 2 * stdv);
    this.Whf = this.createTensor([hiddenSize, hiddenSize], 'Whf', () => (Math.random() - 0.5) * 2 * stdv);
    this.Whg = this.createTensor([hiddenSize, hiddenSize], 'Whg', () => (Math.random() - 0.5) * 2 * stdv);
    this.Who = this.createTensor([hiddenSize, hiddenSize], 'Who', () => (Math.random() - 0.5) * 2 * stdv);

    this.bi = this.createTensor([hiddenSize], 'bi', () => 0);
    this.bf = this.createTensor([hiddenSize], 'bf', () => 1); // Initialize forget gate bias to 1
    this.bg = this.createTensor([hiddenSize], 'bg', () => 0);
    this.bo = this.createTensor([hiddenSize], 'bo', () => 0);

    this.parameters = [
      this.Wii, this.Wif, this.Wig, this.Wio,
      this.Whi, this.Whf, this.Whg, this.Who,
      this.bi, this.bf, this.bg, this.bo
    ];

    this.gradients = this.parameters.map(p =>
      this.createTensor(p.shape, `grad_${p.name}`, () => 0)
    );
  }

  forward(input: GgmlTensor, initialState?: { h: GgmlTensor, c: GgmlTensor }): GgmlTensor {
    // Input shape: [seqLen, batch, inputSize]
    const seqLen = input.shape[0];
    const batchSize = input.shape[1];

    let h = initialState?.h || this.createTensor([batchSize, this.hiddenSize], 'h0', () => 0);
    let c = initialState?.c || this.createTensor([batchSize, this.hiddenSize], 'c0', () => 0);

    const outputs: Float32Array[] = [];
    this.hiddenCache = [];
    this.cellCache = [];
    this.gateCache = [];

    for (let t = 0; t < seqLen; t++) {
      // Extract input at time t
      const xt = new Float32Array(batchSize * this.inputSize);
      for (let b = 0; b < batchSize; b++) {
        for (let i = 0; i < this.inputSize; i++) {
          xt[b * this.inputSize + i] = input.data[t * batchSize * this.inputSize + b * this.inputSize + i];
        }
      }

      const gates = {
        i: new Float32Array(batchSize * this.hiddenSize),
        f: new Float32Array(batchSize * this.hiddenSize),
        g: new Float32Array(batchSize * this.hiddenSize),
        o: new Float32Array(batchSize * this.hiddenSize)
      };

      const newH = new Float32Array(batchSize * this.hiddenSize);
      const newC = new Float32Array(batchSize * this.hiddenSize);

      for (let b = 0; b < batchSize; b++) {
        for (let j = 0; j < this.hiddenSize; j++) {
          // Compute gates
          let iGate = this.bi.data[j];
          let fGate = this.bf.data[j];
          let gGate = this.bg.data[j];
          let oGate = this.bo.data[j];

          for (let k = 0; k < this.inputSize; k++) {
            const x = xt[b * this.inputSize + k];
            iGate += this.Wii.data[j * this.inputSize + k] * x;
            fGate += this.Wif.data[j * this.inputSize + k] * x;
            gGate += this.Wig.data[j * this.inputSize + k] * x;
            oGate += this.Wio.data[j * this.inputSize + k] * x;
          }

          for (let k = 0; k < this.hiddenSize; k++) {
            const hPrev = h.data[b * this.hiddenSize + k];
            iGate += this.Whi.data[j * this.hiddenSize + k] * hPrev;
            fGate += this.Whf.data[j * this.hiddenSize + k] * hPrev;
            gGate += this.Whg.data[j * this.hiddenSize + k] * hPrev;
            oGate += this.Who.data[j * this.hiddenSize + k] * hPrev;
          }

          // Apply activations
          const idx = b * this.hiddenSize + j;
          gates.i[idx] = this.sigmoid(iGate);
          gates.f[idx] = this.sigmoid(fGate);
          gates.g[idx] = Math.tanh(gGate);
          gates.o[idx] = this.sigmoid(oGate);

          // Update cell and hidden state
          newC[idx] = gates.f[idx] * c.data[idx] + gates.i[idx] * gates.g[idx];
          newH[idx] = gates.o[idx] * Math.tanh(newC[idx]);
        }
      }

      if (this.training) {
        this.hiddenCache.push({ ...h, data: new Float32Array(h.data) });
        this.cellCache.push({ ...c, data: new Float32Array(c.data) });
        this.gateCache.push(gates);
      }

      h = { ...h, data: newH };
      c = { ...c, data: newC };
      outputs.push(newH);
    }

    // Concatenate outputs: [seqLen, batch, hiddenSize]
    const output = this.createTensor([seqLen, batchSize, this.hiddenSize], 'lstm_out');
    for (let t = 0; t < seqLen; t++) {
      for (let i = 0; i < batchSize * this.hiddenSize; i++) {
        output.data[t * batchSize * this.hiddenSize + i] = outputs[t][i];
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    // Simplified backward pass (BPTT)
    const seqLen = input.shape[0];
    const batchSize = input.shape[1];
    const gradInput = this.createTensor(input.shape, 'grad_lstm_input');

    // Initialize gradients for hidden and cell states
    let dh = new Float32Array(batchSize * this.hiddenSize);
    let dc = new Float32Array(batchSize * this.hiddenSize);

    for (let t = seqLen - 1; t >= 0; t--) {
      const gates = this.gateCache[t];
      const hPrev = t > 0 ? this.hiddenCache[t - 1] : null;
      const cPrev = t > 0 ? this.cellCache[t - 1] : null;
      const c = this.cellCache[t];

      // Add gradient from output
      for (let i = 0; i < batchSize * this.hiddenSize; i++) {
        dh[i] += gradOutput.data[t * batchSize * this.hiddenSize + i];
      }

      for (let b = 0; b < batchSize; b++) {
        for (let j = 0; j < this.hiddenSize; j++) {
          const idx = b * this.hiddenSize + j;

          // Gradient through output gate
          const tanhC = Math.tanh(c.data[idx]);
          const do_ = dh[idx] * tanhC;
          const dc_from_h = dh[idx] * gates.o[idx] * (1 - tanhC * tanhC);
          dc[idx] += dc_from_h;

          // Gradient through cell update
          const di = dc[idx] * gates.g[idx];
          const df = dc[idx] * (cPrev?.data[idx] ?? 0);
          const dg = dc[idx] * gates.i[idx];

          // Gradient through activations
          const di_pre = di * gates.i[idx] * (1 - gates.i[idx]);
          const df_pre = df * gates.f[idx] * (1 - gates.f[idx]);
          const dg_pre = dg * (1 - gates.g[idx] * gates.g[idx]);
          const do_pre = do_ * gates.o[idx] * (1 - gates.o[idx]);

          // Accumulate gradients for biases
          this.gradients[8].data[j] += di_pre;  // bi
          this.gradients[9].data[j] += df_pre;  // bf
          this.gradients[10].data[j] += dg_pre; // bg
          this.gradients[11].data[j] += do_pre; // bo

          // Gradient for cell state to previous timestep
          if (t > 0) {
            dc[idx] = dc[idx] * gates.f[idx];
          }
        }
      }
    }

    return gradInput;
  }

  private sigmoid(x: number): number {
    return 1 / (1 + Math.exp(-x));
  }

  updateParameters(learningRate: number): void {
    for (let i = 0; i < this.parameters.length; i++) {
      const param = this.parameters[i];
      const grad = this.gradients[i];
      for (let j = 0; j < param.data.length; j++) {
        param.data[j] -= learningRate * grad.data[j];
      }
    }
  }

  zeroGradParameters(): void {
    this.gradients.forEach(grad => grad.data.fill(0));
    this.hiddenCache = [];
    this.cellCache = [];
    this.gateCache = [];
  }

  getParameters() { return { weights: this.parameters, gradients: this.gradients }; }

  private createTensor(shape: number[], name: string, init?: () => number): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (init) for (let i = 0; i < size; i++) data[i] = init();
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data, dtype: 'f32', requires_grad: true, name
    };
  }
}

/**
 * GRU (Gated Recurrent Unit) layer
 */
export class GRUModule implements NNModule {
  name = 'GRU';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training = true;

  private Wir: GgmlTensor; private Wiz: GgmlTensor; private Win: GgmlTensor;
  private Whr: GgmlTensor; private Whz: GgmlTensor; private Whn: GgmlTensor;
  private br: GgmlTensor; private bz: GgmlTensor; private bn: GgmlTensor;

  constructor(
    private inputSize: number,
    private hiddenSize: number
  ) {
    const stdv = 1 / Math.sqrt(hiddenSize);

    this.Wir = this.createTensor([hiddenSize, inputSize], 'Wir', () => (Math.random() - 0.5) * 2 * stdv);
    this.Wiz = this.createTensor([hiddenSize, inputSize], 'Wiz', () => (Math.random() - 0.5) * 2 * stdv);
    this.Win = this.createTensor([hiddenSize, inputSize], 'Win', () => (Math.random() - 0.5) * 2 * stdv);

    this.Whr = this.createTensor([hiddenSize, hiddenSize], 'Whr', () => (Math.random() - 0.5) * 2 * stdv);
    this.Whz = this.createTensor([hiddenSize, hiddenSize], 'Whz', () => (Math.random() - 0.5) * 2 * stdv);
    this.Whn = this.createTensor([hiddenSize, hiddenSize], 'Whn', () => (Math.random() - 0.5) * 2 * stdv);

    this.br = this.createTensor([hiddenSize], 'br', () => 0);
    this.bz = this.createTensor([hiddenSize], 'bz', () => 0);
    this.bn = this.createTensor([hiddenSize], 'bn', () => 0);

    this.parameters = [this.Wir, this.Wiz, this.Win, this.Whr, this.Whz, this.Whn, this.br, this.bz, this.bn];
    this.gradients = this.parameters.map(p => this.createTensor(p.shape, `grad_${p.name}`, () => 0));
  }

  forward(input: GgmlTensor, initialState?: GgmlTensor): GgmlTensor {
    const seqLen = input.shape[0];
    const batchSize = input.shape[1];

    let h = initialState || this.createTensor([batchSize, this.hiddenSize], 'h0', () => 0);
    const outputs: Float32Array[] = [];

    for (let t = 0; t < seqLen; t++) {
      const newH = new Float32Array(batchSize * this.hiddenSize);

      for (let b = 0; b < batchSize; b++) {
        for (let j = 0; j < this.hiddenSize; j++) {
          let rGate = this.br.data[j];
          let zGate = this.bz.data[j];
          let nGate = this.bn.data[j];

          for (let k = 0; k < this.inputSize; k++) {
            const x = input.data[t * batchSize * this.inputSize + b * this.inputSize + k];
            rGate += this.Wir.data[j * this.inputSize + k] * x;
            zGate += this.Wiz.data[j * this.inputSize + k] * x;
            nGate += this.Win.data[j * this.inputSize + k] * x;
          }

          for (let k = 0; k < this.hiddenSize; k++) {
            const hPrev = h.data[b * this.hiddenSize + k];
            rGate += this.Whr.data[j * this.hiddenSize + k] * hPrev;
            zGate += this.Whz.data[j * this.hiddenSize + k] * hPrev;
          }

          const r = this.sigmoid(rGate);
          const z = this.sigmoid(zGate);

          // Compute n with reset gate applied
          for (let k = 0; k < this.hiddenSize; k++) {
            const hPrev = h.data[b * this.hiddenSize + k];
            nGate += this.Whn.data[j * this.hiddenSize + k] * (r * hPrev);
          }
          const n = Math.tanh(nGate);

          const idx = b * this.hiddenSize + j;
          newH[idx] = (1 - z) * n + z * h.data[idx];
        }
      }

      h = { ...h, data: newH };
      outputs.push(newH);
    }

    const output = this.createTensor([seqLen, batchSize, this.hiddenSize], 'gru_out');
    for (let t = 0; t < seqLen; t++) {
      for (let i = 0; i < batchSize * this.hiddenSize; i++) {
        output.data[t * batchSize * this.hiddenSize + i] = outputs[t][i];
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    return this.createTensor(input.shape, 'grad_gru_input');
  }

  private sigmoid(x: number): number {
    return 1 / (1 + Math.exp(-x));
  }

  updateParameters(learningRate: number): void {
    for (let i = 0; i < this.parameters.length; i++) {
      const param = this.parameters[i];
      const grad = this.gradients[i];
      for (let j = 0; j < param.data.length; j++) {
        param.data[j] -= learningRate * grad.data[j];
      }
    }
  }

  zeroGradParameters(): void {
    this.gradients.forEach(grad => grad.data.fill(0));
  }

  getParameters() { return { weights: this.parameters, gradients: this.gradients }; }

  private createTensor(shape: number[], name: string, init?: () => number): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (init) for (let i = 0; i < size; i++) data[i] = init();
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data, dtype: 'f32', requires_grad: true, name
    };
  }
}

// ============================================================================
// ATTENTION MECHANISMS
// ============================================================================

/**
 * Multi-Head Self-Attention (Transformer-style)
 */
export class MultiHeadAttentionModule implements NNModule {
  name = 'MultiHeadAttention';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training = true;

  private Wq: GgmlTensor;
  private Wk: GgmlTensor;
  private Wv: GgmlTensor;
  private Wo: GgmlTensor;

  private headDim: number;
  private scale: number;

  constructor(
    private embedDim: number,
    private numHeads: number,
    private dropout: number = 0.0
  ) {
    if (embedDim % numHeads !== 0) {
      throw new Error('embedDim must be divisible by numHeads');
    }

    this.headDim = embedDim / numHeads;
    this.scale = 1 / Math.sqrt(this.headDim);

    const stdv = 1 / Math.sqrt(embedDim);

    this.Wq = this.createTensor([embedDim, embedDim], 'Wq', () => (Math.random() - 0.5) * 2 * stdv);
    this.Wk = this.createTensor([embedDim, embedDim], 'Wk', () => (Math.random() - 0.5) * 2 * stdv);
    this.Wv = this.createTensor([embedDim, embedDim], 'Wv', () => (Math.random() - 0.5) * 2 * stdv);
    this.Wo = this.createTensor([embedDim, embedDim], 'Wo', () => (Math.random() - 0.5) * 2 * stdv);

    this.parameters = [this.Wq, this.Wk, this.Wv, this.Wo];
    this.gradients = this.parameters.map(p => this.createTensor(p.shape, `grad_${p.name}`, () => 0));
  }

  forward(query: GgmlTensor, key?: GgmlTensor, value?: GgmlTensor, mask?: GgmlTensor): GgmlTensor {
    // Self-attention if key/value not provided
    const k = key || query;
    const v = value || query;

    // Input shape: [batch, seqLen, embedDim]
    const batchSize = query.shape[0];
    const seqLenQ = query.shape[1];
    const seqLenK = k.shape[1];

    // Project Q, K, V
    const Q = this.linearProject(query, this.Wq);
    const K = this.linearProject(k, this.Wk);
    const V = this.linearProject(v, this.Wv);

    // Reshape for multi-head: [batch, numHeads, seqLen, headDim]
    // Compute attention scores
    const scores = this.createTensor([batchSize, this.numHeads, seqLenQ, seqLenK], 'attn_scores');

    for (let b = 0; b < batchSize; b++) {
      for (let h = 0; h < this.numHeads; h++) {
        for (let i = 0; i < seqLenQ; i++) {
          for (let j = 0; j < seqLenK; j++) {
            let score = 0;
            for (let d = 0; d < this.headDim; d++) {
              const qIdx = b * seqLenQ * this.embedDim + i * this.embedDim + h * this.headDim + d;
              const kIdx = b * seqLenK * this.embedDim + j * this.embedDim + h * this.headDim + d;
              score += Q.data[qIdx] * K.data[kIdx];
            }

            const scoreIdx = b * this.numHeads * seqLenQ * seqLenK +
              h * seqLenQ * seqLenK + i * seqLenK + j;
            scores.data[scoreIdx] = score * this.scale;

            // Apply mask if provided
            if (mask && mask.data[i * seqLenK + j] === 0) {
              scores.data[scoreIdx] = -1e9;
            }
          }
        }
      }
    }

    // Softmax over last dimension
    const attnWeights = this.softmax(scores);

    // Apply attention to values
    const attnOutput = this.createTensor([batchSize, seqLenQ, this.embedDim], 'attn_output');

    for (let b = 0; b < batchSize; b++) {
      for (let i = 0; i < seqLenQ; i++) {
        for (let h = 0; h < this.numHeads; h++) {
          for (let d = 0; d < this.headDim; d++) {
            let val = 0;
            for (let j = 0; j < seqLenK; j++) {
              const weightIdx = b * this.numHeads * seqLenQ * seqLenK +
                h * seqLenQ * seqLenK + i * seqLenK + j;
              const vIdx = b * seqLenK * this.embedDim + j * this.embedDim + h * this.headDim + d;
              val += attnWeights.data[weightIdx] * V.data[vIdx];
            }
            const outIdx = b * seqLenQ * this.embedDim + i * this.embedDim + h * this.headDim + d;
            attnOutput.data[outIdx] = val;
          }
        }
      }
    }

    // Final projection
    return this.linearProject(attnOutput, this.Wo);
  }

  private linearProject(input: GgmlTensor, weight: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const seqLen = input.shape[1];
    const output = this.createTensor(input.shape, 'linear_proj');

    for (let b = 0; b < batchSize; b++) {
      for (let s = 0; s < seqLen; s++) {
        for (let o = 0; o < this.embedDim; o++) {
          let sum = 0;
          for (let i = 0; i < this.embedDim; i++) {
            const inIdx = b * seqLen * this.embedDim + s * this.embedDim + i;
            sum += input.data[inIdx] * weight.data[o * this.embedDim + i];
          }
          output.data[b * seqLen * this.embedDim + s * this.embedDim + o] = sum;
        }
      }
    }

    return output;
  }

  private softmax(tensor: GgmlTensor): GgmlTensor {
    const result = this.createTensor(tensor.shape, 'softmax');
    const lastDim = tensor.shape[tensor.shape.length - 1];
    const numElements = tensor.data.length / lastDim;

    for (let i = 0; i < numElements; i++) {
      const offset = i * lastDim;

      // Find max for numerical stability
      let max = -Infinity;
      for (let j = 0; j < lastDim; j++) {
        max = Math.max(max, tensor.data[offset + j]);
      }

      // Compute exp and sum
      let sum = 0;
      for (let j = 0; j < lastDim; j++) {
        const exp = Math.exp(tensor.data[offset + j] - max);
        result.data[offset + j] = exp;
        sum += exp;
      }

      // Normalize
      for (let j = 0; j < lastDim; j++) {
        result.data[offset + j] /= sum;
      }
    }

    return result;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    return this.createTensor(input.shape, 'grad_mha_input');
  }

  updateParameters(learningRate: number): void {
    for (let i = 0; i < this.parameters.length; i++) {
      const param = this.parameters[i];
      const grad = this.gradients[i];
      for (let j = 0; j < param.data.length; j++) {
        param.data[j] -= learningRate * grad.data[j];
      }
    }
  }

  zeroGradParameters(): void {
    this.gradients.forEach(grad => grad.data.fill(0));
  }

  getParameters() { return { weights: this.parameters, gradients: this.gradients }; }

  private createTensor(shape: number[], name: string, init?: () => number): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (init) for (let i = 0; i < size; i++) data[i] = init();
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data, dtype: 'f32', requires_grad: true, name
    };
  }
}

// ============================================================================
// POOLING LAYERS
// ============================================================================

/**
 * Max Pooling 1D
 */
export class MaxPool1DModule implements NNModule {
  name = 'MaxPool1D';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  private maxIndices?: Int32Array;

  constructor(
    private kernelSize: number,
    private stride?: number,
    private padding: number = 0
  ) {
    this.stride = stride || kernelSize;
  }

  forward(input: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const channels = input.shape[1];
    const inputLength = input.shape[2];
    const outputLength = Math.floor((inputLength + 2 * this.padding - this.kernelSize) / this.stride!) + 1;

    const output = this.createTensor([batchSize, channels, outputLength], 'maxpool1d_out');
    this.maxIndices = new Int32Array(output.data.length);

    for (let b = 0; b < batchSize; b++) {
      for (let c = 0; c < channels; c++) {
        for (let o = 0; o < outputLength; o++) {
          let maxVal = -Infinity;
          let maxIdx = 0;

          for (let k = 0; k < this.kernelSize; k++) {
            const inputIdx = o * this.stride! + k - this.padding;
            if (inputIdx >= 0 && inputIdx < inputLength) {
              const idx = b * channels * inputLength + c * inputLength + inputIdx;
              if (input.data[idx] > maxVal) {
                maxVal = input.data[idx];
                maxIdx = inputIdx;
              }
            }
          }

          const outIdx = b * channels * outputLength + c * outputLength + o;
          output.data[outIdx] = maxVal;
          this.maxIndices[outIdx] = maxIdx;
        }
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const channels = input.shape[1];
    const inputLength = input.shape[2];
    const outputLength = gradOutput.shape[2];

    const gradInput = this.createTensor(input.shape, 'grad_maxpool1d');

    for (let b = 0; b < batchSize; b++) {
      for (let c = 0; c < channels; c++) {
        for (let o = 0; o < outputLength; o++) {
          const outIdx = b * channels * outputLength + c * outputLength + o;
          const maxIdx = this.maxIndices?.[outIdx] ?? 0;
          const inIdx = b * channels * inputLength + c * inputLength + maxIdx;
          gradInput.data[inIdx] += gradOutput.data[outIdx];
        }
      }
    }

    return gradInput;
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }

  private createTensor(shape: number[], name: string): GgmlTensor {
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data: new Float32Array(shape.reduce((a, b) => a * b, 1)),
      dtype: 'f32', requires_grad: true, name
    };
  }
}

/**
 * Average Pooling 1D
 */
export class AvgPool1DModule implements NNModule {
  name = 'AvgPool1D';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  constructor(
    private kernelSize: number,
    private stride?: number,
    private padding: number = 0
  ) {
    this.stride = stride || kernelSize;
  }

  forward(input: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const channels = input.shape[1];
    const inputLength = input.shape[2];
    const outputLength = Math.floor((inputLength + 2 * this.padding - this.kernelSize) / this.stride!) + 1;

    const output = this.createTensor([batchSize, channels, outputLength], 'avgpool1d_out');

    for (let b = 0; b < batchSize; b++) {
      for (let c = 0; c < channels; c++) {
        for (let o = 0; o < outputLength; o++) {
          let sum = 0;
          let count = 0;

          for (let k = 0; k < this.kernelSize; k++) {
            const inputIdx = o * this.stride! + k - this.padding;
            if (inputIdx >= 0 && inputIdx < inputLength) {
              sum += input.data[b * channels * inputLength + c * inputLength + inputIdx];
              count++;
            }
          }

          output.data[b * channels * outputLength + c * outputLength + o] = sum / count;
        }
      }
    }

    return output;
  }

  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const batchSize = input.shape[0];
    const channels = input.shape[1];
    const inputLength = input.shape[2];
    const outputLength = gradOutput.shape[2];

    const gradInput = this.createTensor(input.shape, 'grad_avgpool1d');

    for (let b = 0; b < batchSize; b++) {
      for (let c = 0; c < channels; c++) {
        for (let o = 0; o < outputLength; o++) {
          let count = 0;
          for (let k = 0; k < this.kernelSize; k++) {
            const inputIdx = o * this.stride! + k - this.padding;
            if (inputIdx >= 0 && inputIdx < inputLength) count++;
          }

          const gradVal = gradOutput.data[b * channels * outputLength + c * outputLength + o] / count;

          for (let k = 0; k < this.kernelSize; k++) {
            const inputIdx = o * this.stride! + k - this.padding;
            if (inputIdx >= 0 && inputIdx < inputLength) {
              gradInput.data[b * channels * inputLength + c * inputLength + inputIdx] += gradVal;
            }
          }
        }
      }
    }

    return gradInput;
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }

  private createTensor(shape: number[], name: string): GgmlTensor {
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape, data: new Float32Array(shape.reduce((a, b) => a * b, 1)),
      dtype: 'f32', requires_grad: true, name
    };
  }
}

// ============================================================================
// UTILITY LAYERS
// ============================================================================

/**
 * Flatten layer
 */
export class FlattenModule implements NNModule {
  name = 'Flatten';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training = true;

  private originalShape?: number[];

  constructor(private startDim: number = 1, private endDim: number = -1) {}

  forward(input: GgmlTensor): GgmlTensor {
    this.originalShape = [...input.shape];

    const endDim = this.endDim < 0 ? input.shape.length + this.endDim : this.endDim;

    const newShape: number[] = [];
    let flattenedSize = 1;

    for (let i = 0; i < input.shape.length; i++) {
      if (i < this.startDim) {
        newShape.push(input.shape[i]);
      } else if (i <= endDim) {
        flattenedSize *= input.shape[i];
      } else {
        if (flattenedSize > 1) {
          newShape.push(flattenedSize);
          flattenedSize = 1;
        }
        newShape.push(input.shape[i]);
      }
    }
    if (flattenedSize > 1) {
      newShape.push(flattenedSize);
    }

    const output: GgmlTensor = {
      id: `flatten_${input.id}`,
      shape: newShape,
      data: input.data,
      dtype: input.dtype,
      requires_grad: input.requires_grad,
      name: 'flatten_out'
    };

    return output;
  }

  backward(_input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    return {
      ...gradOutput,
      shape: this.originalShape || gradOutput.shape,
      id: `grad_flatten_${gradOutput.id}`
    };
  }

  updateParameters(_lr: number): void {}
  zeroGradParameters(): void {}
  getParameters() { return { weights: [], gradients: [] }; }
}

// ============================================================================
// EXPORTS
// ============================================================================

export const ExtendedArchitectures = {
  // Activations
  LeakyReLU: LeakyReLUModule,
  ELU: ELUModule,
  GELU: GELUModule,
  Swish: SwishModule,

  // Normalization
  BatchNorm: BatchNormModule,
  LayerNorm: LayerNormModule,

  // Regularization
  Dropout: DropoutModule,

  // Convolution
  Conv1D: Conv1DModule,
  Conv2D: Conv2DModule,

  // Recurrent
  LSTM: LSTMModule,
  GRU: GRUModule,

  // Attention
  MultiHeadAttention: MultiHeadAttentionModule,

  // Pooling
  MaxPool1D: MaxPool1DModule,
  AvgPool1D: AvgPool1DModule,

  // Utility
  Flatten: FlattenModule
};
