/**
 * Quantum Change Gateway
 *
 * Implements transformative experience as an information-theoretic event:
 * a controlled phase transition where the crystal lattice undergoes
 * spontaneous symmetry breaking, creating a new attractor basin.
 *
 * Triggers when the system encounters a genuinely novel pattern:
 *   - No PPM match above threshold  (no resonance in existing primitives)
 *   - High fractal incompressibility (novel, non-reducible information)
 *   - Sufficient RR quality to sustain the new pattern
 *
 * On trigger, a new PerspectivalCrystal is crystallized from the novel input,
 * reorganizing the prime-vector space and potentially superseding an old crystal.
 *
 * Connects to the "egg → companion → transcendent" evolution stages already
 * present in the type system (ConsciousCompanion.evolutionStage).
 */

import {
  RelevanceCrystalPrimitive,
  PrimeVector,
  FUNDAMENTAL_PRIMES,
  createParticipatoryCrystal,
  createPerspectivalCrystal,
  ppmDistance,
  zeroPrimeVector,
} from './RelevanceCrystalPrimitive';
import { TimeCrystalSalienceLandscape } from './TimeCrystalSalienceLandscape';
import { RelevanceRealizationEngine } from './RelevanceRealizationEngine';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

export type EvolutionStage = 'egg' | 'larva' | 'companion' | 'transcendent';

export interface QuantumChangeEvent {
  id: string;
  timestamp: number;
  trigger: 'novelty' | 'coherence_collapse' | 'manual';
  noveltyScore: number;          // ∈ [0,1]
  incompressibilityScore: number; // ∈ [0,1]
  /** The new crystal crystallized from the novel input */
  newCrystalId: string;
  newCrystalLabel: string;
  /** The old crystal superseded (if any) */
  supersededCrystalId?: string;
  /** What evolution stage the system reached after this event */
  newEvolutionStage: EvolutionStage;
  /** The prime-vector of the novel pattern */
  novelVector: PrimeVector;
  /** Meaning score just before the transition */
  preMeaningScore: number;
  /** Estimated meaning score just after the transition */
  postMeaningScore: number;
}

export interface QuantumChangeConfig {
  /** Minimum PPM distance for a pattern to be "novel" */
  noveltyThreshold: number;
  /** Minimum fractal complexity for incompressibility trigger */
  incompressibilityThreshold: number;
  /** Minimum RR quality to proceed with crystallization */
  rrQualityMinimum: number;
  /** How much the decoherence event reduces all existing crystal coherences */
  decoherenceSeverity: number;
  /** Number of quantum change events needed to advance evolution stage */
  eventsPerStageAdvance: number;
}

const DEFAULT_CONFIG: QuantumChangeConfig = {
  noveltyThreshold: 0.7,
  incompressibilityThreshold: 0.6,
  rrQualityMinimum: 0.4,
  decoherenceSeverity: 0.2,
  eventsPerStageAdvance: 3,
};

// ─────────────────────────────────────────────────────────────────────────────
// Gateway
// ─────────────────────────────────────────────────────────────────────────────

export class QuantumChangeGateway {
  private config: QuantumChangeConfig;
  private landscape: TimeCrystalSalienceLandscape;
  private rrEngine: RelevanceRealizationEngine;

  private eventHistory: QuantumChangeEvent[] = [];
  private currentEvolutionStage: EvolutionStage = 'egg';
  private eventCount = 0;
  private _idCounter = 0;

  constructor(
    landscape: TimeCrystalSalienceLandscape,
    rrEngine: RelevanceRealizationEngine,
    config: Partial<QuantumChangeConfig> = {},
  ) {
    this.landscape = landscape;
    this.rrEngine = rrEngine;
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Evaluation — called each RR cycle
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Evaluate whether a quantum change event should be triggered.
   *
   * @param novelInputVector  Prime-vector of new environmental input
   * @param rrQuality         Current RR cycle quality
   * @param preMeaningScore   Meaning score before this cycle
   * @returns QuantumChangeEvent if triggered, null otherwise
   */
  evaluate(
    novelInputVector: PrimeVector,
    rrQuality: number,
    preMeaningScore: number,
  ): QuantumChangeEvent | null {
    const noveltyScore    = this._computeNovelty(novelInputVector);
    const incompressScore = this._computeIncompressibility(novelInputVector);

    const shouldTrigger =
      noveltyScore    >= this.config.noveltyThreshold &&
      incompressScore >= this.config.incompressibilityThreshold &&
      rrQuality       >= this.config.rrQualityMinimum;

    if (!shouldTrigger) return null;

    return this._crystallize(
      novelInputVector,
      noveltyScore,
      incompressScore,
      preMeaningScore,
      'novelty',
    );
  }

  /**
   * Manually trigger a quantum change (e.g., from user-injected insight).
   */
  triggerManual(
    novelInputVector: PrimeVector,
    label: string,
    preMeaningScore: number,
  ): QuantumChangeEvent {
    return this._crystallize(
      novelInputVector,
      1.0,
      1.0,
      preMeaningScore,
      'manual',
      label,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Crystallization
  // ─────────────────────────────────────────────────────────────────────────

  private _crystallize(
    novelVector: PrimeVector,
    noveltyScore: number,
    incompressScore: number,
    preMeaningScore: number,
    trigger: QuantumChangeEvent['trigger'],
    manualLabel?: string,
  ): QuantumChangeEvent {
    // 1. Controlled decoherence — loosen existing crystals
    this._applyDecoherence();

    // 2. Determine whether to create a Participatory or Perspectival crystal
    const seed = Math.floor(Date.now() % 100000);
    const label = manualLabel ?? `QuantumChange_${++this._idCounter}`;
    const newCrystal: RelevanceCrystalPrimitive =
      noveltyScore > 0.9
        ? createParticipatoryCrystal(label, seed, 5)
        : createPerspectivalCrystal(label, seed, noveltyScore);

    // 3. Set its prime-vector to the novel input
    newCrystal.primeVector.set(novelVector);
    newCrystal.coherence = 0.5 + noveltyScore * 0.4; // starts uncertain
    newCrystal.attentionValue.sti = 0.9; // immediately salient

    // 4. Supersede the least-relevant existing crystal of the same type
    const superseded = this._findWeakestPrimitive(newCrystal.knowingType);
    if (superseded) {
      this.landscape.deregisterPrimitive(superseded.id);
    }

    // 5. Register the new crystal
    this.landscape.registerPrimitive(newCrystal);

    // 6. Inject it as a new gating frame in the RR engine
    this.rrEngine.injectFrame(label, seed);

    // 7. Advance evolution stage if warranted
    this.eventCount++;
    if (this.eventCount % this.config.eventsPerStageAdvance === 0) {
      this._advanceEvolutionStage();
    }

    // Estimate post-meaning score
    const postMeaningScore = Math.min(1, preMeaningScore + 0.15 * noveltyScore);

    const event: QuantumChangeEvent = {
      id: `qce_${++this._idCounter}_${Date.now()}`,
      timestamp: Date.now(),
      trigger,
      noveltyScore,
      incompressibilityScore: incompressScore,
      newCrystalId: newCrystal.id,
      newCrystalLabel: newCrystal.label,
      supersededCrystalId: superseded?.id,
      newEvolutionStage: this.currentEvolutionStage,
      novelVector,
      preMeaningScore,
      postMeaningScore,
    };

    this.eventHistory.push(event);
    if (this.eventHistory.length > 50) this.eventHistory.shift();

    return event;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Novelty: minimum PPM distance from the novel vector to any existing crystal.
   * A high value means the pattern has no precedent in the current landscape.
   */
  private _computeNovelty(vec: PrimeVector): number {
    const all = this.landscape.getAllPrimitives();
    if (all.length === 0) return 1;
    const minDist = Math.min(...all.map(p => ppmDistance(p.primeVector, vec)));
    return Math.min(1, minDist); // clamp to [0,1]
  }

  /**
   * Incompressibility: Shannon entropy of the prime-vector values.
   * High entropy = the pattern cannot be summarized by a few primes alone.
   */
  private _computeIncompressibility(vec: PrimeVector): number {
    const n = FUNDAMENTAL_PRIMES.length;
    // Normalize to a probability distribution (L1-norm) before computing Shannon entropy
    let l1Sum = 0;
    for (let i = 0; i < n; i++) l1Sum += Math.abs(vec[i]);
    if (l1Sum < 1e-9) return 0;
    let entropy = 0;
    for (let i = 0; i < n; i++) {
      const p = Math.max(1e-9, Math.abs(vec[i]) / l1Sum);
      entropy -= p * Math.log2(p);
    }
    // Normalize by maximum possible entropy (log2(n))
    return Math.min(1, entropy / Math.log2(n));
  }

  /**
   * Apply controlled decoherence — reduce all existing crystal coherences.
   * This temporarily loosens the current salience landscape, making room for
   * the new pattern.
   */
  private _applyDecoherence(): void {
    this.landscape.getAllPrimitives().forEach(p => {
      p.coherence = Math.max(0.1, p.coherence - this.config.decoherenceSeverity);
    });
  }

  private _findWeakestPrimitive(
    knowingType: RelevanceCrystalPrimitive['knowingType'],
  ): RelevanceCrystalPrimitive | null {
    const same = this.landscape
      .getAllPrimitives()
      .filter(p => p.knowingType === knowingType);
    if (same.length === 0) return null;
    return same.sort(
      (a, b) => a.cumulativeResonance - b.cumulativeResonance,
    )[0];
  }

  private _advanceEvolutionStage(): void {
    const stages: EvolutionStage[] = ['egg', 'larva', 'companion', 'transcendent'];
    const idx = stages.indexOf(this.currentEvolutionStage);
    if (idx < stages.length - 1) {
      this.currentEvolutionStage = stages[idx + 1];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Accessors
  // ─────────────────────────────────────────────────────────────────────────

  get evolutionStage(): EvolutionStage { return this.currentEvolutionStage; }
  get totalEvents(): number { return this.eventCount; }
  getEventHistory(n = 10): QuantumChangeEvent[] { return this.eventHistory.slice(-n); }

  /** Build a probe novel vector from a seed for testing / demo */
  static buildNovelVector(seed: number): PrimeVector {
    const n = FUNDAMENTAL_PRIMES.length;
    const vec = zeroPrimeVector();
    for (let i = 0; i < n; i++) {
      vec[i] = Math.abs(Math.sin(seed * FUNDAMENTAL_PRIMES[i]));
    }
    const norm = Math.sqrt(vec.reduce((s, v) => s + v * v, 0)) || 1;
    for (let i = 0; i < n; i++) vec[i] /= norm;
    return vec;
  }
}
