/**
 * Time Crystal Salience Landscape
 *
 * Implements the dynamic relevance filter that operates over the population of
 * Relevance Crystal Primitives (RCPs).  Salience is determined by three
 * mutually reinforcing signals:
 *
 *   1. PPM-metric proximity  — how close a crystal is to the current context
 *      in the 15-prime basis
 *   2. Phase alignment       — how well the crystal's temporal oscillation
 *      aligns with the current cognitive-cycle moment
 *   3. Fractal resonance     — whether the crystal's GML geometric encoding
 *      resonates with the context's fractal dimension
 *
 * Opponent processing (Ch.7 hexagonal lattice) is implemented as two
 * anti-phase crystal sub-populations:
 *   • Exploration lattice (PerspectivalCrystals) — surfaces novel patterns
 *   • Exploitation lattice (PropositionalCrystals) — surfaces familiar patterns
 *
 * Triplet-of-triplet resonance (Ch.6) is applied as a three-level harmonic
 * filter over the top-k scored candidates.
 */

import {
  RelevanceCrystalPrimitive,
  PrimeVector,
  FUNDAMENTAL_PRIMES,
  ppmDistance,
  computeRelevance,
  KnowingType,
} from './RelevanceCrystalPrimitive';

export interface SalienceScore {
  primitiveId: string;
  label: string;
  knowingType: KnowingType;
  score: number;           // ∈ [0, 1]
  ppmComponent: number;
  phaseComponent: number;
  fractalComponent: number;
  resonanceBand: 'high' | 'mid' | 'low';
}

export interface SalienceLandscapeSnapshot {
  cycleTime: number;       // seconds since start
  topK: SalienceScore[];
  explorationScore: number;  // balance ∈ [0,1]  (0=full exploit, 1=full explore)
  exploitationScore: number;
  coherenceField: number;    // average coherence of top-k
  opponentBalance: number;   // |explore – exploit| — 0 = balanced
  tripletBands: TripletBands;
}

/** Triplet-of-triplet resonance bands mirroring Ch.6.2.2 */
export interface TripletBands {
  /** Three groups of three resonance values */
  bands: number[][];  // [3][3]
  /** Overall resonance score across all nine bands */
  overallResonance: number;
}

export interface SalienceLandscapeConfig {
  /** Number of primitives to promote to the conscious window */
  topK: number;
  /** Weighting of PPM similarity in total salience score */
  alpha: number;
  /** Weighting of phase coherence */
  beta: number;
  /** Weighting of fractal resonance */
  gamma: number;
  /** Rate at which activated crystals decay back to baseline STI */
  attentionDecayRate: number;
  /** How strongly the exploration vs. exploitation balance shifts salience */
  opponentCouplingStrength: number;
}

const DEFAULT_CONFIG: SalienceLandscapeConfig = {
  topK: 7,
  alpha: 0.5,
  beta: 0.3,
  gamma: 0.2,
  attentionDecayRate: 0.02,
  opponentCouplingStrength: 0.4,
};

export class TimeCrystalSalienceLandscape {
  private config: SalienceLandscapeConfig;
  private primitives: Map<string, RelevanceCrystalPrimitive>;
  private cycleTime = 0;
  private history: SalienceLandscapeSnapshot[] = [];

  constructor(
    primitives: RelevanceCrystalPrimitive[],
    config: Partial<SalienceLandscapeConfig> = {},
  ) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.primitives = new Map(primitives.map(p => [p.id, p]));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /** Add or replace a primitive in the landscape */
  registerPrimitive(p: RelevanceCrystalPrimitive): void {
    this.primitives.set(p.id, p);
  }

  /** Remove a primitive (e.g. after it has been superseded by transformation) */
  deregisterPrimitive(id: string): void {
    this.primitives.delete(id);
  }

  get size(): number {
    return this.primitives.size;
  }

  /**
   * Advance the landscape by dt seconds and compute salience relative to a
   * context primitive (or a raw prime-vector).
   */
  update(
    dt: number,
    contextPrimitive: RelevanceCrystalPrimitive | null,
    contextVector?: PrimeVector,
  ): SalienceLandscapeSnapshot {
    this.cycleTime += dt;
    const t = this.cycleTime;

    const allPrimitives = Array.from(this.primitives.values());

    // ── 1. Decay STI for all primitives ──────────────────────────────────
    allPrimitives.forEach(p => {
      p.attentionValue.sti = Math.max(
        0,
        p.attentionValue.sti - this.config.attentionDecayRate * dt,
      );
    });

    // ── 2. Score all primitives ───────────────────────────────────────────
    const scores = allPrimitives.map(candidate =>
      this._scorePrimitive(candidate, contextPrimitive, contextVector, t),
    );
    scores.sort((a, b) => b.score - a.score);

    // ── 3. Promote top-k and boost their STI ─────────────────────────────
    const topK = scores.slice(0, this.config.topK);
    topK.forEach(s => {
      const p = this.primitives.get(s.primitiveId)!;
      p.attentionValue.sti = Math.min(1, p.attentionValue.sti + s.score * 0.3);
      p.lastActivated = Date.now();
      p.cumulativeResonance += s.score;
    });

    // ── 4. Opponent processing ────────────────────────────────────────────
    const { explorationScore, exploitationScore } = this._opponentScores(topK);

    // ── 5. Triplet-of-triplet resonance bands ─────────────────────────────
    const tripletBands = this._computeTripletBands(topK);

    // ── 6. Coherence field ────────────────────────────────────────────────
    const topPrimitives = topK
      .map(s => this.primitives.get(s.primitiveId))
      .filter((p): p is RelevanceCrystalPrimitive => !!p);
    const coherenceField =
      topPrimitives.length > 0
        ? topPrimitives.reduce((sum, p) => sum + p.coherence, 0) / topPrimitives.length
        : 0;

    const snapshot: SalienceLandscapeSnapshot = {
      cycleTime: t,
      topK,
      explorationScore,
      exploitationScore,
      coherenceField,
      opponentBalance: Math.abs(explorationScore - exploitationScore),
      tripletBands,
    };

    this.history.push(snapshot);
    if (this.history.length > 200) this.history.shift();

    return snapshot;
  }

  /** Retrieve the n most recent snapshots */
  getHistory(n = 10): SalienceLandscapeSnapshot[] {
    return this.history.slice(-n);
  }

  /** Retrieve a primitive by id */
  getPrimitive(id: string): RelevanceCrystalPrimitive | undefined {
    return this.primitives.get(id);
  }

  getAllPrimitives(): RelevanceCrystalPrimitive[] {
    return Array.from(this.primitives.values());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  private _scorePrimitive(
    candidate: RelevanceCrystalPrimitive,
    context: RelevanceCrystalPrimitive | null,
    contextVector: PrimeVector | undefined,
    t: number,
  ): SalienceScore {
    // PPM component
    const effectiveContextVector: PrimeVector =
      contextVector ?? context?.primeVector ?? candidate.primeVector;
    const ppmSim = 1 - ppmDistance(candidate.primeVector, effectiveContextVector);

    // Phase component — uses context's resonance freq if available
    const contextPhase = context
      ? context.phase + context.frameAttractor.resonanceFrequency * t
      : 0;
    const candidatePhase = candidate.phase + candidate.frameAttractor.resonanceFrequency * t;
    const phaseCoh = 0.5 * (1 + Math.cos(candidatePhase - contextPhase));

    // Fractal component — resonance between fractal dimensions
    const contextFractal = context?.frameAttractor.fractalDimension ?? 1.618;
    const fractalDiff = Math.abs(candidate.frameAttractor.fractalDimension - contextFractal);
    const fractalRes = Math.exp(-fractalDiff * 2);

    const score =
      this.config.alpha * ppmSim +
      this.config.beta  * phaseCoh +
      this.config.gamma * fractalRes;

    const band: SalienceScore['resonanceBand'] =
      score > 0.7 ? 'high' : score > 0.4 ? 'mid' : 'low';

    return {
      primitiveId: candidate.id,
      label: candidate.label,
      knowingType: candidate.knowingType,
      score,
      ppmComponent: ppmSim,
      phaseComponent: phaseCoh,
      fractalComponent: fractalRes,
      resonanceBand: band,
    };
  }

  /** Exploration = perspectival crystals in top-k; Exploitation = propositional */
  private _opponentScores(topK: SalienceScore[]): {
    explorationScore: number;
    exploitationScore: number;
  } {
    const k = topK.length || 1;
    const exploreCount = topK.filter(s => s.knowingType === 'perspectival').length;
    const exploitCount = topK.filter(s => s.knowingType === 'propositional').length;
    return {
      explorationScore:  exploreCount / k,
      exploitationScore: exploitCount / k,
    };
  }

  /**
   * Triplet-of-triplet resonance (Ch.6.2.2):
   * Three groups of three resonance values — each group corresponds to one
   * knowing-type cluster; the ninth value is inter-group coherence.
   */
  private _computeTripletBands(topK: SalienceScore[]): TripletBands {
    const groups: KnowingType[][] = [
      ['propositional', 'procedural'],
      ['perspectival'],
      ['participatory'],
    ];

    const bands: number[][] = groups.map(types => {
      const subset = topK.filter(s => types.includes(s.knowingType));
      if (subset.length === 0) return [0, 0, 0];
      const avg = subset.reduce((s, x) => s + x.score, 0) / subset.length;
      const maxS = Math.max(...subset.map(x => x.score), 0);
      const coherence = subset.reduce((s, x) => s + x.phaseComponent, 0) / subset.length;
      return [avg, maxS, coherence];
    });

    // Ensure exactly 3 values per band
    const normalised = bands.map(b => {
      while (b.length < 3) b.push(0);
      return b.slice(0, 3);
    });

    const overallResonance =
      normalised.flat().reduce((s, v) => s + v, 0) / 9;

    return { bands: normalised, overallResonance };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PPM Divergence (used by SelfDeceptionDetector)
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Compute average PPM distance between the currently attended primitives
   * (top-k) and a ground-truth / environmental prime-vector.
   * High divergence + high coherence = self-deception signal.
   */
  computePPMDivergence(
    lastSnapshot: SalienceLandscapeSnapshot,
    groundTruthVector: PrimeVector,
  ): number {
    const topPrimitives = lastSnapshot.topK
      .map(s => this.primitives.get(s.primitiveId))
      .filter((p): p is RelevanceCrystalPrimitive => !!p);

    if (topPrimitives.length === 0) return 0;

    const totalDivergence = topPrimitives.reduce(
      (sum, p) => sum + ppmDistance(p.primeVector, groundTruthVector),
      0,
    );
    return totalDivergence / topPrimitives.length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Unused context helper (kept for downstream consumers)
  // ─────────────────────────────────────────────────────────────────────────

  /** Score a specific candidate against a raw prime-vector context */
  scoreAgainst(
    candidate: RelevanceCrystalPrimitive,
    contextVector: PrimeVector,
    t = this.cycleTime,
  ): number {
    return computeRelevance(
      candidate,
      {
        ...candidate, // borrow shape; override vector
        primeVector: contextVector,
      } as RelevanceCrystalPrimitive,
      t,
    );
  }

  /** 
   * Compute the average prime-vector of the current top-k window.
   * Useful as a "current salience centroid".
   */
  computeWindowCentroid(snapshot: SalienceLandscapeSnapshot): PrimeVector {
    const n = FUNDAMENTAL_PRIMES.length;
    const centroid = new Float32Array(n);
    const topPrimitives = snapshot.topK
      .map(s => this.primitives.get(s.primitiveId))
      .filter((p): p is RelevanceCrystalPrimitive => !!p);

    if (topPrimitives.length === 0) return centroid;
    topPrimitives.forEach(p => {
      for (let i = 0; i < n; i++) centroid[i] += p.primeVector[i];
    });
    for (let i = 0; i < n; i++) centroid[i] /= topPrimitives.length;
    return centroid;
  }
}
