/**
 * Relevance Realization System — Integration Layer
 *
 * Wires together all five RR sub-systems and exposes a single, clean API that
 * can be called from the OpenCogNanoBrainKernel each processing cycle.
 *
 * Architecture:
 *   TimeCrystalSalienceLandscape  ← populated with seed RCPs
 *       ↑                  ↓
 *   RelevanceRealizationEngine   (drives the landscape, 4-phase RR cycle)
 *       ↓
 *   ThreeOrdersCoherenceMonitor  (meaning score)
 *       ↓
 *   QuantumChangeGateway         (transformation events)
 *   SelfDeceptionDetector        (epistemic hygiene)
 */

import {
  RelevanceCrystalPrimitive,
  PrimeVector,
  createSeedPopulation,
  zeroPrimeVector,
  primeVectorFromSeed,
  FUNDAMENTAL_PRIMES,
} from './RelevanceCrystalPrimitive';
import {
  TimeCrystalSalienceLandscape,
} from './TimeCrystalSalienceLandscape';
import {
  RelevanceRealizationEngine,
  RRCycleResult,
  RREngineStats,
} from './RelevanceRealizationEngine';
import {
  ThreeOrdersCoherenceMonitor,
  ThreeOrdersSnapshot,
} from './ThreeOrdersCoherenceMonitor';
import {
  QuantumChangeGateway,
  QuantumChangeEvent,
  EvolutionStage,
} from './QuantumChangeGateway';
import {
  SelfDeceptionDetector,
  SelfDeceptionReport,
} from './SelfDeceptionDetector';

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

export interface RRSystemConfig {
  /** Time step per cycle in seconds */
  dt: number;
  /** Whether to probe for quantum change events each cycle */
  enableQuantumChangeDetection: boolean;
  /** Whether to run self-deception detection each cycle */
  selfDeceptionDetectionRate: number; // 0 = off, 1 = every cycle, 0-1 = probability
  /** Number of top-k crystals in the salience window */
  salienceTopK: number;
}

const DEFAULT_RR_CONFIG: RRSystemConfig = {
  dt: 1 / 60,  // 60 Hz
  enableQuantumChangeDetection: true,
  selfDeceptionDetectionRate: 1,
  salienceTopK: 7,
};

// ─────────────────────────────────────────────────────────────────────────────
// Combined state snapshot
// ─────────────────────────────────────────────────────────────────────────────

export interface RRSystemState {
  cycleId: number;
  rrCycle: RRCycleResult;
  threeOrders: ThreeOrdersSnapshot;
  selfDeception: SelfDeceptionReport | null;
  quantumChangeEvent: QuantumChangeEvent | null;
  evolutionStage: EvolutionStage;
  rrStats: RREngineStats;
  epistemicHealth: number;
  timestamp: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// System
// ─────────────────────────────────────────────────────────────────────────────

export class RelevanceRealizationSystem {
  readonly landscape: TimeCrystalSalienceLandscape;
  readonly engine: RelevanceRealizationEngine;
  readonly threeOrdersMonitor: ThreeOrdersCoherenceMonitor;
  readonly quantumGateway: QuantumChangeGateway;
  readonly deceptionDetector: SelfDeceptionDetector;

  private config: RRSystemConfig;
  private primitiveMap: Map<string, RelevanceCrystalPrimitive>;
  private stateHistory: RRSystemState[] = [];
  private cycleId = 0;
  private environmentVector: PrimeVector;

  constructor(config: Partial<RRSystemConfig> = {}) {
    this.config = { ...DEFAULT_RR_CONFIG, ...config };

    // Seed population
    const seeds = createSeedPopulation();
    this.primitiveMap = new Map(seeds.map(p => [p.id, p]));

    // Instantiate sub-systems
    this.landscape = new TimeCrystalSalienceLandscape(seeds, {
      topK: this.config.salienceTopK,
    });
    this.engine = new RelevanceRealizationEngine(this.landscape);
    this.threeOrdersMonitor = new ThreeOrdersCoherenceMonitor();
    this.quantumGateway = new QuantumChangeGateway(this.landscape, this.engine);
    this.deceptionDetector = new SelfDeceptionDetector(this.landscape);

    // Default environment vector: uniform distribution over primes
    this.environmentVector = primeVectorFromSeed(42);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main cycle — call this each processing frame
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Run one complete RR system cycle.
   *
   * @param inputVector     Environmental prime-vector (optional)
   * @param reasoningDepth  Current PLN reasoning depth (from RecursiveReasoningEngine)
   * @param attentionEntropy Current attention entropy (from AttentionAllocationEngine)
   */
  tick(
    inputVector?: PrimeVector,
    reasoningDepth = 3,
    attentionEntropy = 0.5,
  ): RRSystemState {
    this.cycleId++;

    // Keep track of environment
    if (inputVector) {
      this.environmentVector = inputVector;
    } else {
      // Slowly drift the environment vector to simulate dynamic world
      this._driftEnvironment();
    }

    // ── RR cycle ──────────────────────────────────────────────────────────
    const rrCycle = this.engine.runCycle(this.config.dt, this.environmentVector);

    // Sync primitive map with landscape
    this.landscape.getAllPrimitives().forEach(p => {
      this.primitiveMap.set(p.id, p);
    });

    // ── Three-orders monitor ──────────────────────────────────────────────
    const threeOrders = this.threeOrdersMonitor.update(
      rrCycle,
      this.primitiveMap,
      reasoningDepth,
      attentionEntropy,
    );

    // ── Self-deception detection ──────────────────────────────────────────
    let selfDeception: SelfDeceptionReport | null = null;
    if (Math.random() < this.config.selfDeceptionDetectionRate) {
      selfDeception = this.deceptionDetector.evaluate(
        rrCycle.salienceSnapshot,
        this.environmentVector,
      );
    }

    // ── Quantum change check ──────────────────────────────────────────────
    let quantumChangeEvent: QuantumChangeEvent | null = null;
    if (this.config.enableQuantumChangeDetection) {
      quantumChangeEvent = this.quantumGateway.evaluate(
        this.environmentVector,
        rrCycle.rrQuality,
        threeOrders.meaningScore,
      );
    }

    const epistemicHealth = this.deceptionDetector.getEpistemicHealth();

    const state: RRSystemState = {
      cycleId: this.cycleId,
      rrCycle,
      threeOrders,
      selfDeception,
      quantumChangeEvent,
      evolutionStage: this.quantumGateway.evolutionStage,
      rrStats: this.engine.getStats(),
      epistemicHealth,
      timestamp: Date.now(),
    };

    this.stateHistory.push(state);
    if (this.stateHistory.length > 50) this.stateHistory.shift();

    return state;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Accessors
  // ─────────────────────────────────────────────────────────────────────────

  getStateHistory(n = 10): RRSystemState[] {
    return this.stateHistory.slice(-n);
  }

  getLatestState(): RRSystemState | null {
    return this.stateHistory[this.stateHistory.length - 1] ?? null;
  }

  getAllPrimitives(): RelevanceCrystalPrimitive[] {
    return this.landscape.getAllPrimitives();
  }

  get currentEvolutionStage(): EvolutionStage {
    return this.quantumGateway.evolutionStage;
  }

  /**
   * Manually inject a novel environmental stimulus to trigger exploration.
   */
  injectNovelStimulus(seed: number): void {
    this.environmentVector = zeroPrimeVector();
    // Build using QuantumChangeGateway's helper
    const novel = QuantumChangeGateway.buildNovelVector(seed);
    this.environmentVector = novel;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────────

  private _driftEnvironment(): void {
    const n = FUNDAMENTAL_PRIMES.length;
    const t = Date.now() / 10000; // slow drift
    for (let i = 0; i < n; i++) {
      const drift = 0.01 * Math.sin(t * FUNDAMENTAL_PRIMES[i]);
      this.environmentVector[i] = Math.max(0, this.environmentVector[i] + drift);
    }
    // Re-normalise
    const norm = Math.sqrt(
      this.environmentVector.reduce((s, v) => s + v * v, 0),
    ) || 1;
    for (let i = 0; i < n; i++) this.environmentVector[i] /= norm;
  }
}
