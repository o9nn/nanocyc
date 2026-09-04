/**
 * Relevance Realization Engine
 *
 * Implements Vervaeke's four-phase RR cycle mapped onto time-crystal dynamics:
 *
 *   Phase A — Filter  (PerspectivalCrystals gate the processing window)
 *   Phase B — Frame   (PPM-metric salience scores candidates; top-k promoted)
 *   Phase C — Feed-Forward (anticipatory resonance: predict next prime cluster)
 *   Phase D — Feed-Back   (coherence-driven Hebbian learning of prime-vectors)
 *
 * The engine drives the TimeCrystalSalienceLandscape and feeds results to
 * the three-orders coherence monitor.
 */

import {
  RelevanceCrystalPrimitive,
  PrimeVector,
  FUNDAMENTAL_PRIMES,
  createPerspectivalCrystal,
  ppmDistance,
  zeroPrimeVector,
} from './RelevanceCrystalPrimitive';
import {
  TimeCrystalSalienceLandscape,
  SalienceLandscapeSnapshot,
} from './TimeCrystalSalienceLandscape';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

export type RRPhase = 'filter' | 'frame' | 'feed_forward' | 'feed_back' | 'idle';

export interface RRCycleResult {
  cycleId: number;
  timestamp: number;
  phase: RRPhase;

  /** Phase A: active gating frames */
  activeFrames: string[];  // RCP ids of active PerspectivalCrystals

  /** Phase B: promoted salience snapshot */
  salienceSnapshot: SalienceLandscapeSnapshot;

  /** Phase C: anticipated next prime-cluster centroid */
  anticipatedVector: PrimeVector;

  /** Phase D: coherence achieved & learning delta */
  achievedCoherence: number;
  learningDelta: number;

  /** Overall RR quality ∈ [0,1] */
  rrQuality: number;

  /** Milliseconds taken for this cycle */
  cycleTimeMs: number;
}

export interface RREngineConfig {
  /** Number of PerspectivalCrystals kept active as gating frames */
  maxActiveFrames: number;
  /** How much phase-C anticipation influences the next cycle's context */
  anticipationStrength: number;
  /** Hebbian learning rate for phase-D prime-vector updates */
  hebbianLearningRate: number;
  /** Minimum coherence to confirm a feed-back update */
  coherenceThreshold: number;
  /** Target explore/exploit balance (0 = full exploit, 1 = full explore) */
  targetExploreBalance: number;
}

const DEFAULT_ENGINE_CONFIG: RREngineConfig = {
  maxActiveFrames: 3,
  anticipationStrength: 0.3,
  hebbianLearningRate: 0.05,
  coherenceThreshold: 0.4,
  targetExploreBalance: 0.5,
};

export interface RREngineStats {
  totalCycles: number;
  avgCycleTimeMs: number;
  avgRRQuality: number;
  avgCoherence: number;
  currentExploreBalance: number;
  phaseDistribution: Record<RRPhase, number>;
}

// ─────────────────────────────────────────────────────────────────────────────
// Engine
// ─────────────────────────────────────────────────────────────────────────────

export class RelevanceRealizationEngine {
  private config: RREngineConfig;
  private landscape: TimeCrystalSalienceLandscape;

  private cycleId = 0;
  private currentPhase: RRPhase = 'idle';
  private activeFrameIds: Set<string> = new Set();
  private lastAnticipatedVector: PrimeVector = zeroPrimeVector();
  private history: RRCycleResult[] = [];
  private stats: RREngineStats;

  constructor(
    landscape: TimeCrystalSalienceLandscape,
    config: Partial<RREngineConfig> = {},
  ) {
    this.landscape = landscape;
    this.config = { ...DEFAULT_ENGINE_CONFIG, ...config };
    this.stats = {
      totalCycles: 0,
      avgCycleTimeMs: 0,
      avgRRQuality: 0,
      avgCoherence: 0,
      currentExploreBalance: 0.5,
      phaseDistribution: { filter: 0, frame: 0, feed_forward: 0, feed_back: 0, idle: 0 },
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main cycle
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Execute one complete RR cycle (all four phases).
   *
   * @param dt          Time step in seconds since last cycle
   * @param inputVector Optional exogenous input (environmental prime-vector)
   */
  runCycle(dt: number, inputVector?: PrimeVector): RRCycleResult {
    const t0 = performance.now();
    this.cycleId++;

    // ── Phase A: Filter ───────────────────────────────────────────────────
    this.currentPhase = 'filter';
    const activeFrames = this._phaseA_Filter();

    // ── Determine context vector for phase B ──────────────────────────────
    // Blend: exogenous input + anticipation from last cycle
    const contextVector = this._blendContextVector(inputVector);

    // ── Phase B: Frame ────────────────────────────────────────────────────
    this.currentPhase = 'frame';
    // Pick a context primitive from the landscape for the landscape update
    const contextPrimitive = this._selectContextPrimitive(contextVector);
    const salienceSnapshot = this.landscape.update(dt, contextPrimitive, contextVector);

    // ── Phase C: Feed-Forward ─────────────────────────────────────────────
    this.currentPhase = 'feed_forward';
    const anticipatedVector = this._phaseC_FeedForward(salienceSnapshot);
    this.lastAnticipatedVector = anticipatedVector;

    // ── Phase D: Feed-Back ────────────────────────────────────────────────
    this.currentPhase = 'feed_back';
    const { achievedCoherence, learningDelta } =
      this._phaseD_FeedBack(salienceSnapshot);

    // ── Compute RR quality ────────────────────────────────────────────────
    const rrQuality = this._computeRRQuality(salienceSnapshot, achievedCoherence);

    const cycleTimeMs = performance.now() - t0;
    this.currentPhase = 'idle';

    const result: RRCycleResult = {
      cycleId: this.cycleId,
      timestamp: Date.now(),
      phase: 'idle',
      activeFrames,
      salienceSnapshot,
      anticipatedVector,
      achievedCoherence,
      learningDelta,
      rrQuality,
      cycleTimeMs,
    };

    this._updateStats(result);
    this.history.push(result);
    if (this.history.length > 100) this.history.shift();

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phase implementations
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Phase A — Filter.
   * PerspectivalCrystals with the highest cumulative resonance become the
   * active gating frames.  They modulate which patterns reach phase B.
   */
  private _phaseA_Filter(): string[] {
    const perspectival = this.landscape
      .getAllPrimitives()
      .filter(p => p.knowingType === 'perspectival')
      .sort((a, b) => b.cumulativeResonance - a.cumulativeResonance)
      .slice(0, this.config.maxActiveFrames);

    this.activeFrameIds = new Set(perspectival.map(p => p.id));
    return perspectival.map(p => p.id);
  }

  /**
   * Phase C — Feed-Forward / Anticipatory Resonance.
   * Walk forward along the PPM manifold from the current top-k centroid.
   * The "natural next cluster" is the direction of steepest prime coherence.
   */
  private _phaseC_FeedForward(snapshot: SalienceLandscapeSnapshot): PrimeVector {
    const centroid = this.landscape.computeWindowCentroid(snapshot);
    const n = FUNDAMENTAL_PRIMES.length;
    const anticipated = new Float32Array(n);

    // Project forward: each prime component is phase-advanced by its
    // natural frequency (p * coherenceField * 2π)
    for (let i = 0; i < n; i++) {
      const freq = FUNDAMENTAL_PRIMES[i] * snapshot.coherenceField;
      const advance = Math.cos(freq * 0.1); // 100ms look-ahead
      anticipated[i] = centroid[i] * advance;
    }

    // L2-normalise
    const norm = Math.sqrt(anticipated.reduce((s, v) => s + v * v, 0)) || 1;
    for (let i = 0; i < n; i++) anticipated[i] /= norm;

    return anticipated;
  }

  /**
   * Phase D — Feed-Back / Coherence-driven Hebbian learning.
   * Primitives that fired in the top-k and achieved high phase-coherence
   * have their prime-vectors pulled slightly toward the context centroid.
   */
  private _phaseD_FeedBack(
    snapshot: SalienceLandscapeSnapshot,
  ): { achievedCoherence: number; learningDelta: number } {
    const achievedCoherence = snapshot.coherenceField;
    let totalDelta = 0;

    if (achievedCoherence < this.config.coherenceThreshold) {
      return { achievedCoherence, learningDelta: 0 };
    }

    const centroid = this.landscape.computeWindowCentroid(snapshot);
    const lr = this.config.hebbianLearningRate * achievedCoherence;

    snapshot.topK.forEach(s => {
      const p = this.landscape.getPrimitive(s.primitiveId);
      if (!p) return;

      for (let i = 0; i < p.primeVector.length; i++) {
        const delta = lr * (centroid[i] - p.primeVector[i]);
        p.primeVector[i] += delta;
        totalDelta += Math.abs(delta);
      }

      // Also update LTI from STI (wisdom accumulation)
      p.attentionValue.lti = Math.min(
        1,
        p.attentionValue.lti + 0.001 * achievedCoherence,
      );
    });

    return { achievedCoherence, learningDelta: totalDelta };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  private _blendContextVector(input?: PrimeVector): PrimeVector {
    const n = FUNDAMENTAL_PRIMES.length;
    const blended = new Float32Array(n);

    if (input) {
      const w = 1 - this.config.anticipationStrength;
      for (let i = 0; i < n; i++) {
        blended[i] = w * input[i] + this.config.anticipationStrength * this.lastAnticipatedVector[i];
      }
    } else {
      blended.set(this.lastAnticipatedVector);
    }

    const norm = Math.sqrt(blended.reduce((s, v) => s + v * v, 0)) || 1;
    for (let i = 0; i < n; i++) blended[i] /= norm;
    return blended;
  }

  private _selectContextPrimitive(
    contextVector: PrimeVector,
  ): RelevanceCrystalPrimitive | null {
    const all = this.landscape.getAllPrimitives();
    if (all.length === 0) return null;

    // Pick the primitive whose prime-vector is closest to the context
    let best: RelevanceCrystalPrimitive = all[0];
    let bestDist = ppmDistance(all[0].primeVector, contextVector);

    for (let i = 1; i < all.length; i++) {
      const d = ppmDistance(all[i].primeVector, contextVector);
      if (d < bestDist) { bestDist = d; best = all[i]; }
    }
    return best;
  }

  private _computeRRQuality(
    snapshot: SalienceLandscapeSnapshot,
    achievedCoherence: number,
  ): number {
    const balanceScore = 1 - Math.abs(
      snapshot.explorationScore - this.config.targetExploreBalance,
    );
    const resonanceScore = snapshot.tripletBands.overallResonance;
    const coherenceScore = achievedCoherence;

    return (balanceScore * 0.3 + resonanceScore * 0.3 + coherenceScore * 0.4);
  }

  private _updateStats(result: RRCycleResult): void {
    const n = this.stats.totalCycles;
    this.stats.totalCycles++;
    this.stats.avgCycleTimeMs =
      (this.stats.avgCycleTimeMs * n + result.cycleTimeMs) / (n + 1);
    this.stats.avgRRQuality =
      (this.stats.avgRRQuality * n + result.rrQuality) / (n + 1);
    this.stats.avgCoherence =
      (this.stats.avgCoherence * n + result.achievedCoherence) / (n + 1);
    this.stats.currentExploreBalance = result.salienceSnapshot.explorationScore;
    this.stats.phaseDistribution['filter']++;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public accessors
  // ─────────────────────────────────────────────────────────────────────────

  get currentRRPhase(): RRPhase { return this.currentPhase; }
  get cycleCount(): number { return this.cycleId; }
  getStats(): RREngineStats { return { ...this.stats }; }
  getHistory(n = 10): RRCycleResult[] { return this.history.slice(-n); }

  /**
   * Inject an ad-hoc PerspectivalCrystal as a temporary gating frame.
   * Useful when the QuantumChangeGateway triggers a paradigm shift.
   */
  injectFrame(label: string, seed: number): string {
    const p = createPerspectivalCrystal(label, seed, 0.5 + Math.random() * 0.5);
    this.landscape.registerPrimitive(p);
    this.activeFrameIds.add(p.id);
    return p.id;
  }
}
