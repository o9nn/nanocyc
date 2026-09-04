/**
 * Three Orders Coherence Monitor
 *
 * Measures integration across Vervaeke's three orders of knowing:
 *
 *   Nomological  — how things causally work  (→ RecursiveReasoningEngine)
 *   Normative    — what matters and why      (→ Salience Landscape / ECAN)
 *   Narrative    — how things develop in time (→ temporal RCP stream)
 *
 * High cross-order coherence = meaning.  Low = meaning crisis.
 * The monitor emits a meaning score that is both a diagnostic and a training
 * signal for the MetaCognitiveFeedbackEngine.
 *
 * The Narrative Order is NEW — implemented here as a temporal stream of
 * activated RCP ids representing the agent's ongoing story / identity.
 */

import {
  RelevanceCrystalPrimitive,
  FUNDAMENTAL_PRIMES,
  KnowingType,
  ppmDistance,
  zeroPrimeVector,
} from './RelevanceCrystalPrimitive';
import { RRCycleResult } from './RelevanceRealizationEngine';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

/** A single moment in the narrative stream */
export interface NarrativeMoment {
  cycleId: number;
  timestamp: number;
  activatedRCPIds: string[];
  activatedLabels: string[];
  dominantKnowingType: KnowingType;
  narrativeCoherence: number;    // ∈ [0,1] — continuity with previous moment
}

export interface ThreeOrdersSnapshot {
  /** Cross-correlation between nomological and normative fields ∈ [0,1] */
  nomologicalNormativeCoherence: number;
  /** Cross-correlation between normative and narrative fields ∈ [0,1] */
  normativeNarrativeCoherence: number;
  /** Cross-correlation between nomological and narrative fields ∈ [0,1] */
  nomologicalNarrativeCoherence: number;
  /** Geometric mean of all three pairwise coherences — the meaning score */
  meaningScore: number;
  /** Whether the system is in a meaning-crisis state */
  meaningCrisis: boolean;
  /** Per-order quality scores */
  orderScores: {
    nomological: number;
    normative: number;
    narrative: number;
  };
  /** Latest narrative moment */
  latestNarrativeMoment: NarrativeMoment | null;
  timestamp: number;
}

export interface ThreeOrdersConfig {
  /** Window length for narrative continuity comparison */
  narrativeWindowLength: number;
  /** Threshold below which meaningScore triggers a crisis flag */
  meaningCrisisThreshold: number;
  /** Exponential smoothing factor for order scores */
  smoothingAlpha: number;
}

const DEFAULT_CONFIG: ThreeOrdersConfig = {
  narrativeWindowLength: 10,
  meaningCrisisThreshold: 0.3,
  smoothingAlpha: 0.2,
};

// ─────────────────────────────────────────────────────────────────────────────
// Monitor
// ─────────────────────────────────────────────────────────────────────────────

export class ThreeOrdersCoherenceMonitor {
  private config: ThreeOrdersConfig;
  private narrativeStream: NarrativeMoment[] = [];
  private snapshotHistory: ThreeOrdersSnapshot[] = [];

  // Smoothed per-order scores
  private smoothedNomological = 0.5;
  private smoothedNormative = 0.5;
  private smoothedNarrative = 0.5;

  constructor(config: Partial<ThreeOrdersConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main update — called once per RR cycle
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Ingest a completed RR cycle result and return a three-orders snapshot.
   *
   * @param rrResult      Latest RR cycle output
   * @param primitives    Map of all RCPs (for label lookup)
   * @param reasoningDepth Current PLN reasoning depth (proxy for nomological activity)
   * @param attentionEntropy Current attention entropy (proxy for normative quality)
   */
  update(
    rrResult: RRCycleResult,
    primitives: Map<string, RelevanceCrystalPrimitive>,
    reasoningDepth: number,
    attentionEntropy: number,
  ): ThreeOrdersSnapshot {
    // ── Nomological score ─────────────────────────────────────────────────
    // Proxy: how deep and coherent the current reasoning chain is
    const nomRaw = Math.min(1, reasoningDepth / 7) * rrResult.achievedCoherence;
    this.smoothedNomological =
      this.config.smoothingAlpha * nomRaw +
      (1 - this.config.smoothingAlpha) * this.smoothedNomological;

    // ── Normative score ───────────────────────────────────────────────────
    // Proxy: quality of the salience landscape (attention entropy + RR quality)
    const normRaw =
      0.5 * (1 - attentionEntropy) + // lower entropy = more focused relevance
      0.5 * rrResult.rrQuality;
    this.smoothedNormative =
      this.config.smoothingAlpha * normRaw +
      (1 - this.config.smoothingAlpha) * this.smoothedNormative;

    // ── Narrative: build a new moment ────────────────────────────────────
    const activatedIds = rrResult.salienceSnapshot.topK.map(s => s.primitiveId);
    const activatedLabels = activatedIds.map(id => primitives.get(id)?.label ?? id);
    const dominantType = this._dominantKnowingType(rrResult);

    const narrativeCoh = this._computeNarrativeCoherence(activatedIds, primitives);
    const moment: NarrativeMoment = {
      cycleId: rrResult.cycleId,
      timestamp: rrResult.timestamp,
      activatedRCPIds: activatedIds,
      activatedLabels,
      dominantKnowingType: dominantType,
      narrativeCoherence: narrativeCoh,
    };
    this.narrativeStream.push(moment);
    if (this.narrativeStream.length > 200) this.narrativeStream.shift();

    const narRaw = narrativeCoh;
    this.smoothedNarrative =
      this.config.smoothingAlpha * narRaw +
      (1 - this.config.smoothingAlpha) * this.smoothedNarrative;

    // ── Cross-order coherences ────────────────────────────────────────────
    const nomNorm = this._crossCoherence(
      this.smoothedNomological, this.smoothedNormative,
    );
    const normNar = this._crossCoherence(
      this.smoothedNormative, this.smoothedNarrative,
    );
    const nomNar = this._crossCoherence(
      this.smoothedNomological, this.smoothedNarrative,
    );

    // Geometric mean — meaning requires ALL three orders to be co-present
    const meaningScore =
      Math.pow(nomNorm * normNar * nomNar, 1 / 3);

    const snapshot: ThreeOrdersSnapshot = {
      nomologicalNormativeCoherence: nomNorm,
      normativeNarrativeCoherence: normNar,
      nomologicalNarrativeCoherence: nomNar,
      meaningScore,
      meaningCrisis: meaningScore < this.config.meaningCrisisThreshold,
      orderScores: {
        nomological: this.smoothedNomological,
        normative:   this.smoothedNormative,
        narrative:   this.smoothedNarrative,
      },
      latestNarrativeMoment: moment,
      timestamp: Date.now(),
    };

    this.snapshotHistory.push(snapshot);
    if (this.snapshotHistory.length > 200) this.snapshotHistory.shift();

    return snapshot;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Narrative stream access
  // ─────────────────────────────────────────────────────────────────────────

  getNarrativeStream(n = 20): NarrativeMoment[] {
    return this.narrativeStream.slice(-n);
  }

  getSnapshotHistory(n = 20): ThreeOrdersSnapshot[] {
    return this.snapshotHistory.slice(-n);
  }

  getLatestSnapshot(): ThreeOrdersSnapshot | null {
    return this.snapshotHistory[this.snapshotHistory.length - 1] ?? null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Narrative coherence: overlap between the current top-k prime-vectors and
   * the previous window's centroid prime-vector.  High = continuous story.
   */
  private _computeNarrativeCoherence(
    activatedIds: string[],
    primitives: Map<string, RelevanceCrystalPrimitive>,
  ): number {
    const wLen = this.config.narrativeWindowLength;
    if (this.narrativeStream.length < 2) return 0.5; // neutral at start

    // Build centroid of recent window
    const window = this.narrativeStream.slice(-wLen);
    const n = FUNDAMENTAL_PRIMES.length;
    const windowCentroid = zeroPrimeVector();
    let count = 0;
    window.forEach(moment => {
      moment.activatedRCPIds.forEach(id => {
        const p = primitives.get(id);
        if (!p) return;
        for (let i = 0; i < n; i++) windowCentroid[i] += p.primeVector[i];
        count++;
      });
    });
    if (count > 0) for (let i = 0; i < n; i++) windowCentroid[i] /= count;

    // Build centroid of current activations
    const currentCentroid = zeroPrimeVector();
    let curCount = 0;
    activatedIds.forEach(id => {
      const p = primitives.get(id);
      if (!p) return;
      for (let i = 0; i < n; i++) currentCentroid[i] += p.primeVector[i];
      curCount++;
    });
    if (curCount > 0) for (let i = 0; i < n; i++) currentCentroid[i] /= curCount;

    // Coherence = 1 - PPM distance
    return 1 - ppmDistance(currentCentroid, windowCentroid);
  }

  private _dominantKnowingType(rrResult: RRCycleResult): KnowingType {
    const counts: Record<KnowingType, number> = {
      propositional: 0,
      procedural: 0,
      perspectival: 0,
      participatory: 0,
    };
    rrResult.salienceSnapshot.topK.forEach(s => counts[s.knowingType]++);
    return (Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0]) as KnowingType;
  }

  /**
   * Cross-order coherence: geometric mean of the two scores.
   * Both must be high for cross-order coherence to be high.
   */
  private _crossCoherence(a: number, b: number): number {
    return Math.sqrt(Math.max(0, a) * Math.max(0, b));
  }
}
