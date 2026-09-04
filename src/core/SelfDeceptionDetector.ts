/**
 * Self-Deception Detector
 *
 * Implements Vervaeke's anti-bullshit principle as a first-class physical
 * phenomenon: self-deception is *false phase lock* — the agent's crystal
 * lattice has locked to an internal resonance rather than to the external
 * signal.
 *
 * Mechanism:
 *   1. Compare the prime-vectors of currently attended RCPs (top-k) against
 *      the prime-vector of the actual incoming environmental data.
 *   2. Compute PPM divergence: how much the agent's salience landscape
 *      deviates from what the environment actually presents.
 *   3. High divergence + high internal coherence = self-deception signal.
 *   4. Feed the signal back into the RR engine as a negative adaptation:
 *      loosen the false phase lock by reducing coherence and STI of the
 *      divergent crystals.
 *
 * Additionally tracks self-consistency of the agent's own narrative stream
 * (a form of internal coherence audit) to detect motivated reasoning.
 */

import {
  RelevanceCrystalPrimitive,
  PrimeVector,
  FUNDAMENTAL_PRIMES,
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

export interface SelfDeceptionReport {
  /** PPM divergence between top-k and environmental vector ∈ [0, 2] */
  ppmDivergence: number;
  /** Internal coherence of the top-k crystals ∈ [0, 1] */
  internalCoherence: number;
  /**
   * Self-deception index = divergence × internalCoherence
   * 0   = aligned and coherent (good)
   * 0.5 = divergent but incoherent (noise, not deception)
   * 1+  = divergent AND coherent  (classical bullshit)
   */
  selfDeceptionIndex: number;
  /** Whether the detector has fired a correction signal */
  correctionFired: boolean;
  /** Ids of crystals whose phase lock was loosened */
  correctedCrystalIds: string[];
  /** Narrative self-consistency score ∈ [0,1] */
  narrativeSelfConsistency: number;
  /** Motivated reasoning detected */
  motivatedReasoning: boolean;
  timestamp: number;
}

export interface SelfDeceptionConfig {
  /** Above this self-deception index, correction fires */
  correctionThreshold: number;
  /** How much STI is removed from divergent crystals on correction */
  correctionSTIReduction: number;
  /** How much coherence is reduced on divergent crystals */
  correctionCoherenceReduction: number;
  /** Window for narrative self-consistency check */
  narrativeWindowLength: number;
  /** Below this narrative consistency, flag motivated reasoning */
  motivatedReasoningThreshold: number;
}

const DEFAULT_CONFIG: SelfDeceptionConfig = {
  correctionThreshold: 0.5,
  correctionSTIReduction: 0.3,
  correctionCoherenceReduction: 0.15,
  narrativeWindowLength: 15,
  motivatedReasoningThreshold: 0.35,
};

// ─────────────────────────────────────────────────────────────────────────────
// Detector
// ─────────────────────────────────────────────────────────────────────────────

export class SelfDeceptionDetector {
  private config: SelfDeceptionConfig;
  private landscape: TimeCrystalSalienceLandscape;

  private reportHistory: SelfDeceptionReport[] = [];
  /** Ring buffer of previously attended prime-vectors for narrative check */
  private attendedVectorHistory: PrimeVector[] = [];

  constructor(
    landscape: TimeCrystalSalienceLandscape,
    config: Partial<SelfDeceptionConfig> = {},
  ) {
    this.landscape = landscape;
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main evaluation
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Evaluate the current snapshot against the environmental ground truth.
   *
   * @param snapshot          Latest salience landscape snapshot
   * @param environmentVector Prime-vector of current environmental input
   * @returns SelfDeceptionReport
   */
  evaluate(
    snapshot: SalienceLandscapeSnapshot,
    environmentVector: PrimeVector,
  ): SelfDeceptionReport {
    // ── PPM divergence ────────────────────────────────────────────────────
    const ppmDivergence = this.landscape.computePPMDivergence(
      snapshot,
      environmentVector,
    );

    // ── Internal coherence ────────────────────────────────────────────────
    const internalCoherence = snapshot.coherenceField;

    // ── Self-deception index ──────────────────────────────────────────────
    const selfDeceptionIndex = ppmDivergence * internalCoherence;

    // ── Narrative self-consistency ────────────────────────────────────────
    const currentCentroid = this.landscape.computeWindowCentroid(snapshot);
    const narrativeSelfConsistency = this._checkNarrativeConsistency(currentCentroid);

    // Update attended vector history
    this.attendedVectorHistory.push(currentCentroid);
    if (this.attendedVectorHistory.length > this.config.narrativeWindowLength * 2) {
      this.attendedVectorHistory.shift();
    }

    // ── Motivated reasoning ───────────────────────────────────────────────
    const motivatedReasoning =
      narrativeSelfConsistency < this.config.motivatedReasoningThreshold &&
      selfDeceptionIndex > this.config.correctionThreshold * 0.7;

    // ── Correction signal ─────────────────────────────────────────────────
    let correctionFired = false;
    const correctedCrystalIds: string[] = [];

    if (selfDeceptionIndex > this.config.correctionThreshold) {
      correctionFired = true;
      this._applyCorrection(snapshot, environmentVector, correctedCrystalIds);
    }

    const report: SelfDeceptionReport = {
      ppmDivergence,
      internalCoherence,
      selfDeceptionIndex,
      correctionFired,
      correctedCrystalIds,
      narrativeSelfConsistency,
      motivatedReasoning,
      timestamp: Date.now(),
    };

    this.reportHistory.push(report);
    if (this.reportHistory.length > 100) this.reportHistory.shift();

    return report;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Apply correction: loosen the phase lock of the most divergent crystals.
   */
  private _applyCorrection(
    snapshot: SalienceLandscapeSnapshot,
    environmentVector: PrimeVector,
    corrected: string[],
  ): void {
    // Rank top-k crystals by their individual PPM divergence from environment
    const scored = snapshot.topK
      .map(s => {
        const p = this.landscape.getPrimitive(s.primitiveId);
        if (!p) return null;
        return { p, divergence: ppmDistance(p.primeVector, environmentVector) };
      })
      .filter((x): x is { p: RelevanceCrystalPrimitive; divergence: number } => !!x)
      .sort((a, b) => b.divergence - a.divergence);

    // Loosen the top-3 most divergent
    scored.slice(0, 3).forEach(({ p }) => {
      p.attentionValue.sti = Math.max(0, p.attentionValue.sti - this.config.correctionSTIReduction);
      p.coherence = Math.max(0.1, p.coherence - this.config.correctionCoherenceReduction);
      corrected.push(p.id);
    });
  }

  /**
   * Narrative self-consistency: compare the current centroid to the mean of
   * the last N attended vectors.  Low score means the agent is drifting in
   * directions inconsistent with its own recent history.
   */
  private _checkNarrativeConsistency(currentCentroid: PrimeVector): number {
    const wLen = this.config.narrativeWindowLength;
    if (this.attendedVectorHistory.length < 2) return 0.8; // neutral at start

    const window = this.attendedVectorHistory.slice(-wLen);
    const n = FUNDAMENTAL_PRIMES.length;
    const historicalCentroid = zeroPrimeVector();
    window.forEach(vec => {
      for (let i = 0; i < n; i++) historicalCentroid[i] += vec[i];
    });
    for (let i = 0; i < n; i++) historicalCentroid[i] /= window.length;

    return 1 - ppmDistance(currentCentroid, historicalCentroid);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Accessors
  // ─────────────────────────────────────────────────────────────────────────

  getReportHistory(n = 10): SelfDeceptionReport[] {
    return this.reportHistory.slice(-n);
  }

  getLatestReport(): SelfDeceptionReport | null {
    return this.reportHistory[this.reportHistory.length - 1] ?? null;
  }

  /**
   * Rolling average self-deception index over the last N reports.
   */
  getAverageSelfDeceptionIndex(n = 20): number {
    const recent = this.reportHistory.slice(-n);
    if (recent.length === 0) return 0;
    return recent.reduce((s, r) => s + r.selfDeceptionIndex, 0) / recent.length;
  }

  /**
   * Overall epistemic health score ∈ [0,1].
   * Combines alignment with environment, narrative consistency, and absence
   * of motivated reasoning.
   */
  getEpistemicHealth(): number {
    const latest = this.getLatestReport();
    if (!latest) return 0.5;

    const alignmentScore = 1 - Math.min(1, latest.ppmDivergence);
    const consistencyScore = latest.narrativeSelfConsistency;
    const motivationPenalty = latest.motivatedReasoning ? 0.2 : 0;

    return Math.max(0, (alignmentScore * 0.5 + consistencyScore * 0.5) - motivationPenalty);
  }
}
