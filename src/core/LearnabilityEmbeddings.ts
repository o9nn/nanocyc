/**
 * Learnability Embeddings Module
 * 
 * Inspired by Torch7's nn Lua framework, this module provides neural network primitives
 * for creating learnable representations in the cognitive architecture.
 * 
 * Key concepts from Torch7 nn:
 * - Module: Base class for all neural network components
 * - Container: Modules that contain other modules (Sequential, Parallel)
 * - Criterion: Loss functions for training
 * - Learnable parameters with gradient tracking
 */

import { GgmlTensor, TensorContext } from './GgmlTensorKernel';

/**
 * Base neural network module interface (inspired by nn.Module)
 */
export interface NNModule {
  name: string;
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training: boolean;
  
  forward(input: GgmlTensor): GgmlTensor;
  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor;
  updateParameters(learningRate: number): void;
  zeroGradParameters(): void;
  getParameters(): { weights: GgmlTensor[], gradients: GgmlTensor[] };
}

/**
 * Linear layer (nn.Linear)
 * Applies affine transformation: y = Wx + b
 */
export class LinearModule implements NNModule {
  name: string = 'Linear';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training: boolean = true;
  
  private weight: GgmlTensor;
  private bias: GgmlTensor;
  private inputCache?: GgmlTensor;
  
  constructor(
    private inputSize: number,
    private outputSize: number,
    private useBias: boolean = true
  ) {
    // Initialize weight with Xavier/Glorot initialization
    const stdv = 1.0 / Math.sqrt(inputSize);
    this.weight = this.createTensor(
      [outputSize, inputSize],
      'weight',
      () => (Math.random() - 0.5) * 2 * stdv
    );
    
    this.bias = useBias
      ? this.createTensor([outputSize], 'bias', () => 0)
      : this.createTensor([outputSize], 'bias', () => 0);
    
    this.parameters = useBias ? [this.weight, this.bias] : [this.weight];
    this.gradients = this.parameters.map(p => ({
      ...p,
      id: `grad_${p.id}`,
      data: new Float32Array(p.data.length)
    }));
  }
  
  forward(input: GgmlTensor): GgmlTensor {
    if (this.training) {
      this.inputCache = input;
    }
    
    // Matrix multiplication: output = input * W^T + b
    const batchSize = input.shape[0];
    const output = this.createTensor([batchSize, this.outputSize], 'linear_output');
    
    for (let i = 0; i < batchSize; i++) {
      for (let j = 0; j < this.outputSize; j++) {
        let sum = this.useBias ? this.bias.data[j] : 0;
        for (let k = 0; k < this.inputSize; k++) {
          sum += input.data[i * this.inputSize + k] * 
                 this.weight.data[j * this.inputSize + k];
        }
        output.data[i * this.outputSize + j] = sum;
      }
    }
    
    return output;
  }
  
  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const batchSize = gradOutput.shape[0];
    const gradInput = this.createTensor(input.shape, 'grad_input');
    
    // Compute gradient w.r.t input: gradInput = gradOutput * W
    for (let i = 0; i < batchSize; i++) {
      for (let k = 0; k < this.inputSize; k++) {
        let sum = 0;
        for (let j = 0; j < this.outputSize; j++) {
          sum += gradOutput.data[i * this.outputSize + j] * 
                 this.weight.data[j * this.inputSize + k];
        }
        gradInput.data[i * this.inputSize + k] = sum;
      }
    }
    
    // Compute gradient w.r.t weights: gradWeight += gradOutput^T * input
    const weightGrad = this.gradients[0];
    for (let j = 0; j < this.outputSize; j++) {
      for (let k = 0; k < this.inputSize; k++) {
        let sum = 0;
        for (let i = 0; i < batchSize; i++) {
          sum += gradOutput.data[i * this.outputSize + j] * 
                 input.data[i * this.inputSize + k];
        }
        weightGrad.data[j * this.inputSize + k] += sum;
      }
    }
    
    // Compute gradient w.r.t bias: gradBias += sum(gradOutput, dim=0)
    if (this.useBias) {
      const biasGrad = this.gradients[1];
      for (let j = 0; j < this.outputSize; j++) {
        let sum = 0;
        for (let i = 0; i < batchSize; i++) {
          sum += gradOutput.data[i * this.outputSize + j];
        }
        biasGrad.data[j] += sum;
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
    this.gradients.forEach(grad => {
      for (let i = 0; i < grad.data.length; i++) {
        grad.data[i] = 0;
      }
    });
  }
  
  getParameters(): { weights: GgmlTensor[], gradients: GgmlTensor[] } {
    return { weights: this.parameters, gradients: this.gradients };
  }
  
  private createTensor(
    shape: number[],
    name: string,
    initializer?: () => number
  ): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (initializer) {
      for (let i = 0; i < size; i++) {
        data[i] = initializer();
      }
    }
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape,
      data,
      dtype: 'f32',
      requires_grad: true,
      name
    };
  }
}

/**
 * Tanh activation (nn.Tanh)
 */
export class TanhModule implements NNModule {
  name: string = 'Tanh';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training: boolean = true;
  
  private outputCache?: GgmlTensor;
  
  forward(input: GgmlTensor): GgmlTensor {
    const output = {
      ...input,
      id: `tanh_${input.id}`,
      data: new Float32Array(input.data.length)
    };
    
    for (let i = 0; i < input.data.length; i++) {
      output.data[i] = Math.tanh(input.data[i]);
    }
    
    if (this.training) {
      this.outputCache = output;
    }
    
    return output;
  }
  
  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const gradInput = {
      ...gradOutput,
      id: `grad_tanh_${input.id}`,
      data: new Float32Array(gradOutput.data.length)
    };
    
    // d/dx tanh(x) = 1 - tanh^2(x)
    for (let i = 0; i < gradOutput.data.length; i++) {
      const tanhVal = this.outputCache?.data[i] || Math.tanh(input.data[i]);
      gradInput.data[i] = gradOutput.data[i] * (1 - tanhVal * tanhVal);
    }
    
    return gradInput;
  }
  
  updateParameters(learningRate: number): void {
    // No parameters to update
  }
  
  zeroGradParameters(): void {
    // No gradients to zero
  }
  
  getParameters(): { weights: GgmlTensor[], gradients: GgmlTensor[] } {
    return { weights: [], gradients: [] };
  }
}

/**
 * Sigmoid activation (nn.Sigmoid)
 */
export class SigmoidModule implements NNModule {
  name: string = 'Sigmoid';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training: boolean = true;
  
  private outputCache?: GgmlTensor;
  
  forward(input: GgmlTensor): GgmlTensor {
    const output = {
      ...input,
      id: `sigmoid_${input.id}`,
      data: new Float32Array(input.data.length)
    };
    
    for (let i = 0; i < input.data.length; i++) {
      output.data[i] = 1.0 / (1.0 + Math.exp(-input.data[i]));
    }
    
    if (this.training) {
      this.outputCache = output;
    }
    
    return output;
  }
  
  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const gradInput = {
      ...gradOutput,
      id: `grad_sigmoid_${input.id}`,
      data: new Float32Array(gradOutput.data.length)
    };
    
    // d/dx sigmoid(x) = sigmoid(x) * (1 - sigmoid(x))
    for (let i = 0; i < gradOutput.data.length; i++) {
      const sigVal = this.outputCache?.data[i] || (1.0 / (1.0 + Math.exp(-input.data[i])));
      gradInput.data[i] = gradOutput.data[i] * sigVal * (1 - sigVal);
    }
    
    return gradInput;
  }
  
  updateParameters(learningRate: number): void {
    // No parameters to update
  }
  
  zeroGradParameters(): void {
    // No gradients to zero
  }
  
  getParameters(): { weights: GgmlTensor[], gradients: GgmlTensor[] } {
    return { weights: [], gradients: [] };
  }
}

/**
 * ReLU activation (nn.ReLU)
 */
export class ReLUModule implements NNModule {
  name: string = 'ReLU';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training: boolean = true;
  
  private inputCache?: GgmlTensor;
  
  forward(input: GgmlTensor): GgmlTensor {
    if (this.training) {
      this.inputCache = input;
    }
    
    const output = {
      ...input,
      id: `relu_${input.id}`,
      data: new Float32Array(input.data.length)
    };
    
    for (let i = 0; i < input.data.length; i++) {
      output.data[i] = Math.max(0, input.data[i]);
    }
    
    return output;
  }
  
  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    const gradInput = {
      ...gradOutput,
      id: `grad_relu_${input.id}`,
      data: new Float32Array(gradOutput.data.length)
    };
    
    // d/dx relu(x) = 1 if x > 0 else 0
    for (let i = 0; i < gradOutput.data.length; i++) {
      const inputVal = this.inputCache?.data[i] || input.data[i];
      gradInput.data[i] = inputVal > 0 ? gradOutput.data[i] : 0;
    }
    
    return gradInput;
  }
  
  updateParameters(learningRate: number): void {
    // No parameters to update
  }
  
  zeroGradParameters(): void {
    // No gradients to zero
  }
  
  getParameters(): { weights: GgmlTensor[], gradients: GgmlTensor[] } {
    return { weights: [], gradients: [] };
  }
}

/**
 * Sequential container (nn.Sequential)
 * Chains multiple modules together
 */
export class SequentialModule implements NNModule {
  name: string = 'Sequential';
  parameters: GgmlTensor[] = [];
  gradients: GgmlTensor[] = [];
  training: boolean = true;
  
  private modules: NNModule[];
  private intermediateOutputs: GgmlTensor[] = [];
  
  constructor(...modules: NNModule[]) {
    this.modules = modules;
    this.updateParameters(0); // Initialize parameter lists
  }
  
  forward(input: GgmlTensor): GgmlTensor {
    this.intermediateOutputs = [];
    let output = input;
    
    for (const module of this.modules) {
      module.training = this.training;
      output = module.forward(output);
      if (this.training) {
        this.intermediateOutputs.push(output);
      }
    }
    
    return output;
  }
  
  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    let gradInput = gradOutput;
    
    // Backpropagate through modules in reverse order
    for (let i = this.modules.length - 1; i >= 0; i--) {
      const module = this.modules[i];
      const moduleInput = i === 0 ? input : this.intermediateOutputs[i - 1];
      gradInput = module.backward(moduleInput, gradInput);
    }
    
    return gradInput;
  }
  
  updateParameters(learningRate: number): void {
    // Collect all parameters and gradients from submodules
    this.parameters = [];
    this.gradients = [];
    
    for (const module of this.modules) {
      module.updateParameters(learningRate);
      const { weights, gradients } = module.getParameters();
      this.parameters.push(...weights);
      this.gradients.push(...gradients);
    }
  }
  
  zeroGradParameters(): void {
    this.modules.forEach(m => m.zeroGradParameters());
  }
  
  getParameters(): { weights: GgmlTensor[], gradients: GgmlTensor[] } {
    return { weights: this.parameters, gradients: this.gradients };
  }
  
  add(module: NNModule): SequentialModule {
    this.modules.push(module);
    this.updateParameters(0);
    return this;
  }
}

/**
 * Mean Squared Error loss (nn.MSECriterion)
 */
export class MSECriterion {
  name: string = 'MSECriterion';
  
  forward(input: GgmlTensor, target: GgmlTensor): number {
    let sum = 0;
    for (let i = 0; i < input.data.length; i++) {
      const diff = input.data[i] - target.data[i];
      sum += diff * diff;
    }
    return sum / input.data.length;
  }
  
  backward(input: GgmlTensor, target: GgmlTensor): GgmlTensor {
    const gradInput = {
      ...input,
      id: `grad_mse_${input.id}`,
      data: new Float32Array(input.data.length)
    };
    
    const scale = 2.0 / input.data.length;
    for (let i = 0; i < input.data.length; i++) {
      gradInput.data[i] = scale * (input.data[i] - target.data[i]);
    }
    
    return gradInput;
  }
}

/**
 * Embedding layer for discrete tokens (nn.LookupTable)
 */
export class EmbeddingModule implements NNModule {
  name: string = 'Embedding';
  parameters: GgmlTensor[];
  gradients: GgmlTensor[];
  training: boolean = true;
  
  private weight: GgmlTensor;
  private inputCache?: number[];
  
  constructor(
    private numEmbeddings: number,
    private embeddingDim: number
  ) {
    // Initialize embeddings with small random values
    const stdv = 1.0 / Math.sqrt(embeddingDim);
    this.weight = this.createTensor(
      [numEmbeddings, embeddingDim],
      'embeddings',
      () => (Math.random() - 0.5) * 2 * stdv
    );
    
    this.parameters = [this.weight];
    this.gradients = [{
      ...this.weight,
      id: `grad_${this.weight.id}`,
      data: new Float32Array(this.weight.data.length)
    }];
  }
  
  forward(input: GgmlTensor): GgmlTensor {
    // Input should be integer indices
    const batchSize = input.shape[0];
    const indices = Array.from(input.data).map(x => Math.floor(x));
    
    if (this.training) {
      this.inputCache = indices;
    }
    
    const output = this.createTensor([batchSize, this.embeddingDim], 'embedded');
    
    for (let i = 0; i < batchSize; i++) {
      const idx = indices[i];
      if (idx >= 0 && idx < this.numEmbeddings) {
        for (let j = 0; j < this.embeddingDim; j++) {
          output.data[i * this.embeddingDim + j] = 
            this.weight.data[idx * this.embeddingDim + j];
        }
      }
    }
    
    return output;
  }
  
  backward(input: GgmlTensor, gradOutput: GgmlTensor): GgmlTensor {
    // Accumulate gradients for each embedding
    const weightGrad = this.gradients[0];
    const batchSize = gradOutput.shape[0];
    
    if (this.inputCache) {
      for (let i = 0; i < batchSize; i++) {
        const idx = this.inputCache[i];
        if (idx >= 0 && idx < this.numEmbeddings) {
          for (let j = 0; j < this.embeddingDim; j++) {
            weightGrad.data[idx * this.embeddingDim + j] += 
              gradOutput.data[i * this.embeddingDim + j];
          }
        }
      }
    }
    
    // Return zeros for gradInput (embeddings are discrete)
    return this.createTensor(input.shape, 'grad_input');
  }
  
  updateParameters(learningRate: number): void {
    const param = this.parameters[0];
    const grad = this.gradients[0];
    for (let i = 0; i < param.data.length; i++) {
      param.data[i] -= learningRate * grad.data[i];
    }
  }
  
  zeroGradParameters(): void {
    const grad = this.gradients[0];
    for (let i = 0; i < grad.data.length; i++) {
      grad.data[i] = 0;
    }
  }
  
  getParameters(): { weights: GgmlTensor[], gradients: GgmlTensor[] } {
    return { weights: this.parameters, gradients: this.gradients };
  }
  
  private createTensor(
    shape: number[],
    name: string,
    initializer?: () => number
  ): GgmlTensor {
    const size = shape.reduce((a, b) => a * b, 1);
    const data = new Float32Array(size);
    if (initializer) {
      for (let i = 0; i < size; i++) {
        data[i] = initializer();
      }
    }
    return {
      id: `${name}_${Math.random().toString(36).substr(2, 9)}`,
      shape,
      data,
      dtype: 'f32',
      requires_grad: true,
      name
    };
  }
}

/**
 * Training utilities
 */
export class Trainer {
  constructor(
    private model: NNModule,
    private criterion: MSECriterion,
    private learningRate: number = 0.01
  ) {}
  
  train(input: GgmlTensor, target: GgmlTensor): number {
    this.model.training = true;
    this.model.zeroGradParameters();
    
    // Forward pass
    const output = this.model.forward(input);
    const loss = this.criterion.forward(output, target);
    
    // Backward pass
    const gradOutput = this.criterion.backward(output, target);
    this.model.backward(input, gradOutput);
    
    // Update parameters
    this.model.updateParameters(this.learningRate);
    
    return loss;
  }
  
  evaluate(input: GgmlTensor, target: GgmlTensor): number {
    this.model.training = false;
    const output = this.model.forward(input);
    return this.criterion.forward(output, target);
  }
  
  setLearningRate(lr: number): void {
    this.learningRate = lr;
  }
}
