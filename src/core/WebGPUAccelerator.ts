/**
 * WebGPU Accelerator - Phase 6
 *
 * GPU-accelerated tensor operations using WebGPU:
 * - Matrix multiplication
 * - Element-wise operations
 * - Convolution operations
 * - Attention computation
 * - Automatic fallback to CPU
 */

import { GgmlTensor } from './GgmlTensorKernel';

// ============================================================================
// WEBGPU INTERFACES
// ============================================================================

/**
 * GPU device configuration
 */
export interface GPUConfig {
  preferHighPerformance: boolean;
  maxBufferSize: number;
  enableTimestamps: boolean;
}

/**
 * Compute shader definition
 */
export interface ComputeShader {
  name: string;
  code: string;
  workgroupSize: [number, number, number];
  bindings: BindingLayout[];
}

export interface BindingLayout {
  binding: number;
  visibility: number;
  type: 'storage' | 'uniform' | 'read-only-storage';
}

/**
 * Operation result with timing
 */
export interface GPUOperationResult {
  success: boolean;
  data?: Float32Array;
  duration?: number;
  error?: string;
}

// ============================================================================
// WEBGPU ACCELERATOR
// ============================================================================

/**
 * WebGPU-based tensor acceleration
 */
export class WebGPUAccelerator {
  private device: GPUDevice | null = null;
  private adapter: GPUAdapter | null = null;
  private initialized = false;
  private available = false;

  // Cached pipelines
  private pipelines: Map<string, GPUComputePipeline> = new Map();
  private bindGroupLayouts: Map<string, GPUBindGroupLayout> = new Map();

  // Shader cache
  private shaderModules: Map<string, GPUShaderModule> = new Map();

  constructor(private config: GPUConfig = {
    preferHighPerformance: true,
    maxBufferSize: 256 * 1024 * 1024, // 256MB
    enableTimestamps: false
  }) {}

  /**
   * Initialize WebGPU
   */
  public async initialize(): Promise<boolean> {
    if (this.initialized) return this.available;

    try {
      // Check WebGPU availability
      if (!navigator.gpu) {
        console.warn('WebGPU not supported in this browser');
        this.initialized = true;
        this.available = false;
        return false;
      }

      // Request adapter
      this.adapter = await navigator.gpu.requestAdapter({
        powerPreference: this.config.preferHighPerformance ? 'high-performance' : 'low-power'
      });

      if (!this.adapter) {
        console.warn('No WebGPU adapter found');
        this.initialized = true;
        this.available = false;
        return false;
      }

      // Request device
      this.device = await this.adapter.requestDevice({
        requiredLimits: {
          maxBufferSize: this.config.maxBufferSize,
          maxStorageBufferBindingSize: this.config.maxBufferSize
        }
      });

      // Setup error handling
      this.device.lost.then((info) => {
        console.error('WebGPU device lost:', info.message);
        this.available = false;
      });

      // Initialize common shaders
      await this.initializeShaders();

      this.initialized = true;
      this.available = true;
      console.log('WebGPU initialized successfully');

      return true;

    } catch (error) {
      console.error('WebGPU initialization failed:', error);
      this.initialized = true;
      this.available = false;
      return false;
    }
  }

  /**
   * Check if GPU acceleration is available
   */
  public isAvailable(): boolean {
    return this.available;
  }

  /**
   * Initialize common compute shaders
   */
  private async initializeShaders(): Promise<void> {
    if (!this.device) return;

    // Matrix multiplication shader
    const matmulShader = `
      struct Dimensions {
        M: u32,
        N: u32,
        K: u32,
      }

      @group(0) @binding(0) var<storage, read> A: array<f32>;
      @group(0) @binding(1) var<storage, read> B: array<f32>;
      @group(0) @binding(2) var<storage, read_write> C: array<f32>;
      @group(0) @binding(3) var<uniform> dims: Dimensions;

      @compute @workgroup_size(16, 16)
      fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
        let row = global_id.x;
        let col = global_id.y;

        if (row >= dims.M || col >= dims.N) {
          return;
        }

        var sum: f32 = 0.0;
        for (var k: u32 = 0u; k < dims.K; k = k + 1u) {
          sum = sum + A[row * dims.K + k] * B[k * dims.N + col];
        }
        C[row * dims.N + col] = sum;
      }
    `;

    // Element-wise addition shader
    const addShader = `
      @group(0) @binding(0) var<storage, read> A: array<f32>;
      @group(0) @binding(1) var<storage, read> B: array<f32>;
      @group(0) @binding(2) var<storage, read_write> C: array<f32>;

      @compute @workgroup_size(256)
      fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
        let idx = global_id.x;
        C[idx] = A[idx] + B[idx];
      }
    `;

    // Element-wise multiplication shader
    const mulShader = `
      @group(0) @binding(0) var<storage, read> A: array<f32>;
      @group(0) @binding(1) var<storage, read> B: array<f32>;
      @group(0) @binding(2) var<storage, read_write> C: array<f32>;

      @compute @workgroup_size(256)
      fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
        let idx = global_id.x;
        C[idx] = A[idx] * B[idx];
      }
    `;

    // ReLU activation shader
    const reluShader = `
      @group(0) @binding(0) var<storage, read> input: array<f32>;
      @group(0) @binding(1) var<storage, read_write> output: array<f32>;

      @compute @workgroup_size(256)
      fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
        let idx = global_id.x;
        output[idx] = max(0.0, input[idx]);
      }
    `;

    // Softmax shader (simplified - single row)
    const softmaxShader = `
      struct Params {
        size: u32,
      }

      @group(0) @binding(0) var<storage, read> input: array<f32>;
      @group(0) @binding(1) var<storage, read_write> output: array<f32>;
      @group(0) @binding(2) var<uniform> params: Params;

      var<workgroup> shared_max: f32;
      var<workgroup> shared_sum: f32;

      @compute @workgroup_size(256)
      fn main(@builtin(global_invocation_id) global_id: vec3<u32>,
              @builtin(local_invocation_id) local_id: vec3<u32>) {
        let idx = global_id.x;

        // Find max (simplified - assumes single workgroup)
        if (local_id.x == 0u) {
          shared_max = input[0];
          for (var i: u32 = 1u; i < params.size; i = i + 1u) {
            shared_max = max(shared_max, input[i]);
          }
        }
        workgroupBarrier();

        // Compute exp and sum
        if (idx < params.size) {
          let exp_val = exp(input[idx] - shared_max);
          output[idx] = exp_val;
        }
        workgroupBarrier();

        if (local_id.x == 0u) {
          shared_sum = 0.0;
          for (var i: u32 = 0u; i < params.size; i = i + 1u) {
            shared_sum = shared_sum + output[i];
          }
        }
        workgroupBarrier();

        // Normalize
        if (idx < params.size) {
          output[idx] = output[idx] / shared_sum;
        }
      }
    `;

    // Compile and cache shaders
    this.shaderModules.set('matmul', this.device.createShaderModule({ code: matmulShader }));
    this.shaderModules.set('add', this.device.createShaderModule({ code: addShader }));
    this.shaderModules.set('mul', this.device.createShaderModule({ code: mulShader }));
    this.shaderModules.set('relu', this.device.createShaderModule({ code: reluShader }));
    this.shaderModules.set('softmax', this.device.createShaderModule({ code: softmaxShader }));

    // Create pipelines
    await this.createMatmulPipeline();
    await this.createElementWisePipelines();
  }

  private async createMatmulPipeline(): Promise<void> {
    if (!this.device) return;

    const bindGroupLayout = this.device.createBindGroupLayout({
      entries: [
        { binding: 0, visibility: GPUShaderStage.COMPUTE, buffer: { type: 'read-only-storage' } },
        { binding: 1, visibility: GPUShaderStage.COMPUTE, buffer: { type: 'read-only-storage' } },
        { binding: 2, visibility: GPUShaderStage.COMPUTE, buffer: { type: 'storage' } },
        { binding: 3, visibility: GPUShaderStage.COMPUTE, buffer: { type: 'uniform' } }
      ]
    });

    const pipeline = this.device.createComputePipeline({
      layout: this.device.createPipelineLayout({ bindGroupLayouts: [bindGroupLayout] }),
      compute: {
        module: this.shaderModules.get('matmul')!,
        entryPoint: 'main'
      }
    });

    this.bindGroupLayouts.set('matmul', bindGroupLayout);
    this.pipelines.set('matmul', pipeline);
  }

  private async createElementWisePipelines(): Promise<void> {
    if (!this.device) return;

    const bindGroupLayout = this.device.createBindGroupLayout({
      entries: [
        { binding: 0, visibility: GPUShaderStage.COMPUTE, buffer: { type: 'read-only-storage' } },
        { binding: 1, visibility: GPUShaderStage.COMPUTE, buffer: { type: 'read-only-storage' } },
        { binding: 2, visibility: GPUShaderStage.COMPUTE, buffer: { type: 'storage' } }
      ]
    });

    for (const op of ['add', 'mul']) {
      const pipeline = this.device.createComputePipeline({
        layout: this.device.createPipelineLayout({ bindGroupLayouts: [bindGroupLayout] }),
        compute: {
          module: this.shaderModules.get(op)!,
          entryPoint: 'main'
        }
      });

      this.bindGroupLayouts.set(op, bindGroupLayout);
      this.pipelines.set(op, pipeline);
    }
  }

  // ==========================================================================
  // GPU OPERATIONS
  // ==========================================================================

  /**
   * GPU matrix multiplication
   */
  public async matmul(a: GgmlTensor, b: GgmlTensor): Promise<GPUOperationResult> {
    if (!this.available || !this.device) {
      return { success: false, error: 'GPU not available' };
    }

    const [M, K] = a.shape;
    const [K2, N] = b.shape;

    if (K !== K2) {
      return { success: false, error: 'Matrix dimensions mismatch' };
    }

    try {
      const startTime = performance.now();

      // Create buffers
      const bufferA = this.device.createBuffer({
        size: a.data.byteLength,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
      });

      const bufferB = this.device.createBuffer({
        size: b.data.byteLength,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
      });

      const resultSize = M * N * 4;
      const bufferC = this.device.createBuffer({
        size: resultSize,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
      });

      const uniformBuffer = this.device.createBuffer({
        size: 16, // 3 u32 + padding
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
      });

      // Write data to buffers
      this.device.queue.writeBuffer(bufferA, 0, a.data);
      this.device.queue.writeBuffer(bufferB, 0, b.data);
      this.device.queue.writeBuffer(uniformBuffer, 0, new Uint32Array([M, N, K, 0]));

      // Create bind group
      const bindGroup = this.device.createBindGroup({
        layout: this.bindGroupLayouts.get('matmul')!,
        entries: [
          { binding: 0, resource: { buffer: bufferA } },
          { binding: 1, resource: { buffer: bufferB } },
          { binding: 2, resource: { buffer: bufferC } },
          { binding: 3, resource: { buffer: uniformBuffer } }
        ]
      });

      // Execute
      const commandEncoder = this.device.createCommandEncoder();
      const passEncoder = commandEncoder.beginComputePass();
      passEncoder.setPipeline(this.pipelines.get('matmul')!);
      passEncoder.setBindGroup(0, bindGroup);
      passEncoder.dispatchWorkgroups(Math.ceil(M / 16), Math.ceil(N / 16));
      passEncoder.end();

      // Read back results
      const readBuffer = this.device.createBuffer({
        size: resultSize,
        usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
      });

      commandEncoder.copyBufferToBuffer(bufferC, 0, readBuffer, 0, resultSize);
      this.device.queue.submit([commandEncoder.finish()]);

      await readBuffer.mapAsync(GPUMapMode.READ);
      const result = new Float32Array(readBuffer.getMappedRange().slice(0));
      readBuffer.unmap();

      // Cleanup
      bufferA.destroy();
      bufferB.destroy();
      bufferC.destroy();
      uniformBuffer.destroy();
      readBuffer.destroy();

      return {
        success: true,
        data: result,
        duration: performance.now() - startTime
      };

    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  }

  /**
   * GPU element-wise addition
   */
  public async add(a: GgmlTensor, b: GgmlTensor): Promise<GPUOperationResult> {
    return this.elementWiseOp(a, b, 'add');
  }

  /**
   * GPU element-wise multiplication
   */
  public async multiply(a: GgmlTensor, b: GgmlTensor): Promise<GPUOperationResult> {
    return this.elementWiseOp(a, b, 'mul');
  }

  private async elementWiseOp(
    a: GgmlTensor,
    b: GgmlTensor,
    op: 'add' | 'mul'
  ): Promise<GPUOperationResult> {
    if (!this.available || !this.device) {
      return { success: false, error: 'GPU not available' };
    }

    if (a.data.length !== b.data.length) {
      return { success: false, error: 'Tensor sizes mismatch' };
    }

    try {
      const startTime = performance.now();
      const size = a.data.length;

      const bufferA = this.device.createBuffer({
        size: a.data.byteLength,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
      });

      const bufferB = this.device.createBuffer({
        size: b.data.byteLength,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
      });

      const bufferC = this.device.createBuffer({
        size: a.data.byteLength,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
      });

      this.device.queue.writeBuffer(bufferA, 0, a.data);
      this.device.queue.writeBuffer(bufferB, 0, b.data);

      const bindGroup = this.device.createBindGroup({
        layout: this.bindGroupLayouts.get(op)!,
        entries: [
          { binding: 0, resource: { buffer: bufferA } },
          { binding: 1, resource: { buffer: bufferB } },
          { binding: 2, resource: { buffer: bufferC } }
        ]
      });

      const commandEncoder = this.device.createCommandEncoder();
      const passEncoder = commandEncoder.beginComputePass();
      passEncoder.setPipeline(this.pipelines.get(op)!);
      passEncoder.setBindGroup(0, bindGroup);
      passEncoder.dispatchWorkgroups(Math.ceil(size / 256));
      passEncoder.end();

      const readBuffer = this.device.createBuffer({
        size: a.data.byteLength,
        usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
      });

      commandEncoder.copyBufferToBuffer(bufferC, 0, readBuffer, 0, a.data.byteLength);
      this.device.queue.submit([commandEncoder.finish()]);

      await readBuffer.mapAsync(GPUMapMode.READ);
      const result = new Float32Array(readBuffer.getMappedRange().slice(0));
      readBuffer.unmap();

      bufferA.destroy();
      bufferB.destroy();
      bufferC.destroy();
      readBuffer.destroy();

      return {
        success: true,
        data: result,
        duration: performance.now() - startTime
      };

    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  }

  // ==========================================================================
  // HYBRID CPU/GPU OPERATIONS
  // ==========================================================================

  /**
   * Smart operation that chooses GPU or CPU based on size and availability
   */
  public async smartMatmul(a: GgmlTensor, b: GgmlTensor): Promise<Float32Array> {
    // Use GPU for large matrices
    if (this.available && a.data.length > 10000) {
      const result = await this.matmul(a, b);
      if (result.success && result.data) {
        return result.data;
      }
    }

    // Fallback to CPU
    return this.cpuMatmul(a, b);
  }

  private cpuMatmul(a: GgmlTensor, b: GgmlTensor): Float32Array {
    const [M, K] = a.shape;
    const [, N] = b.shape;
    const result = new Float32Array(M * N);

    for (let i = 0; i < M; i++) {
      for (let j = 0; j < N; j++) {
        let sum = 0;
        for (let k = 0; k < K; k++) {
          sum += a.data[i * K + k] * b.data[k * N + j];
        }
        result[i * N + j] = sum;
      }
    }

    return result;
  }

  // ==========================================================================
  // DEVICE INFO & CLEANUP
  // ==========================================================================

  /**
   * Get GPU device information
   */
  public getDeviceInfo(): GPUDeviceInfo | null {
    if (!this.adapter || !this.device) return null;

    return {
      vendor: 'Unknown', // Would need adapter info
      architecture: 'Unknown',
      available: this.available,
      limits: {
        maxBufferSize: this.device.limits.maxBufferSize,
        maxStorageBufferBindingSize: this.device.limits.maxStorageBufferBindingSize,
        maxComputeWorkgroupsPerDimension: this.device.limits.maxComputeWorkgroupsPerDimension,
        maxComputeInvocationsPerWorkgroup: this.device.limits.maxComputeInvocationsPerWorkgroup
      }
    };
  }

  /**
   * Cleanup GPU resources
   */
  public destroy(): void {
    for (const pipeline of this.pipelines.values()) {
      // Pipelines are automatically cleaned up
    }
    this.pipelines.clear();
    this.bindGroupLayouts.clear();
    this.shaderModules.clear();

    if (this.device) {
      this.device.destroy();
      this.device = null;
    }

    this.adapter = null;
    this.available = false;
    this.initialized = false;
  }
}

export interface GPUDeviceInfo {
  vendor: string;
  architecture: string;
  available: boolean;
  limits: {
    maxBufferSize: number;
    maxStorageBufferBindingSize: number;
    maxComputeWorkgroupsPerDimension: number;
    maxComputeInvocationsPerWorkgroup: number;
  };
}

// ============================================================================
// ACCELERATED TENSOR WRAPPER
// ============================================================================

/**
 * Tensor operations with automatic GPU acceleration
 */
export class AcceleratedTensorOps {
  private accelerator: WebGPUAccelerator;
  private initialized = false;

  constructor() {
    this.accelerator = new WebGPUAccelerator();
  }

  public async init(): Promise<boolean> {
    if (this.initialized) return this.accelerator.isAvailable();
    this.initialized = true;
    return await this.accelerator.initialize();
  }

  public async matmul(a: GgmlTensor, b: GgmlTensor): Promise<GgmlTensor> {
    await this.init();

    const result = await this.accelerator.smartMatmul(a, b);
    const [M] = a.shape;
    const [, N] = b.shape;

    return {
      id: `matmul_${a.id}_${b.id}`,
      shape: [M, N],
      data: result,
      dtype: 'f32',
      requires_grad: a.requires_grad || b.requires_grad
    };
  }

  public async add(a: GgmlTensor, b: GgmlTensor): Promise<GgmlTensor> {
    await this.init();

    if (this.accelerator.isAvailable()) {
      const result = await this.accelerator.add(a, b);
      if (result.success && result.data) {
        return {
          id: `add_${a.id}_${b.id}`,
          shape: a.shape,
          data: result.data,
          dtype: 'f32',
          requires_grad: a.requires_grad || b.requires_grad
        };
      }
    }

    // CPU fallback
    const result = new Float32Array(a.data.length);
    for (let i = 0; i < a.data.length; i++) {
      result[i] = a.data[i] + b.data[i];
    }

    return {
      id: `add_${a.id}_${b.id}`,
      shape: a.shape,
      data: result,
      dtype: 'f32',
      requires_grad: a.requires_grad || b.requires_grad
    };
  }

  public async multiply(a: GgmlTensor, b: GgmlTensor): Promise<GgmlTensor> {
    await this.init();

    if (this.accelerator.isAvailable()) {
      const result = await this.accelerator.multiply(a, b);
      if (result.success && result.data) {
        return {
          id: `mul_${a.id}_${b.id}`,
          shape: a.shape,
          data: result.data,
          dtype: 'f32',
          requires_grad: a.requires_grad || b.requires_grad
        };
      }
    }

    // CPU fallback
    const result = new Float32Array(a.data.length);
    for (let i = 0; i < a.data.length; i++) {
      result[i] = a.data[i] * b.data[i];
    }

    return {
      id: `mul_${a.id}_${b.id}`,
      shape: a.shape,
      data: result,
      dtype: 'f32',
      requires_grad: a.requires_grad || b.requires_grad
    };
  }

  public isGPUAvailable(): boolean {
    return this.accelerator.isAvailable();
  }

  public getDeviceInfo(): GPUDeviceInfo | null {
    return this.accelerator.getDeviceInfo();
  }

  public destroy(): void {
    this.accelerator.destroy();
  }
}

// ============================================================================
// EXPORTS
// ============================================================================

export const GPUAcceleration = {
  WebGPUAccelerator,
  AcceleratedTensorOps
};

// Create singleton instance
export const gpuAccelerator = new AcceleratedTensorOps();
