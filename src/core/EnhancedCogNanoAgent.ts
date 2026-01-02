/**
 * Enhanced CogNano Agent Integration
 * 
 * This module integrates learnability embeddings and cognitive grip fabric
 * into the CogNano agent system, enabling:
 * 1. Learning from cognitive patterns
 * 2. Multi-language idea transformation
 * 3. Adaptive reasoning with learned representations
 */

import {
  NNModule,
  SequentialModule,
  LinearModule,
  TanhModule,
  SigmoidModule,
  ReLUModule,
  EmbeddingModule,
  MSECriterion,
  Trainer
} from './LearnabilityEmbeddings';

import {
  CognitiveGripFabric,
  CognitiveIdea,
  OperationalImplementation,
  ExampleCognitiveIdeas
} from './CognitiveGripFabric';

import { GgmlTensor } from './GgmlTensorKernel';

/**
 * Enhanced CogNano agent configuration
 */
export interface EnhancedCogNanoConfig {
  // Embedding configuration
  embedding_dim: number;
  hidden_dim: number;
  output_dim: number;
  learning_rate: number;
  
  // Cognitive grip configuration
  enabled_languages: string[];
  transformation_depth: number;
  
  // Agent behavior
  enable_learning: boolean;
  enable_multi_language: boolean;
  adaptation_rate: number;
}

/**
 * Learnability metrics
 */
export interface LearnabilityMetrics {
  total_training_steps: number;
  current_loss: number;
  average_loss: number;
  learning_rate: number;
  convergence_score: number;
  embedding_quality: number;
  generalization_score: number;
}

/**
 * Cognitive transformation result
 */
export interface CognitiveTransformationResult {
  idea: CognitiveIdea;
  implementations: Map<string, OperationalImplementation>;
  selected_language: string;
  transformation_time_ms: number;
  success: boolean;
  errors: string[];
}

/**
 * Enhanced CogNano agent state
 */
export interface EnhancedCogNanoState {
  status: 'initializing' | 'ready' | 'learning' | 'transforming' | 'executing' | 'error';
  learnability_metrics: LearnabilityMetrics;
  cognitive_ideas_processed: number;
  transformations_completed: number;
  active_language: string;
  error_log: string[];
}

/**
 * Enhanced CogNano Agent
 * 
 * Integrates neural embeddings with multi-language cognitive transformations
 */
export class EnhancedCogNanoAgent {
  private config: EnhancedCogNanoConfig;
  private state: EnhancedCogNanoState;
  
  // Learning components
  private embeddingModel: NNModule;
  private trainer: Trainer;
  private criterion: MSECriterion;
  
  // Cognitive grip components
  private gripFabric: CognitiveGripFabric;
  
  // Training history
  private lossHistory: number[] = [];
  
  constructor(config: Partial<EnhancedCogNanoConfig> = {}) {
    // Initialize configuration with defaults
    this.config = {
      embedding_dim: 64,
      hidden_dim: 128,
      output_dim: 32,
      learning_rate: 0.01,
      enabled_languages: ['Racket', 'Clojure', 'Scheme', 'Perl', 'Raku'],
      transformation_depth: 3,
      enable_learning: true,
      enable_multi_language: true,
      adaptation_rate: 0.1,
      ...config
    };
    
    // Initialize state
    this.state = {
      status: 'initializing',
      learnability_metrics: {
        total_training_steps: 0,
        current_loss: 0,
        average_loss: 0,
        learning_rate: this.config.learning_rate,
        convergence_score: 0,
        embedding_quality: 0,
        generalization_score: 0
      },
      cognitive_ideas_processed: 0,
      transformations_completed: 0,
      active_language: 'Racket',
      error_log: []
    };
    
    // Initialize learning components
    this.embeddingModel = this.buildEmbeddingModel();
    this.criterion = new MSECriterion();
    this.trainer = new Trainer(this.embeddingModel, this.criterion, this.config.learning_rate);
    
    // Initialize cognitive grip fabric
    this.gripFabric = new CognitiveGripFabric();
    
    this.state.status = 'ready';
  }
  
  /**
   * Build the neural embedding model
   */
  private buildEmbeddingModel(): NNModule {
    // Create a simple feedforward network
    // Input -> Hidden (with Tanh) -> Output
    return new SequentialModule(
      new LinearModule(this.config.embedding_dim, this.config.hidden_dim),
      new TanhModule(),
      new LinearModule(this.config.hidden_dim, this.config.output_dim),
      new SigmoidModule()
    );
  }
  
  /**
   * Train the embedding model on a cognitive pattern
   */
  trainOnPattern(inputPattern: Float32Array, targetPattern: Float32Array): number {
    if (!this.config.enable_learning) {
      return 0;
    }
    
    this.state.status = 'learning';
    
    // Create tensors
    const inputTensor: GgmlTensor = {
      id: 'train_input',
      shape: [1, inputPattern.length],
      data: inputPattern,
      dtype: 'f32',
      requires_grad: true
    };
    
    const targetTensor: GgmlTensor = {
      id: 'train_target',
      shape: [1, targetPattern.length],
      data: targetPattern,
      dtype: 'f32',
      requires_grad: false
    };
    
    // Train
    const loss = this.trainer.train(inputTensor, targetTensor);
    
    // Update metrics
    this.lossHistory.push(loss);
    this.state.learnability_metrics.total_training_steps++;
    this.state.learnability_metrics.current_loss = loss;
    this.state.learnability_metrics.average_loss = 
      this.lossHistory.reduce((a, b) => a + b, 0) / this.lossHistory.length;
    
    // Calculate convergence score (inverse of recent loss trend)
    if (this.lossHistory.length > 10) {
      const recentLosses = this.lossHistory.slice(-10);
      const avgRecentLoss = recentLosses.reduce((a, b) => a + b, 0) / recentLosses.length;
      this.state.learnability_metrics.convergence_score = 
        Math.max(0, 1 - avgRecentLoss);
    }
    
    this.state.status = 'ready';
    return loss;
  }
  
  /**
   * Generate embedding for a cognitive pattern
   */
  generateEmbedding(inputPattern: Float32Array): Float32Array {
    const inputTensor: GgmlTensor = {
      id: 'embed_input',
      shape: [1, inputPattern.length],
      data: inputPattern,
      dtype: 'f32',
      requires_grad: false
    };
    
    this.embeddingModel.training = false;
    const outputTensor = this.embeddingModel.forward(inputTensor);
    
    return outputTensor.data;
  }
  
  /**
   * Transform a cognitive idea into operational implementations
   */
  transformCognitiveIdea(idea: CognitiveIdea): CognitiveTransformationResult {
    if (!this.config.enable_multi_language) {
      return {
        idea,
        implementations: new Map(),
        selected_language: 'none',
        transformation_time_ms: 0,
        success: false,
        errors: ['Multi-language transformation disabled']
      };
    }
    
    this.state.status = 'transforming';
    const startTime = performance.now();
    const errors: string[] = [];
    
    try {
      // Transform to all enabled languages
      const implementations = new Map<string, OperationalImplementation>();
      
      for (const language of this.config.enabled_languages) {
        const impl = this.gripFabric.transformToLanguage(idea, language);
        if (impl) {
          implementations.set(language, impl);
        } else {
          errors.push(`Failed to transform to ${language}`);
        }
      }
      
      // Select best language based on idea characteristics
      const selectedLanguage = this.selectBestLanguage(idea, implementations);
      
      this.state.cognitive_ideas_processed++;
      this.state.transformations_completed += implementations.size;
      this.state.active_language = selectedLanguage;
      this.state.status = 'ready';
      
      const transformationTime = performance.now() - startTime;
      
      return {
        idea,
        implementations,
        selected_language: selectedLanguage,
        transformation_time_ms: transformationTime,
        success: implementations.size > 0,
        errors
      };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      this.state.error_log.push(errorMsg);
      this.state.status = 'error';
      
      return {
        idea,
        implementations: new Map(),
        selected_language: 'none',
        transformation_time_ms: performance.now() - startTime,
        success: false,
        errors: [errorMsg]
      };
    }
  }
  
  /**
   * Select the best language for a cognitive idea
   */
  private selectBestLanguage(
    idea: CognitiveIdea,
    implementations: Map<string, OperationalImplementation>
  ): string {
    // Simple heuristic: prefer functional languages for pattern-based ideas
    if (idea.abstract_pattern.includes('pattern') || idea.abstract_pattern.includes('transform')) {
      if (implementations.has('Racket')) return 'Racket';
      if (implementations.has('Clojure')) return 'Clojure';
      if (implementations.has('Scheme')) return 'Scheme';
    }
    
    // Prefer Raku for complex text processing
    if (idea.domain.includes('text') || idea.domain.includes('processing')) {
      if (implementations.has('Raku')) return 'Raku';
      if (implementations.has('Perl')) return 'Perl';
    }
    
    // Default to first available
    return implementations.keys().next().value || 'none';
  }
  
  /**
   * Process a cognitive workflow: learn from patterns and transform ideas
   */
  async processCognitiveWorkflow(
    inputPatterns: Float32Array[],
    targetPatterns: Float32Array[],
    ideasToTransform: CognitiveIdea[]
  ): Promise<{
    training_losses: number[];
    transformations: CognitiveTransformationResult[];
    final_metrics: LearnabilityMetrics;
  }> {
    const training_losses: number[] = [];
    const transformations: CognitiveTransformationResult[] = [];
    
    // Phase 1: Learn from patterns
    if (this.config.enable_learning) {
      for (let i = 0; i < inputPatterns.length; i++) {
        const loss = this.trainOnPattern(inputPatterns[i], targetPatterns[i]);
        training_losses.push(loss);
      }
    }
    
    // Phase 2: Transform ideas
    if (this.config.enable_multi_language) {
      for (const idea of ideasToTransform) {
        const result = this.transformCognitiveIdea(idea);
        transformations.push(result);
      }
    }
    
    return {
      training_losses,
      transformations,
      final_metrics: this.state.learnability_metrics
    };
  }
  
  /**
   * Get current agent state
   */
  getState(): EnhancedCogNanoState {
    return { ...this.state };
  }
  
  /**
   * Get learnability metrics
   */
  getLearnabilityMetrics(): LearnabilityMetrics {
    return { ...this.state.learnability_metrics };
  }
  
  /**
   * Get cognitive grip fabric
   */
  getCognitiveGripFabric(): CognitiveGripFabric {
    return this.gripFabric;
  }
  
  /**
   * Update learning rate
   */
  setLearningRate(lr: number): void {
    this.config.learning_rate = lr;
    this.trainer.setLearningRate(lr);
    this.state.learnability_metrics.learning_rate = lr;
  }
  
  /**
   * Enable/disable learning
   */
  setLearningEnabled(enabled: boolean): void {
    this.config.enable_learning = enabled;
  }
  
  /**
   * Enable/disable multi-language transformation
   */
  setMultiLanguageEnabled(enabled: boolean): void {
    this.config.enable_multi_language = enabled;
  }
  
  /**
   * Reset the agent state
   */
  reset(): void {
    this.state = {
      status: 'ready',
      learnability_metrics: {
        total_training_steps: 0,
        current_loss: 0,
        average_loss: 0,
        learning_rate: this.config.learning_rate,
        convergence_score: 0,
        embedding_quality: 0,
        generalization_score: 0
      },
      cognitive_ideas_processed: 0,
      transformations_completed: 0,
      active_language: 'Racket',
      error_log: []
    };
    
    this.lossHistory = [];
    this.embeddingModel = this.buildEmbeddingModel();
    this.trainer = new Trainer(this.embeddingModel, this.criterion, this.config.learning_rate);
  }
}

/**
 * Factory function to create pre-configured enhanced CogNano agents
 */
export function createEnhancedCogNanoAgent(
  preset: 'default' | 'high-performance' | 'minimal' = 'default'
): EnhancedCogNanoAgent {
  const configs = {
    default: {
      embedding_dim: 64,
      hidden_dim: 128,
      output_dim: 32,
      learning_rate: 0.01,
      enabled_languages: ['Racket', 'Clojure', 'Scheme', 'Perl', 'Raku'],
      transformation_depth: 3,
      enable_learning: true,
      enable_multi_language: true,
      adaptation_rate: 0.1
    },
    'high-performance': {
      embedding_dim: 128,
      hidden_dim: 256,
      output_dim: 64,
      learning_rate: 0.005,
      enabled_languages: ['Racket', 'Clojure', 'Scheme', 'Perl', 'Raku'],
      transformation_depth: 5,
      enable_learning: true,
      enable_multi_language: true,
      adaptation_rate: 0.05
    },
    minimal: {
      embedding_dim: 32,
      hidden_dim: 64,
      output_dim: 16,
      learning_rate: 0.02,
      enabled_languages: ['Racket', 'Scheme'],
      transformation_depth: 2,
      enable_learning: true,
      enable_multi_language: true,
      adaptation_rate: 0.15
    }
  };
  
  return new EnhancedCogNanoAgent(configs[preset]);
}

/**
 * Example usage and demonstration
 */
export const CogNanoExamples = {
  /**
   * Create a simple learning example
   */
  createLearningExample(): {
    agent: EnhancedCogNanoAgent;
    inputPatterns: Float32Array[];
    targetPatterns: Float32Array[];
  } {
    const agent = createEnhancedCogNanoAgent('default');
    
    // Create simple XOR-like patterns
    const inputPatterns = [
      new Float32Array(64).fill(0).map((_, i) => i < 32 ? 1 : 0),
      new Float32Array(64).fill(0).map((_, i) => i < 32 ? 0 : 1),
      new Float32Array(64).fill(1)
    ];
    
    const targetPatterns = [
      new Float32Array(32).fill(0).map((_, i) => i < 16 ? 1 : 0),
      new Float32Array(32).fill(0).map((_, i) => i < 16 ? 0 : 1),
      new Float32Array(32).fill(0.5)
    ];
    
    return { agent, inputPatterns, targetPatterns };
  },
  
  /**
   * Create a transformation example
   */
  createTransformationExample(): {
    agent: EnhancedCogNanoAgent;
    ideas: CognitiveIdea[];
  } {
    const agent = createEnhancedCogNanoAgent('default');
    const ideas = Object.values(ExampleCognitiveIdeas);
    
    return { agent, ideas };
  }
};
