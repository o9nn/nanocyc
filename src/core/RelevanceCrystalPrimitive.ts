/**
 * Relevance Crystal Primitives (RCP)
 *
 * Ontological primitives that fuse Vervaeke's four ways of knowing with
 * Bandyopadhyay's Phase Prime Metric.  Each primitive is a phase-locked time
 * crystal whose position in the 15-prime basis encodes its relevance signature.
 *
 * Four primitive sub-types map exactly to the four ways of knowing:
 *   PropositionalCrystal  – knowing-that  (stable attractor, truth-value)
 *   ProceduralCrystal     – knowing-how   (phase-advancing sequence)
 *   PerspectivalCrystal   – knowing-as    (salience-landscape framer)
 *   ParticipatoryCrystal  – knowing-by-being (identity-transforming)
 */

/** The 15 fundamental primes that together span 99.99 % of all integers */
export const FUNDAMENTAL_PRIMES: readonly number[] = [
  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
] as const;

/** How each knowing-type maps to a prime-group in the PPM */
export const KNOWING_TYPE_PRIME_GROUPS = {
  propositional: [2, 3, 5],          // Spatial Prime Metric (Ch.7 dim 3)
  procedural:    [7, 11, 13],         // Temporal Prime Metric (Ch.7 dim 1)
  perspectival:  [17, 19, 23],        // Phase Prime Metric (Ch.7 dim 4)
  participatory: [29, 31, 37, 41, 43, 47], // Consciousness Prime Metric (Ch.7 dim 11)
} as const;

export type KnowingType = keyof typeof KNOWING_TYPE_PRIME_GROUPS;

/**
 * A vector in the 15-prime basis.
 * Element i is the amplitude/weight of FUNDAMENTAL_PRIMES[i] in this crystal.
 */
export type PrimeVector = Float32Array; // length 15

/** Geometric shapes from GML (Ch.2) that encode the crystal's spatial signature */
export type GeometricEncoding =
  | 'sphere' | 'torus' | 'helix' | 'fractal' | 'hypercube'
  | 'simplex' | 'hexagonal' | 'dodecahedron' | 'tetrahedron' | 'spiral';

/** Core time-crystal quantum state (mirrors OpenCogNanoBrainKernel) */
export interface CrystalQuantumState {
  dimensions: number[];          // 11D manifold coordinates
  primeSignature: number[];      // PPM signature (15 primes)
  temporalCoherence: number;     // ∈ [0,1]
  fractalDimension: number;
  resonanceFrequency: number;    // Hz
  quantumPhase: number;          // radians ∈ [0, 2π]
}

/** A single Relevance Crystal Primitive */
export interface RelevanceCrystalPrimitive {
  id: string;
  knowingType: KnowingType;
  label: string;

  /** Position in the 15-prime relevance space */
  primeVector: PrimeVector;

  /** Temporal phase (broken-symmetry marker) ∈ [0, 2π] */
  phase: number;

  /** Quantum coherence ∈ [0, 1] */
  coherence: number;

  /** Truth value for propositional crystals; confidence for others */
  truthValue: { strength: number; confidence: number };

  /** The salience frame this crystal projects onto its context */
  frameAttractor: CrystalQuantumState;

  /** Fractal geometry encoding (GML Ch.2) */
  geometricEncoding: GeometricEncoding;

  /** ECAN-style importance */
  attentionValue: { sti: number; lti: number; vlti: number };

  /** Timestamp of last activation (ms since epoch) */
  lastActivated: number;

  /** Accumulated resonance score across recent cycles */
  cumulativeResonance: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory helpers
// ─────────────────────────────────────────────────────────────────────────────

let _idCounter = 0;
function nextId(prefix: string): string {
  return `${prefix}_${++_idCounter}_${Date.now()}`;
}

/** Build a zero prime-vector */
export function zeroPrimeVector(): PrimeVector {
  return new Float32Array(FUNDAMENTAL_PRIMES.length);
}

/** Initialise a prime-vector from a seed integer via PPM */
export function primeVectorFromSeed(seed: number): PrimeVector {
  const vec = zeroPrimeVector();
  FUNDAMENTAL_PRIMES.forEach((p, i) => {
    // Each prime contributes log(p)/p weight modulated by seed
    vec[i] = (Math.log(p) / p) * (1 + Math.sin((seed * p * Math.PI) / 180));
  });
  // L2-normalise
  const norm = Math.sqrt(vec.reduce((s, v) => s + v * v, 0)) || 1;
  for (let i = 0; i < vec.length; i++) vec[i] /= norm;
  return vec;
}

/** Build a default 11D crystal quantum state */
export function defaultCrystalQuantumState(
  resonanceFreq = 1.0,
  phase = 0,
): CrystalQuantumState {
  return {
    dimensions: Array.from({ length: 11 }, (_, i) => Math.cos((i * Math.PI) / 6)),
    primeSignature: Array.from(FUNDAMENTAL_PRIMES),
    temporalCoherence: 0.5,
    fractalDimension: 1.618, // golden ratio — natural fractal baseline
    resonanceFrequency: resonanceFreq,
    quantumPhase: phase,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Constructors for the four knowing-types
// ─────────────────────────────────────────────────────────────────────────────

/** knowing-that: stable attractor, high truth-value confidence */
export function createPropositionalCrystal(
  label: string,
  seed: number,
  truthStrength = 0.8,
  truthConfidence = 0.9,
): RelevanceCrystalPrimitive {
  const pv = primeVectorFromSeed(seed);
  // Boost propositional prime group
  KNOWING_TYPE_PRIME_GROUPS.propositional.forEach(p => {
    const idx = FUNDAMENTAL_PRIMES.indexOf(p);
    if (idx >= 0) pv[idx] *= 1.5;
  });

  return {
    id: nextId('prop'),
    knowingType: 'propositional',
    label,
    primeVector: pv,
    phase: (seed % 360) * (Math.PI / 180),
    coherence: 0.85,
    truthValue: { strength: truthStrength, confidence: truthConfidence },
    frameAttractor: defaultCrystalQuantumState(2.0 + (seed % 5)),
    geometricEncoding: 'sphere',
    attentionValue: { sti: 0.6, lti: 0.8, vlti: 0.5 },
    lastActivated: Date.now(),
    cumulativeResonance: 0,
  };
}

/** knowing-how: phase-advancing sequence crystal */
export function createProceduralCrystal(
  label: string,
  seed: number,
  sequenceLength = 7,
): RelevanceCrystalPrimitive {
  const pv = primeVectorFromSeed(seed + 1000);
  KNOWING_TYPE_PRIME_GROUPS.procedural.forEach(p => {
    const idx = FUNDAMENTAL_PRIMES.indexOf(p);
    if (idx >= 0) pv[idx] *= 1.5;
  });

  return {
    id: nextId('proc'),
    knowingType: 'procedural',
    label,
    primeVector: pv,
    phase: (seed * 13 % 360) * (Math.PI / 180),
    coherence: 0.7,
    truthValue: { strength: 0.6, confidence: 0.5 },
    frameAttractor: defaultCrystalQuantumState(5.0, (sequenceLength * Math.PI) / 12),
    geometricEncoding: 'helix',
    attentionValue: { sti: 0.5, lti: 0.6, vlti: 0.4 },
    lastActivated: Date.now(),
    cumulativeResonance: 0,
  };
}

/** knowing-as: shifts the salience landscape of other crystals */
export function createPerspectivalCrystal(
  label: string,
  seed: number,
  frameBias = 0.5,
): RelevanceCrystalPrimitive {
  const pv = primeVectorFromSeed(seed + 2000);
  KNOWING_TYPE_PRIME_GROUPS.perspectival.forEach(p => {
    const idx = FUNDAMENTAL_PRIMES.indexOf(p);
    if (idx >= 0) pv[idx] *= 1.5;
  });

  return {
    id: nextId('persp'),
    knowingType: 'perspectival',
    label,
    primeVector: pv,
    phase: (seed * 7 % 360) * (Math.PI / 180),
    coherence: 0.75,
    truthValue: { strength: frameBias, confidence: 0.6 },
    frameAttractor: defaultCrystalQuantumState(7.0, frameBias * Math.PI),
    geometricEncoding: 'torus',
    attentionValue: { sti: 0.7, lti: 0.5, vlti: 0.3 },
    lastActivated: Date.now(),
    cumulativeResonance: 0,
  };
}

/** knowing-by-being: identity-transforming, restructures the agent's frame */
export function createParticipatoryCrystal(
  label: string,
  seed: number,
  transformationDepth = 3,
): RelevanceCrystalPrimitive {
  const pv = primeVectorFromSeed(seed + 3000);
  KNOWING_TYPE_PRIME_GROUPS.participatory.forEach(p => {
    const idx = FUNDAMENTAL_PRIMES.indexOf(p);
    if (idx >= 0) pv[idx] *= 1.5;
  });

  return {
    id: nextId('part'),
    knowingType: 'participatory',
    label,
    primeVector: pv,
    phase: (seed * 3 % 360) * (Math.PI / 180),
    coherence: 0.9,
    truthValue: { strength: 0.95, confidence: 0.4 },  // deep but uncertain
    frameAttractor: defaultCrystalQuantumState(11.0, transformationDepth * (Math.PI / 6)),
    geometricEncoding: 'fractal',
    attentionValue: { sti: 0.4, lti: 0.9, vlti: 0.9 },
    lastActivated: Date.now(),
    cumulativeResonance: 0,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// PPM distance metric
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Phase Prime Metric distance between two prime-vectors.
 * Lower = more similar (more relevant to each other).
 * Uses weighted cosine divergence so that prime-group alignment matters more.
 */
export function ppmDistance(a: PrimeVector, b: PrimeVector): number {
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < FUNDAMENTAL_PRIMES.length; i++) {
    // Weight by log(prime) — larger primes carry more information per Bandyopadhyay
    const w = Math.log(FUNDAMENTAL_PRIMES[i]);
    dot  += a[i] * b[i] * w;
    normA += a[i] * a[i] * w;
    normB += b[i] * b[i] * w;
  }
  const cosine = dot / (Math.sqrt(normA) * Math.sqrt(normB) + 1e-9);
  return 1 - cosine; // 0 = identical, 2 = opposite
}

/**
 * Phase coherence score between two crystals at a given cognitive cycle time.
 * Measures how well their temporal phases align.
 */
export function phaseCoherence(a: RelevanceCrystalPrimitive, b: RelevanceCrystalPrimitive, t: number): number {
  const phaseDiff = Math.abs(
    Math.sin(a.phase + a.frameAttractor.resonanceFrequency * t) -
    Math.sin(b.phase + b.frameAttractor.resonanceFrequency * t),
  );
  return 1 - phaseDiff / 2; // ∈ [0, 1]
}

/**
 * Compute relevance of candidate primitive given a context primitive.
 *
 * Salience(rcp, context) = α·PPM_similarity + β·PhaseCoherence + γ·CoherenceProduct
 */
export function computeRelevance(
  candidate: RelevanceCrystalPrimitive,
  context: RelevanceCrystalPrimitive,
  t: number,
  alpha = 0.5,
  beta = 0.3,
  gamma = 0.2,
): number {
  const ppmSim = 1 - ppmDistance(candidate.primeVector, context.primeVector);
  const phaseCoh = phaseCoherence(candidate, context, t);
  const cohProduct = candidate.coherence * context.coherence;
  return alpha * ppmSim + beta * phaseCoh + gamma * cohProduct;
}

// ─────────────────────────────────────────────────────────────────────────────
// Seed population of primitives
// ─────────────────────────────────────────────────────────────────────────────

/** Build the default seed population of RCPs for initialising the system */
export function createSeedPopulation(): RelevanceCrystalPrimitive[] {
  return [
    // Propositional — causal / factual anchors
    createPropositionalCrystal('CausalRelation',     2,  0.9, 0.95),
    createPropositionalCrystal('TemporalFact',       7,  0.8, 0.85),
    createPropositionalCrystal('SpatialFact',       11,  0.75, 0.80),
    createPropositionalCrystal('PatternRecognition', 17,  0.85, 0.90),
    createPropositionalCrystal('LogicalRule',        23,  0.95, 0.95),

    // Procedural — skill / sequence programs
    createProceduralCrystal('AttentionShift',    3,  5),
    createProceduralCrystal('PatternMatching',   13, 7),
    createProceduralCrystal('MemoryRetrieval',   19, 3),
    createProceduralCrystal('InferenceChain',    29, 9),
    createProceduralCrystal('LearningUpdate',    37, 4),

    // Perspectival — framing / salience-landscape shapers
    createPerspectivalCrystal('ExplorationBias',   5,  0.7),
    createPerspectivalCrystal('ExploitationBias',  43, 0.3),
    createPerspectivalCrystal('NarrativeFrame',    31, 0.5),
    createPerspectivalCrystal('CausalFrame',       41, 0.6),
    createPerspectivalCrystal('EthicalFrame',      47, 0.8),

    // Participatory — identity / transformative
    createParticipatoryCrystal('SelfModel',            7,  4),
    createParticipatoryCrystal('WorldModel',           11, 3),
    createParticipatoryCrystal('AgentIdentity',        17, 5),
    createParticipatoryCrystal('TransformativeInsight', 23, 7),
    createParticipatoryCrystal('WisdomAttractor',      41, 9),
  ];
}
