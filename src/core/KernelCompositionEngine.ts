/**
 * Kernel Composition Engine - Phase 6
 *
 * Advanced system for composing, chaining, and optimizing kernels across domains:
 * - Sequential kernel composition (pipeline)
 * - Parallel kernel composition (ensemble)
 * - Multi-domain optimization
 * - Cross-domain transfer
 * - Adaptive kernel selection
 */

import {
  UniversalKernelGenerator,
  GeneratedKernel,
  DomainSpecification,
  GripMetrics,
  BSeriesCoefficients,
  RootedTree,
  ContextTensor
} from './UniversalKernelGenerator';

// ============================================================================
// COMPOSITION INTERFACES
// ============================================================================

/**
 * Kernel composition strategy
 */
export enum CompositionStrategy {
  SEQUENTIAL = 'sequential',     // Chain kernels in sequence
  PARALLEL = 'parallel',         // Run kernels in parallel and combine
  HIERARCHICAL = 'hierarchical', // Nested kernel composition
  ADAPTIVE = 'adaptive',         // Dynamically select composition
  RESIDUAL = 'residual'          // Residual connections between kernels
}

/**
 * Combination method for parallel composition
 */
export enum CombinationMethod {
  AVERAGE = 'average',
  WEIGHTED_AVERAGE = 'weighted_average',
  MAX = 'max',
  MIN = 'min',
  PRODUCT = 'product',
  ATTENTION = 'attention'
}

/**
 * Composed kernel result
 */
export interface ComposedKernel {
  id: string;
  name: string;
  strategy: CompositionStrategy;
  components: GeneratedKernel[];
  composition_weights: number[];
  combined_coefficients: number[];
  combined_grip: GripMetrics;
  domains_covered: string[];
  computation_graph: ComputationNode[];
  metadata: CompositionMetadata;
}

/**
 * Computation node in kernel graph
 */
export interface ComputationNode {
  id: string;
  kernel_id: string;
  domain: string;
  inputs: string[];
  outputs: string[];
  operation: 'apply' | 'combine' | 'transform' | 'residual';
  position: { x: number; y: number };
}

/**
 * Composition metadata
 */
export interface CompositionMetadata {
  creation_time: number;
  optimization_iterations: number;
  total_parameters: number;
  estimated_flops: number;
  memory_footprint: number;
}

/**
 * Multi-domain problem specification
 */
export interface MultiDomainProblem {
  id: string;
  name: string;
  description: string;
  domains: DomainSpecification[];
  domain_weights: number[];
  constraints: DomainConstraint[];
  objective: OptimizationObjective;
}

/**
 * Domain constraint
 */
export interface DomainConstraint {
  type: 'order' | 'coupling' | 'exclusion' | 'dependency';
  domains: string[];
  parameters: Record<string, unknown>;
}

/**
 * Optimization objective
 */
export interface OptimizationObjective {
  target: 'grip' | 'efficiency' | 'accuracy' | 'balance';
  weights: {
    grip: number;
    efficiency: number;
    coverage: number;
    stability: number;
  };
}

/**
 * Kernel transfer configuration
 */
export interface TransferConfig {
  source_domain: string;
  target_domain: string;
  transfer_method: 'direct' | 'fine_tune' | 'distill' | 'adapt';
  adaptation_rate: number;
  freeze_layers: number;
}

// ============================================================================
// KERNEL COMPOSITION ENGINE
// ============================================================================

/**
 * Main Kernel Composition Engine class
 */
export class KernelCompositionEngine {
  private kernelGenerator: UniversalKernelGenerator;
  private kernelCache: Map<string, GeneratedKernel> = new Map();
  private compositionCache: Map<string, ComposedKernel> = new Map();

  constructor() {
    this.kernelGenerator = new UniversalKernelGenerator();
  }

  // ==========================================================================
  // SEQUENTIAL COMPOSITION
  // ==========================================================================

  /**
   * Compose kernels sequentially (pipeline)
   * Output of one kernel feeds into the next
   */
  public composeSequential(
    kernels: GeneratedKernel[],
    name?: string
  ): ComposedKernel {
    if (kernels.length === 0) {
      throw new Error('Cannot compose empty kernel list');
    }

    const compositionId = `seq_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Build computation graph
    const graph: ComputationNode[] = [];
    let prevOutput = 'input';

    for (let i = 0; i < kernels.length; i++) {
      const kernel = kernels[i];
      const nodeId = `node_${i}`;
      const outputId = i === kernels.length - 1 ? 'output' : `intermediate_${i}`;

      graph.push({
        id: nodeId,
        kernel_id: kernel.domain.name,
        domain: kernel.domain.type,
        inputs: [prevOutput],
        outputs: [outputId],
        operation: 'apply',
        position: { x: i * 150, y: 0 }
      });

      prevOutput = outputId;
    }

    // Compose coefficients through chain rule
    const composedCoeffs = this.chainCoefficients(kernels);

    // Compute combined grip
    const combinedGrip = this.computeSequentialGrip(kernels);

    return {
      id: compositionId,
      name: name || `Sequential(${kernels.map(k => k.domain.name).join(' → ')})`,
      strategy: CompositionStrategy.SEQUENTIAL,
      components: kernels,
      composition_weights: kernels.map(() => 1),
      combined_coefficients: composedCoeffs,
      combined_grip: combinedGrip,
      domains_covered: kernels.map(k => k.domain.name),
      computation_graph: graph,
      metadata: this.computeMetadata(kernels, 'sequential')
    };
  }

  /**
   * Chain coefficients using composition rules
   */
  private chainCoefficients(kernels: GeneratedKernel[]): number[] {
    if (kernels.length === 1) {
      return kernels[0].coefficients;
    }

    // Start with first kernel's coefficients
    let result = [...kernels[0].coefficients];

    // Apply chain rule for each subsequent kernel
    for (let i = 1; i < kernels.length; i++) {
      const nextCoeffs = kernels[i].coefficients;
      const newResult: number[] = [];

      // Convolve coefficients (simplified chain rule)
      for (let j = 0; j < Math.max(result.length, nextCoeffs.length); j++) {
        let sum = 0;
        for (let k = 0; k <= j; k++) {
          const a = k < result.length ? result[k] : 0;
          const b = (j - k) < nextCoeffs.length ? nextCoeffs[j - k] : 0;
          sum += a * b;
        }
        newResult.push(sum);
      }

      result = newResult;
    }

    return result;
  }

  /**
   * Compute grip for sequential composition
   */
  private computeSequentialGrip(kernels: GeneratedKernel[]): GripMetrics {
    // Sequential grip is the product of individual grips (bottleneck principle)
    let contact = 1;
    let coverage = 0;
    let efficiency = 1;
    let stability = 1;

    for (const kernel of kernels) {
      contact *= kernel.grip.contact;
      coverage = Math.max(coverage, kernel.grip.coverage); // Union of coverage
      efficiency *= kernel.grip.efficiency;
      stability = Math.min(stability, kernel.grip.stability); // Weakest link
    }

    // Normalize efficiency
    efficiency = Math.pow(efficiency, 1 / kernels.length);

    const overall = (contact * 0.3 + coverage * 0.3 + efficiency * 0.2 + stability * 0.2);

    return { contact, coverage, efficiency, stability, overall };
  }

  // ==========================================================================
  // PARALLEL COMPOSITION
  // ==========================================================================

  /**
   * Compose kernels in parallel (ensemble)
   * All kernels process input simultaneously, results combined
   */
  public composeParallel(
    kernels: GeneratedKernel[],
    weights?: number[],
    method: CombinationMethod = CombinationMethod.WEIGHTED_AVERAGE,
    name?: string
  ): ComposedKernel {
    if (kernels.length === 0) {
      throw new Error('Cannot compose empty kernel list');
    }

    const compositionId = `par_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Default to equal weights
    const compositionWeights = weights || kernels.map(() => 1 / kernels.length);

    // Normalize weights
    const weightSum = compositionWeights.reduce((a, b) => a + b, 0);
    const normalizedWeights = compositionWeights.map(w => w / weightSum);

    // Build computation graph
    const graph: ComputationNode[] = [];

    // Input distribution nodes
    for (let i = 0; i < kernels.length; i++) {
      graph.push({
        id: `parallel_${i}`,
        kernel_id: kernels[i].domain.name,
        domain: kernels[i].domain.type,
        inputs: ['input'],
        outputs: [`branch_${i}`],
        operation: 'apply',
        position: { x: 100, y: i * 80 }
      });
    }

    // Combination node
    graph.push({
      id: 'combine',
      kernel_id: 'combiner',
      domain: 'composition',
      inputs: kernels.map((_, i) => `branch_${i}`),
      outputs: ['output'],
      operation: 'combine',
      position: { x: 250, y: (kernels.length - 1) * 40 }
    });

    // Combine coefficients
    const composedCoeffs = this.combineCoefficients(kernels, normalizedWeights, method);

    // Compute combined grip
    const combinedGrip = this.computeParallelGrip(kernels, normalizedWeights);

    return {
      id: compositionId,
      name: name || `Parallel(${kernels.map(k => k.domain.name).join(' + ')})`,
      strategy: CompositionStrategy.PARALLEL,
      components: kernels,
      composition_weights: normalizedWeights,
      combined_coefficients: composedCoeffs,
      combined_grip: combinedGrip,
      domains_covered: kernels.map(k => k.domain.name),
      computation_graph: graph,
      metadata: this.computeMetadata(kernels, 'parallel')
    };
  }

  /**
   * Combine coefficients based on method
   */
  private combineCoefficients(
    kernels: GeneratedKernel[],
    weights: number[],
    method: CombinationMethod
  ): number[] {
    const maxLen = Math.max(...kernels.map(k => k.coefficients.length));
    const result: number[] = new Array(maxLen).fill(0);

    switch (method) {
      case CombinationMethod.WEIGHTED_AVERAGE:
        for (let i = 0; i < maxLen; i++) {
          for (let j = 0; j < kernels.length; j++) {
            const coeff = i < kernels[j].coefficients.length ? kernels[j].coefficients[i] : 0;
            result[i] += weights[j] * coeff;
          }
        }
        break;

      case CombinationMethod.AVERAGE:
        for (let i = 0; i < maxLen; i++) {
          let sum = 0;
          let count = 0;
          for (const kernel of kernels) {
            if (i < kernel.coefficients.length) {
              sum += kernel.coefficients[i];
              count++;
            }
          }
          result[i] = count > 0 ? sum / count : 0;
        }
        break;

      case CombinationMethod.MAX:
        for (let i = 0; i < maxLen; i++) {
          result[i] = Math.max(...kernels.map(k =>
            i < k.coefficients.length ? k.coefficients[i] : -Infinity
          ));
        }
        break;

      case CombinationMethod.MIN:
        for (let i = 0; i < maxLen; i++) {
          result[i] = Math.min(...kernels.map(k =>
            i < k.coefficients.length ? k.coefficients[i] : Infinity
          ));
        }
        break;

      case CombinationMethod.PRODUCT:
        result.fill(1);
        for (let i = 0; i < maxLen; i++) {
          for (const kernel of kernels) {
            if (i < kernel.coefficients.length) {
              result[i] *= kernel.coefficients[i];
            }
          }
        }
        break;

      case CombinationMethod.ATTENTION:
        // Attention-based combination using grip quality as attention scores
        const attentionScores = kernels.map(k => k.grip.overall);
        const attentionSum = attentionScores.reduce((a, b) => a + b, 0);
        const attentionWeights = attentionScores.map(s => s / attentionSum);

        for (let i = 0; i < maxLen; i++) {
          for (let j = 0; j < kernels.length; j++) {
            const coeff = i < kernels[j].coefficients.length ? kernels[j].coefficients[i] : 0;
            result[i] += attentionWeights[j] * coeff;
          }
        }
        break;
    }

    return result;
  }

  /**
   * Compute grip for parallel composition
   */
  private computeParallelGrip(kernels: GeneratedKernel[], weights: number[]): GripMetrics {
    let contact = 0;
    let coverage = 0;
    let efficiency = 0;
    let stability = 0;

    for (let i = 0; i < kernels.length; i++) {
      contact += weights[i] * kernels[i].grip.contact;
      coverage += weights[i] * kernels[i].grip.coverage;
      efficiency += weights[i] * kernels[i].grip.efficiency;
      stability += weights[i] * kernels[i].grip.stability;
    }

    // Parallel composition can improve coverage (union of domains)
    coverage = Math.min(1, coverage * 1.2);

    const overall = (contact * 0.3 + coverage * 0.3 + efficiency * 0.2 + stability * 0.2);

    return { contact, coverage, efficiency, stability, overall };
  }

  // ==========================================================================
  // HIERARCHICAL COMPOSITION
  // ==========================================================================

  /**
   * Compose kernels hierarchically (nested structure)
   */
  public composeHierarchical(
    structure: HierarchicalStructure,
    name?: string
  ): ComposedKernel {
    const compositionId = `hier_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Recursively build the composition
    const { kernels, coefficients, grip, graph } = this.buildHierarchy(structure, 0, 0);

    return {
      id: compositionId,
      name: name || `Hierarchical(${kernels.length} kernels)`,
      strategy: CompositionStrategy.HIERARCHICAL,
      components: kernels,
      composition_weights: kernels.map(() => 1 / kernels.length),
      combined_coefficients: coefficients,
      combined_grip: grip,
      domains_covered: [...new Set(kernels.map(k => k.domain.name))],
      computation_graph: graph,
      metadata: this.computeMetadata(kernels, 'hierarchical')
    };
  }

  private buildHierarchy(
    node: HierarchicalStructure,
    depth: number,
    yOffset: number
  ): {
    kernels: GeneratedKernel[];
    coefficients: number[];
    grip: GripMetrics;
    graph: ComputationNode[];
  } {
    if ('kernel' in node) {
      // Leaf node
      return {
        kernels: [node.kernel],
        coefficients: node.kernel.coefficients,
        grip: node.kernel.grip,
        graph: [{
          id: `leaf_${node.kernel.domain.name}`,
          kernel_id: node.kernel.domain.name,
          domain: node.kernel.domain.type,
          inputs: ['input'],
          outputs: ['output'],
          operation: 'apply',
          position: { x: depth * 150, y: yOffset }
        }]
      };
    }

    // Internal node - recursively process children
    const childResults = node.children.map((child, i) =>
      this.buildHierarchy(child, depth + 1, yOffset + i * 100)
    );

    const allKernels = childResults.flatMap(r => r.kernels);
    const allGraphs = childResults.flatMap(r => r.graph);

    // Combine based on node's combination method
    const composed = node.strategy === 'sequential'
      ? this.composeSequential(childResults.map(r => ({
          ...allKernels[0],
          coefficients: r.coefficients,
          grip: r.grip
        } as GeneratedKernel)))
      : this.composeParallel(childResults.map(r => ({
          ...allKernels[0],
          coefficients: r.coefficients,
          grip: r.grip
        } as GeneratedKernel)));

    return {
      kernels: allKernels,
      coefficients: composed.combined_coefficients,
      grip: composed.combined_grip,
      graph: allGraphs
    };
  }

  // ==========================================================================
  // RESIDUAL COMPOSITION
  // ==========================================================================

  /**
   * Compose with residual connections
   */
  public composeResidual(
    mainKernel: GeneratedKernel,
    residualKernels: GeneratedKernel[],
    residualWeight: number = 0.1,
    name?: string
  ): ComposedKernel {
    const compositionId = `res_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    const allKernels = [mainKernel, ...residualKernels];

    // Build computation graph with residual connections
    const graph: ComputationNode[] = [
      {
        id: 'main',
        kernel_id: mainKernel.domain.name,
        domain: mainKernel.domain.type,
        inputs: ['input'],
        outputs: ['main_out'],
        operation: 'apply',
        position: { x: 100, y: 50 }
      }
    ];

    // Add residual branches
    for (let i = 0; i < residualKernels.length; i++) {
      graph.push({
        id: `residual_${i}`,
        kernel_id: residualKernels[i].domain.name,
        domain: residualKernels[i].domain.type,
        inputs: ['input'],
        outputs: [`residual_out_${i}`],
        operation: 'apply',
        position: { x: 100, y: 150 + i * 80 }
      });
    }

    // Residual addition node
    graph.push({
      id: 'residual_add',
      kernel_id: 'residual_combiner',
      domain: 'composition',
      inputs: ['main_out', ...residualKernels.map((_, i) => `residual_out_${i}`)],
      outputs: ['output'],
      operation: 'residual',
      position: { x: 250, y: 100 }
    });

    // Combine coefficients with residual weighting
    const mainWeight = 1 - residualWeight * residualKernels.length;
    const weights = [mainWeight, ...residualKernels.map(() => residualWeight)];
    const composedCoeffs = this.combineCoefficients(allKernels, weights, CombinationMethod.WEIGHTED_AVERAGE);

    // Compute combined grip with residual boost
    const combinedGrip = this.computeResidualGrip(mainKernel, residualKernels, residualWeight);

    return {
      id: compositionId,
      name: name || `Residual(${mainKernel.domain.name} + ${residualKernels.length} residuals)`,
      strategy: CompositionStrategy.RESIDUAL,
      components: allKernels,
      composition_weights: weights,
      combined_coefficients: composedCoeffs,
      combined_grip: combinedGrip,
      domains_covered: [...new Set(allKernels.map(k => k.domain.name))],
      computation_graph: graph,
      metadata: this.computeMetadata(allKernels, 'residual')
    };
  }

  private computeResidualGrip(
    mainKernel: GeneratedKernel,
    residualKernels: GeneratedKernel[],
    residualWeight: number
  ): GripMetrics {
    const mainWeight = 1 - residualWeight * residualKernels.length;

    let contact = mainWeight * mainKernel.grip.contact;
    let coverage = mainWeight * mainKernel.grip.coverage;
    let efficiency = mainWeight * mainKernel.grip.efficiency;
    let stability = mainWeight * mainKernel.grip.stability;

    for (const rk of residualKernels) {
      contact += residualWeight * rk.grip.contact;
      coverage += residualWeight * rk.grip.coverage;
      efficiency += residualWeight * rk.grip.efficiency;
      stability += residualWeight * rk.grip.stability;
    }

    // Residual connections improve stability
    stability = Math.min(1, stability * 1.1);

    const overall = (contact * 0.3 + coverage * 0.3 + efficiency * 0.2 + stability * 0.2);

    return { contact, coverage, efficiency, stability, overall };
  }

  // ==========================================================================
  // MULTI-DOMAIN OPTIMIZATION
  // ==========================================================================

  /**
   * Solve multi-domain problem with optimal kernel composition
   */
  public solveMultiDomain(problem: MultiDomainProblem): ComposedKernel {
    // Generate kernels for each domain
    const domainKernels = problem.domains.map(domain =>
      this.kernelGenerator.generateKernel(domain)
    );

    // Analyze domain relationships
    const relationships = this.analyzeDomainRelationships(problem);

    // Determine optimal composition strategy
    const strategy = this.selectCompositionStrategy(problem, relationships);

    // Build composition based on strategy and constraints
    let composed: ComposedKernel;

    switch (strategy) {
      case CompositionStrategy.SEQUENTIAL:
        // Order kernels based on dependencies
        const orderedKernels = this.orderByDependencies(domainKernels, problem.constraints);
        composed = this.composeSequential(orderedKernels, problem.name);
        break;

      case CompositionStrategy.PARALLEL:
        composed = this.composeParallel(
          domainKernels,
          problem.domain_weights,
          CombinationMethod.ATTENTION,
          problem.name
        );
        break;

      case CompositionStrategy.HIERARCHICAL:
        const hierarchy = this.buildOptimalHierarchy(domainKernels, problem);
        composed = this.composeHierarchical(hierarchy, problem.name);
        break;

      case CompositionStrategy.ADAPTIVE:
        composed = this.composeAdaptive(domainKernels, problem);
        break;

      default:
        composed = this.composeParallel(domainKernels, problem.domain_weights);
    }

    // Optimize the composition
    return this.optimizeComposition(composed, problem.objective);
  }

  /**
   * Analyze relationships between domains
   */
  private analyzeDomainRelationships(problem: MultiDomainProblem): DomainRelationship[] {
    const relationships: DomainRelationship[] = [];

    for (let i = 0; i < problem.domains.length; i++) {
      for (let j = i + 1; j < problem.domains.length; j++) {
        const d1 = problem.domains[i];
        const d2 = problem.domains[j];

        // Compute domain similarity based on topology
        const topologySimilarity = this.computeTopologySimilarity(d1.topology, d2.topology);

        // Check for coupling constraints
        const coupling = problem.constraints.find(
          c => c.type === 'coupling' && c.domains.includes(d1.name) && c.domains.includes(d2.name)
        );

        relationships.push({
          domain1: d1.name,
          domain2: d2.name,
          similarity: topologySimilarity,
          coupling_strength: coupling ? (coupling.parameters.strength as number) || 0.5 : 0,
          relationship_type: topologySimilarity > 0.7 ? 'similar' : topologySimilarity > 0.3 ? 'related' : 'distinct'
        });
      }
    }

    return relationships;
  }

  private computeTopologySimilarity(t1: DomainSpecification['topology'], t2: DomainSpecification['topology']): number {
    const dimSim = 1 - Math.abs(t1.manifold_dimension - t2.manifold_dimension) / Math.max(t1.manifold_dimension, t2.manifold_dimension);
    const genusSim = t1.genus === t2.genus ? 1 : 0.5;
    const charSim = 1 - Math.abs(t1.characteristic - t2.characteristic) / (Math.abs(t1.characteristic) + Math.abs(t2.characteristic) + 1);

    return (dimSim + genusSim + charSim) / 3;
  }

  /**
   * Select optimal composition strategy
   */
  private selectCompositionStrategy(
    problem: MultiDomainProblem,
    relationships: DomainRelationship[]
  ): CompositionStrategy {
    // Check for explicit ordering constraints
    const hasOrderConstraints = problem.constraints.some(c => c.type === 'order' || c.type === 'dependency');
    if (hasOrderConstraints) {
      return CompositionStrategy.SEQUENTIAL;
    }

    // Check for strong coupling
    const avgCoupling = relationships.reduce((sum, r) => sum + r.coupling_strength, 0) / relationships.length;
    if (avgCoupling > 0.7) {
      return CompositionStrategy.HIERARCHICAL;
    }

    // Check for domain similarity
    const avgSimilarity = relationships.reduce((sum, r) => sum + r.similarity, 0) / relationships.length;
    if (avgSimilarity > 0.6) {
      return CompositionStrategy.PARALLEL;
    }

    // Default to adaptive for complex cases
    return CompositionStrategy.ADAPTIVE;
  }

  /**
   * Order kernels based on dependency constraints
   */
  private orderByDependencies(
    kernels: GeneratedKernel[],
    constraints: DomainConstraint[]
  ): GeneratedKernel[] {
    const orderConstraints = constraints.filter(c => c.type === 'order' || c.type === 'dependency');

    if (orderConstraints.length === 0) {
      return kernels;
    }

    // Build dependency graph
    const graph = new Map<string, Set<string>>();
    for (const kernel of kernels) {
      graph.set(kernel.domain.name, new Set());
    }

    for (const constraint of orderConstraints) {
      if (constraint.domains.length >= 2) {
        for (let i = 1; i < constraint.domains.length; i++) {
          graph.get(constraint.domains[i])?.add(constraint.domains[i - 1]);
        }
      }
    }

    // Topological sort
    const result: GeneratedKernel[] = [];
    const visited = new Set<string>();
    const temp = new Set<string>();

    const visit = (name: string) => {
      if (temp.has(name)) throw new Error('Cyclic dependency detected');
      if (visited.has(name)) return;

      temp.add(name);
      for (const dep of graph.get(name) || []) {
        visit(dep);
      }
      temp.delete(name);
      visited.add(name);

      const kernel = kernels.find(k => k.domain.name === name);
      if (kernel) result.push(kernel);
    };

    for (const kernel of kernels) {
      if (!visited.has(kernel.domain.name)) {
        visit(kernel.domain.name);
      }
    }

    return result;
  }

  /**
   * Build optimal hierarchy from kernels
   */
  private buildOptimalHierarchy(
    kernels: GeneratedKernel[],
    problem: MultiDomainProblem
  ): HierarchicalStructure {
    // Simple binary tree hierarchy based on domain similarity
    if (kernels.length <= 2) {
      if (kernels.length === 1) {
        return { kernel: kernels[0] };
      }
      return {
        strategy: 'parallel',
        children: kernels.map(k => ({ kernel: k }))
      };
    }

    // Split into two groups
    const mid = Math.floor(kernels.length / 2);
    const left = kernels.slice(0, mid);
    const right = kernels.slice(mid);

    return {
      strategy: 'sequential',
      children: [
        this.buildOptimalHierarchy(left, problem),
        this.buildOptimalHierarchy(right, problem)
      ]
    };
  }

  /**
   * Adaptive composition based on runtime analysis
   */
  private composeAdaptive(
    kernels: GeneratedKernel[],
    problem: MultiDomainProblem
  ): ComposedKernel {
    // Try different compositions and select best
    const candidates: ComposedKernel[] = [
      this.composeSequential(kernels, `${problem.name}_seq`),
      this.composeParallel(kernels, problem.domain_weights, CombinationMethod.ATTENTION, `${problem.name}_par`),
    ];

    // Add residual if we have enough kernels
    if (kernels.length >= 2) {
      candidates.push(
        this.composeResidual(kernels[0], kernels.slice(1), 0.2, `${problem.name}_res`)
      );
    }

    // Select based on objective
    return candidates.reduce((best, current) => {
      const bestScore = this.computeObjectiveScore(best, problem.objective);
      const currentScore = this.computeObjectiveScore(current, problem.objective);
      return currentScore > bestScore ? current : best;
    });
  }

  /**
   * Compute objective score for composition
   */
  private computeObjectiveScore(
    composition: ComposedKernel,
    objective: OptimizationObjective
  ): number {
    const w = objective.weights;
    const g = composition.combined_grip;

    return w.grip * g.overall +
           w.efficiency * g.efficiency +
           w.coverage * g.coverage +
           w.stability * g.stability;
  }

  /**
   * Optimize composed kernel
   */
  private optimizeComposition(
    composition: ComposedKernel,
    objective: OptimizationObjective,
    maxIterations: number = 100
  ): ComposedKernel {
    let bestComposition = composition;
    let bestScore = this.computeObjectiveScore(composition, objective);

    for (let iter = 0; iter < maxIterations; iter++) {
      // Perturb weights
      const newWeights = composition.composition_weights.map(w =>
        Math.max(0, w + (Math.random() - 0.5) * 0.1)
      );

      // Normalize
      const sum = newWeights.reduce((a, b) => a + b, 0);
      const normalizedWeights = newWeights.map(w => w / sum);

      // Recompute coefficients
      const newCoeffs = this.combineCoefficients(
        composition.components,
        normalizedWeights,
        CombinationMethod.WEIGHTED_AVERAGE
      );

      // Create candidate
      const candidate: ComposedKernel = {
        ...composition,
        composition_weights: normalizedWeights,
        combined_coefficients: newCoeffs,
        combined_grip: this.computeParallelGrip(composition.components, normalizedWeights)
      };

      const candidateScore = this.computeObjectiveScore(candidate, objective);

      if (candidateScore > bestScore) {
        bestComposition = candidate;
        bestScore = candidateScore;
      }
    }

    bestComposition.metadata.optimization_iterations = maxIterations;
    return bestComposition;
  }

  // ==========================================================================
  // KERNEL TRANSFER
  // ==========================================================================

  /**
   * Transfer kernel knowledge between domains
   */
  public transferKernel(
    sourceKernel: GeneratedKernel,
    targetDomain: DomainSpecification,
    config: TransferConfig
  ): GeneratedKernel {
    // Generate base kernel for target domain
    const targetKernel = this.kernelGenerator.generateKernel(targetDomain);

    switch (config.transfer_method) {
      case 'direct':
        // Direct transfer - use source coefficients with target structure
        return {
          ...targetKernel,
          coefficients: sourceKernel.coefficients.slice(0, targetKernel.coefficients.length)
        };

      case 'fine_tune':
        // Fine-tune source coefficients for target domain
        return this.fineTuneKernel(sourceKernel, targetKernel, config.adaptation_rate);

      case 'distill':
        // Knowledge distillation
        return this.distillKernel(sourceKernel, targetKernel);

      case 'adapt':
        // Domain adaptation
        return this.adaptKernel(sourceKernel, targetKernel, config);

      default:
        return targetKernel;
    }
  }

  private fineTuneKernel(
    source: GeneratedKernel,
    target: GeneratedKernel,
    adaptationRate: number
  ): GeneratedKernel {
    const blendedCoeffs = target.coefficients.map((tc, i) => {
      const sc = i < source.coefficients.length ? source.coefficients[i] : 0;
      return (1 - adaptationRate) * sc + adaptationRate * tc;
    });

    return { ...target, coefficients: blendedCoeffs };
  }

  private distillKernel(source: GeneratedKernel, target: GeneratedKernel): GeneratedKernel {
    // Transfer high-order coefficients
    const distilledCoeffs = target.coefficients.map((tc, i) => {
      if (i < 2) {
        // Keep target's base coefficients
        return tc;
      }
      // Transfer source's higher-order knowledge
      const sc = i < source.coefficients.length ? source.coefficients[i] : 0;
      return 0.7 * tc + 0.3 * sc;
    });

    return { ...target, coefficients: distilledCoeffs };
  }

  private adaptKernel(
    source: GeneratedKernel,
    target: GeneratedKernel,
    config: TransferConfig
  ): GeneratedKernel {
    // Freeze early coefficients, adapt later ones
    const adaptedCoeffs = target.coefficients.map((tc, i) => {
      if (i < config.freeze_layers) {
        // Frozen - use source
        return i < source.coefficients.length ? source.coefficients[i] : tc;
      }
      // Adapted - blend
      const sc = i < source.coefficients.length ? source.coefficients[i] : 0;
      return (1 - config.adaptation_rate) * sc + config.adaptation_rate * tc;
    });

    return { ...target, coefficients: adaptedCoeffs };
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  private computeMetadata(kernels: GeneratedKernel[], type: string): CompositionMetadata {
    const totalParams = kernels.reduce((sum, k) => sum + k.coefficients.length, 0);
    const estimatedFlops = totalParams * (type === 'sequential' ? 1 : 0.5) * 1000;

    return {
      creation_time: Date.now(),
      optimization_iterations: 0,
      total_parameters: totalParams,
      estimated_flops: estimatedFlops,
      memory_footprint: totalParams * 4 // 4 bytes per float
    };
  }

  /**
   * Get all available compositions
   */
  public getCompositions(): ComposedKernel[] {
    return Array.from(this.compositionCache.values());
  }

  /**
   * Cache a composition
   */
  public cacheComposition(composition: ComposedKernel): void {
    this.compositionCache.set(composition.id, composition);
  }
}

// ============================================================================
// SUPPORTING TYPES
// ============================================================================

interface DomainRelationship {
  domain1: string;
  domain2: string;
  similarity: number;
  coupling_strength: number;
  relationship_type: 'similar' | 'related' | 'distinct';
}

type HierarchicalStructure =
  | { kernel: GeneratedKernel }
  | { strategy: 'sequential' | 'parallel'; children: HierarchicalStructure[] };

// ============================================================================
// EXPORTS
// ============================================================================

export const KernelComposition = {
  Engine: KernelCompositionEngine,
  Strategy: CompositionStrategy,
  CombinationMethod
};
