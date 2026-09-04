import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Brain, Zap, RefreshCw, Layers, AlertTriangle, Sparkles, TrendingUp, Shield, Activity } from 'lucide-react';
import { RelevanceRealizationSystem } from '../core/RelevanceRealizationSystem';
import { RRSystemState } from '../core/RelevanceRealizationSystem';
import { FUNDAMENTAL_PRIMES, KnowingType } from '../core/RelevanceCrystalPrimitive';

// ─────────────────────────────────────────────────────────────────────────────
// Colour helpers
// ─────────────────────────────────────────────────────────────────────────────

const KNOWING_COLORS: Record<KnowingType, string> = {
  propositional: '#06b6d4',   // cyan
  procedural:    '#a855f7',   // purple
  perspectival:  '#22c55e',   // green
  participatory: '#f97316',   // orange
};

const KNOWING_LABELS: Record<KnowingType, string> = {
  propositional: 'Propositional (knowing-that)',
  procedural:    'Procedural (knowing-how)',
  perspectival:  'Perspectival (knowing-as)',
  participatory: 'Participatory (knowing-by-being)',
};

function pct(v: number, digits = 1): string {
  return `${(v * 100).toFixed(digits)}%`;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini bar component
// ─────────────────────────────────────────────────────────────────────────────

function Bar({ value, color, label }: { value: number; color: string; label: string }) {
  return (
    <div className="flex items-center space-x-2 text-xs">
      <span className="text-gray-400 w-36 truncate">{label}</span>
      <div className="flex-1 bg-gray-700 rounded-full h-2 overflow-hidden">
        <div
          className="h-full rounded-full transition-all duration-300"
          style={{ width: `${Math.min(1, value) * 100}%`, backgroundColor: color }}
        />
      </div>
      <span className="font-mono w-12 text-right" style={{ color }}>{pct(value)}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Prime-vector spark-line
// ─────────────────────────────────────────────────────────────────────────────

function PrimeVectorSparkline({ vector, color = '#06b6d4' }: { vector: Float32Array | number[]; color?: string }) {
  const max = Math.max(...Array.from(vector), 0.01);
  return (
    <svg viewBox={`0 0 ${FUNDAMENTAL_PRIMES.length * 12} 40`} className="w-full h-10">
      {FUNDAMENTAL_PRIMES.map((p, i) => {
        const h = (vector[i] / max) * 34;
        return (
          <g key={p}>
            <rect
              x={i * 12 + 1}
              y={38 - h}
              width={10}
              height={h}
              fill={color}
              opacity={0.75}
              rx={1}
            />
            <text x={i * 12 + 6} y={42} textAnchor="middle" fill="#6b7280" fontSize="6">{p}</text>
          </g>
        );
      })}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Triplet-of-triplet resonance display
// ─────────────────────────────────────────────────────────────────────────────

function TripletBandsDisplay({ bands, overall }: { bands: number[][]; overall: number }) {
  const groupLabels = ['Prop/Proc', 'Perspect.', 'Particip.'];
  const bandColors = ['#06b6d4', '#a855f7', '#f97316'];

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between mb-1">
        <span className="text-xs text-gray-400">Triplet-of-Triplet Resonance (Ch.6)</span>
        <span className="text-xs font-mono text-cyan-400">{pct(overall)}</span>
      </div>
      {bands.map((band, gi) => (
        <div key={gi} className="flex items-center space-x-1">
          <span className="text-xs w-16 truncate" style={{ color: bandColors[gi] }}>
            {groupLabels[gi]}
          </span>
          {band.map((v, bi) => (
            <div key={bi} className="flex-1 bg-gray-700 rounded h-1.5 overflow-hidden">
              <div
                className="h-full rounded transition-all duration-300"
                style={{ width: `${v * 100}%`, backgroundColor: bandColors[gi] }}
              />
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main panel
// ─────────────────────────────────────────────────────────────────────────────

export const RelevanceRealizationPanel: React.FC = () => {
  const rrSystem = useRef<RelevanceRealizationSystem | null>(null);
  const [state, setState] = useState<RRSystemState | null>(null);
  const [isRunning, setIsRunning] = useState(false);
  const [activeSection, setActiveSection] = useState<
    'overview' | 'landscape' | 'orders' | 'quantum' | 'deception'
  >('overview');
  const [cycleCount, setCycleCount] = useState(0);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // ── Initialise system ────────────────────────────────────────────────────
  useEffect(() => {
    rrSystem.current = new RelevanceRealizationSystem({
      dt: 1 / 10, // 10 Hz for demo
      enableQuantumChangeDetection: true,
      selfDeceptionDetectionRate: 1,
      salienceTopK: 7,
    });
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  // ── Tick ─────────────────────────────────────────────────────────────────
  const tick = useCallback(() => {
    if (!rrSystem.current) return;
    const s = rrSystem.current.tick(undefined, 3 + Math.random() * 4, 0.3 + Math.random() * 0.4);
    setState(s);
    setCycleCount(c => c + 1);
  }, []);

  const startStop = useCallback(() => {
    if (isRunning) {
      if (intervalRef.current) clearInterval(intervalRef.current);
      intervalRef.current = null;
      setIsRunning(false);
    } else {
      intervalRef.current = setInterval(tick, 200);
      setIsRunning(true);
    }
  }, [isRunning, tick]);

  const injectNovelty = useCallback(() => {
    rrSystem.current?.injectNovelStimulus(Math.floor(Math.random() * 10000));
    tick();
  }, [tick]);

  const salienceSnapshot = state?.rrCycle.salienceSnapshot;
  const threeOrders = state?.threeOrders;
  const sdReport = state?.selfDeception;
  const qce = state?.quantumChangeEvent;

  // ─────────────────────────────────────────────────────────────────────────

  return (
    <div className="space-y-6">
      {/* ── Header ─────────────────────────────────────────────────────── */}
      <div className="bg-gradient-to-r from-cyan-900/30 via-purple-900/30 to-orange-900/30 border border-cyan-700 rounded-xl p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Brain className="text-cyan-400" size={32} />
            <div>
              <h2 className="text-2xl font-bold text-white">
                Relevance Realization System
              </h2>
              <p className="text-gray-300 text-sm">
                Time Crystal Ontological Primitives × Vervaeke's 4-Phase RR Cycle
              </p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <div className="text-right text-xs text-gray-400">
              <div>Cycles: <span className="text-cyan-400 font-mono">{cycleCount}</span></div>
              <div>Stage: <span className="text-orange-400 font-mono capitalize">
                {state?.evolutionStage ?? 'egg'}
              </span></div>
            </div>
            <button
              onClick={injectNovelty}
              className="flex items-center space-x-1 px-3 py-2 rounded-lg bg-purple-800/50 border border-purple-600 text-purple-300 text-xs hover:bg-purple-700/50 transition-all"
            >
              <Sparkles size={14} />
              <span>Inject Novelty</span>
            </button>
            <button
              onClick={startStop}
              className={`flex items-center space-x-2 px-4 py-2 rounded-lg font-semibold text-sm transition-all ${
                isRunning
                  ? 'bg-red-500/80 hover:bg-red-600 text-white'
                  : 'bg-gradient-to-r from-cyan-500 to-purple-500 hover:from-cyan-600 hover:to-purple-600 text-white'
              }`}
            >
              {isRunning ? <RefreshCw size={16} className="animate-spin" /> : <Zap size={16} />}
              <span>{isRunning ? 'Stop' : 'Start'} RR Engine</span>
            </button>
          </div>
        </div>

        {/* Top-level metrics row */}
        {state && (
          <div className="mt-4 grid grid-cols-5 gap-3">
            {[
              { label: 'RR Quality', value: state.rrCycle.rrQuality, color: '#06b6d4' },
              { label: 'Meaning Score', value: threeOrders?.meaningScore ?? 0, color: '#22c55e' },
              { label: 'Coherence', value: state.rrCycle.achievedCoherence, color: '#a855f7' },
              { label: 'Epistemic Health', value: state.epistemicHealth, color: '#f97316' },
              { label: 'Triplet Resonance', value: salienceSnapshot?.tripletBands.overallResonance ?? 0, color: '#eab308' },
            ].map(m => (
              <div key={m.label} className="bg-gray-900/50 rounded-lg p-3 text-center">
                <div className="text-xs text-gray-400 mb-1">{m.label}</div>
                <div className="text-xl font-bold font-mono" style={{ color: m.color }}>
                  {pct(m.value, 0)}
                </div>
                <div className="mt-1 bg-gray-700 rounded-full h-1 overflow-hidden">
                  <div className="h-full rounded-full" style={{ width: `${m.value * 100}%`, backgroundColor: m.color }} />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── Crisis / Event banners ─────────────────────────────────────── */}
      {threeOrders?.meaningCrisis && (
        <div className="bg-red-900/30 border border-red-600 rounded-xl p-4 flex items-center space-x-3">
          <AlertTriangle className="text-red-400" size={20} />
          <div>
            <span className="text-red-400 font-semibold">Meaning Crisis Detected</span>
            <span className="text-gray-300 text-sm ml-2">
              Three-orders coherence below threshold ({pct(threeOrders.meaningScore)})
            </span>
          </div>
        </div>
      )}
      {qce && (
        <div className="bg-purple-900/30 border border-purple-600 rounded-xl p-4 flex items-center space-x-3">
          <Sparkles className="text-purple-400" size={20} />
          <div>
            <span className="text-purple-400 font-semibold">Quantum Change Event</span>
            <span className="text-gray-300 text-sm ml-2">
              New crystal crystallized: <span className="text-purple-300 font-mono">{qce.newCrystalLabel}</span>
              {' '}(novelty {pct(qce.noveltyScore)}) → Stage:{' '}
              <span className="text-orange-400 capitalize">{qce.newEvolutionStage}</span>
            </span>
          </div>
        </div>
      )}
      {sdReport?.correctionFired && (
        <div className="bg-yellow-900/30 border border-yellow-600 rounded-xl p-4 flex items-center space-x-3">
          <Shield className="text-yellow-400" size={20} />
          <div>
            <span className="text-yellow-400 font-semibold">Self-Deception Corrected</span>
            <span className="text-gray-300 text-sm ml-2">
              PPM divergence {sdReport.ppmDivergence.toFixed(3)} — phase lock loosened on{' '}
              {sdReport.correctedCrystalIds.length} crystals
              {sdReport.motivatedReasoning && ' · Motivated reasoning detected'}
            </span>
          </div>
        </div>
      )}

      {/* ── Section tabs ───────────────────────────────────────────────── */}
      <div className="flex space-x-2 flex-wrap gap-2">
        {[
          { id: 'overview',   label: 'RR Cycle',       icon: Activity },
          { id: 'landscape',  label: 'Salience Landscape', icon: Layers },
          { id: 'orders',     label: 'Three Orders',   icon: TrendingUp },
          { id: 'quantum',    label: 'Quantum Change', icon: Sparkles },
          { id: 'deception',  label: 'Self-Deception', icon: Shield },
        ].map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => setActiveSection(id as typeof activeSection)}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg border text-sm font-medium transition-all ${
              activeSection === id
                ? 'bg-cyan-900/40 border-cyan-600 text-cyan-300'
                : 'bg-gray-800/30 border-gray-700 text-gray-400 hover:border-gray-600'
            }`}
          >
            <Icon size={16} />
            <span>{label}</span>
          </button>
        ))}
      </div>

      {/* ══════════════════ SECTION: RR CYCLE OVERVIEW ══════════════════ */}
      {activeSection === 'overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Four-phase cycle */}
          <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
            <h3 className="text-white font-bold mb-4 flex items-center space-x-2">
              <Activity size={20} className="text-cyan-400" />
              <span>Four-Phase RR Cycle</span>
            </h3>
            {[
              {
                phase: 'A — Filter',
                desc: 'PerspectivalCrystals gate the processing window',
                value: state?.rrCycle.activeFrames.length ?? 0,
                max: 3,
                color: '#22c55e',
                detail: state?.rrCycle.activeFrames.length
                  ? `${state.rrCycle.activeFrames.length} active frames`
                  : 'No active frames',
              },
              {
                phase: 'B — Frame',
                desc: 'PPM-metric salience scores candidates; top-k promoted',
                value: state?.rrCycle.salienceSnapshot.coherenceField ?? 0,
                max: 1,
                color: '#06b6d4',
                detail: `Coherence field: ${pct(state?.rrCycle.salienceSnapshot.coherenceField ?? 0)}`,
              },
              {
                phase: 'C — Feed-Forward',
                desc: 'Anticipatory resonance: predict next prime cluster',
                value: state?.rrCycle.rrQuality ?? 0,
                max: 1,
                color: '#a855f7',
                detail: `Anticipated along PPM manifold`,
              },
              {
                phase: 'D — Feed-Back',
                desc: 'Coherence-driven Hebbian learning of prime-vectors',
                value: state ? Math.min(1, state.rrCycle.learningDelta * 10) : 0,
                max: 1,
                color: '#f97316',
                detail: `Learning delta: ${state?.rrCycle.learningDelta.toFixed(4) ?? '0'}`,
              },
            ].map(({ phase, desc, value, max, color, detail }) => (
              <div key={phase} className="mb-3 bg-gray-800/40 rounded-lg p-3">
                <div className="flex items-center justify-between mb-1">
                  <span className="font-semibold text-sm" style={{ color }}>{phase}</span>
                  <span className="text-xs text-gray-400">{detail}</span>
                </div>
                <p className="text-gray-400 text-xs mb-2">{desc}</p>
                <div className="bg-gray-700 rounded-full h-1.5 overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-500"
                    style={{ width: `${(value / max) * 100}%`, backgroundColor: color }}
                  />
                </div>
              </div>
            ))}
          </div>

          {/* RR Stats + PPM Prime-vector */}
          <div className="space-y-5">
            <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
              <h3 className="text-white font-bold mb-3 text-sm">Engine Statistics</h3>
              <div className="space-y-2 text-xs">
                {[
                  ['Total Cycles',       state?.rrStats.totalCycles ?? 0, '#06b6d4', false],
                  ['Avg RR Quality',     (state?.rrStats.avgRRQuality ?? 0), '#22c55e', true],
                  ['Avg Coherence',      (state?.rrStats.avgCoherence ?? 0), '#a855f7', true],
                  ['Avg Cycle Time',     ((state?.rrStats.avgCycleTimeMs ?? 0) / 10), '#f97316', true],
                  ['Explore Balance',    (state?.rrStats.currentExploreBalance ?? 0), '#eab308', true],
                ].map(([label, value, color, isPct]) => (
                  <div key={label as string} className="flex justify-between">
                    <span className="text-gray-400">{label}</span>
                    <span className="font-mono" style={{ color: color as string }}>
                      {isPct ? pct(value as number) : (value as number).toFixed(0)}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
              <h3 className="text-white font-bold mb-3 text-sm">Anticipated Prime-Vector (Phase C)</h3>
              <PrimeVectorSparkline
                vector={state?.rrCycle.anticipatedVector ?? new Float32Array(FUNDAMENTAL_PRIMES.length)}
                color="#a855f7"
              />
              <p className="text-gray-500 text-xs mt-2">
                Projection forward along PPM manifold — natural next cluster
              </p>
            </div>
          </div>
        </div>
      )}

      {/* ══════════════════ SECTION: SALIENCE LANDSCAPE ══════════════════ */}
      {activeSection === 'landscape' && (
        <div className="space-y-6">
          {/* Top-K promoted crystals */}
          <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
            <h3 className="text-white font-bold mb-4">Top-K Promoted Crystals (Conscious Window)</h3>
            {salienceSnapshot?.topK.length ? (
              <div className="space-y-2">
                {salienceSnapshot.topK.map((s, idx) => (
                  <div key={s.primitiveId} className="flex items-center space-x-3 bg-gray-800/40 rounded-lg px-3 py-2">
                    <span className="text-gray-500 font-mono text-xs w-4">{idx + 1}</span>
                    <span
                      className="text-xs font-semibold w-20"
                      style={{ color: KNOWING_COLORS[s.knowingType] }}
                    >
                      {s.knowingType.slice(0, 5).toUpperCase()}
                    </span>
                    <span className="text-gray-300 text-sm flex-1">{s.label}</span>
                    <div className="flex space-x-1 items-center">
                      <span
                        className="text-xs px-1.5 py-0.5 rounded"
                        style={{
                          backgroundColor: s.resonanceBand === 'high' ? '#166534' : s.resonanceBand === 'mid' ? '#854d0e' : '#374151',
                          color: s.resonanceBand === 'high' ? '#86efac' : s.resonanceBand === 'mid' ? '#fde68a' : '#9ca3af',
                        }}
                      >
                        {s.resonanceBand}
                      </span>
                      <span className="text-xs font-mono text-cyan-400 w-10 text-right">
                        {pct(s.score)}
                      </span>
                    </div>
                    {/* Mini component bars */}
                    <div className="flex space-x-1 text-xs text-gray-500">
                      <span title="PPM">P:{pct(s.ppmComponent, 0)}</span>
                      <span title="Phase">φ:{pct(s.phaseComponent, 0)}</span>
                      <span title="Fractal">F:{pct(s.fractalComponent, 0)}</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 text-sm">No data yet — start the engine.</p>
            )}
          </div>

          {/* Opponent processing + triplet bands */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
              <h3 className="text-white font-bold mb-4 text-sm">Opponent Processing (Ch.7)</h3>
              <div className="space-y-3">
                <Bar
                  value={salienceSnapshot?.explorationScore ?? 0}
                  color="#22c55e"
                  label="Exploration (PerspectivalCrystals)"
                />
                <Bar
                  value={salienceSnapshot?.exploitationScore ?? 0}
                  color="#06b6d4"
                  label="Exploitation (PropositionalCrystals)"
                />
                <Bar
                  value={1 - (salienceSnapshot?.opponentBalance ?? 0)}
                  color="#eab308"
                  label="Opponent Balance"
                />
              </div>
              <p className="text-gray-500 text-xs mt-3">
                Two anti-phase lattices create the explore/exploit tradeoff
              </p>
            </div>

            <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
              <h3 className="text-white font-bold mb-4 text-sm">Triplet-of-Triplet Bands (Ch.6.2.2)</h3>
              {salienceSnapshot ? (
                <TripletBandsDisplay
                  bands={salienceSnapshot.tripletBands.bands}
                  overall={salienceSnapshot.tripletBands.overallResonance}
                />
              ) : (
                <p className="text-gray-500 text-sm">No data yet.</p>
              )}
            </div>
          </div>

          {/* Knowing-type legend */}
          <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
            <h3 className="text-white font-bold mb-3 text-sm">Four Ways of Knowing (Vervaeke)</h3>
            <div className="grid grid-cols-2 gap-3">
              {(Object.entries(KNOWING_LABELS) as [KnowingType, string][]).map(([type, label]) => (
                <div key={type} className="flex items-center space-x-2 text-xs">
                  <div className="w-3 h-3 rounded-full flex-shrink-0" style={{ backgroundColor: KNOWING_COLORS[type] }} />
                  <span style={{ color: KNOWING_COLORS[type] }}>{label}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ══════════════════ SECTION: THREE ORDERS ══════════════════ */}
      {activeSection === 'orders' && (
        <div className="space-y-6">
          <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
            <h3 className="text-white font-bold mb-4 flex items-center space-x-2">
              <TrendingUp size={20} className="text-green-400" />
              <span>Three Orders of Knowing</span>
            </h3>
            <div className="space-y-4">
              {[
                {
                  label: 'Nomological — How things causally work',
                  sub: '→ RecursiveReasoningEngine (PLN causal chains)',
                  value: threeOrders?.orderScores.nomological ?? 0,
                  color: '#06b6d4',
                },
                {
                  label: 'Normative — What matters and why',
                  sub: '→ Salience Landscape / PPM-weighted attention',
                  value: threeOrders?.orderScores.normative ?? 0,
                  color: '#22c55e',
                },
                {
                  label: 'Narrative — How things develop in time',
                  sub: "→ Temporal RCP stream (agent's ongoing story)",
                  value: threeOrders?.orderScores.narrative ?? 0,
                  color: '#f97316',
                },
              ].map(({ label, sub, value, color }) => (
                <div key={label} className="bg-gray-800/40 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-semibold text-sm" style={{ color }}>{label}</span>
                    <span className="font-mono text-sm" style={{ color }}>{pct(value)}</span>
                  </div>
                  <p className="text-gray-500 text-xs mb-2">{sub}</p>
                  <div className="bg-gray-700 rounded-full h-2 overflow-hidden">
                    <div className="h-full rounded-full transition-all duration-500"
                      style={{ width: `${value * 100}%`, backgroundColor: color }} />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Cross-order coherences */}
          <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
            <h3 className="text-white font-bold mb-4 text-sm">Cross-Order Coherences</h3>
            <div className="space-y-3">
              <Bar
                value={threeOrders?.nomologicalNormativeCoherence ?? 0}
                color="#34d399"
                label="Nomological × Normative"
              />
              <Bar
                value={threeOrders?.normativeNarrativeCoherence ?? 0}
                color="#818cf8"
                label="Normative × Narrative"
              />
              <Bar
                value={threeOrders?.nomologicalNarrativeCoherence ?? 0}
                color="#fb923c"
                label="Nomological × Narrative"
              />
            </div>
            <div className="mt-4 p-4 rounded-lg" style={{
              backgroundColor: threeOrders?.meaningCrisis ? '#450a0a' : '#052e16',
              borderColor: threeOrders?.meaningCrisis ? '#7f1d1d' : '#14532d',
              border: '1px solid',
            }}>
              <div className="flex items-center justify-between">
                <span className="font-bold text-sm" style={{ color: threeOrders?.meaningCrisis ? '#ef4444' : '#22c55e' }}>
                  Meaning Score (geometric mean)
                </span>
                <span className="font-mono text-2xl font-bold" style={{ color: threeOrders?.meaningCrisis ? '#ef4444' : '#22c55e' }}>
                  {pct(threeOrders?.meaningScore ?? 0, 1)}
                </span>
              </div>
              <p className="text-gray-400 text-xs mt-2">
                {threeOrders?.meaningCrisis
                  ? '⚠ Three-order integration collapsed — meaning crisis state'
                  : '✓ All three orders co-present — coherent meaning field'}
              </p>
            </div>
          </div>

          {/* Narrative stream */}
          {threeOrders?.latestNarrativeMoment && (
            <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
              <h3 className="text-white font-bold mb-3 text-sm">Narrative Stream (Agent Identity)</h3>
              <div className="flex flex-wrap gap-2">
                {threeOrders.latestNarrativeMoment.activatedLabels.map((label, i) => (
                  <span key={i} className="text-xs px-2 py-1 rounded-full bg-gray-700/60 text-gray-300 border border-gray-600">
                    {label}
                  </span>
                ))}
              </div>
              <div className="mt-2 text-xs text-gray-500">
                Dominant: <span style={{ color: KNOWING_COLORS[threeOrders.latestNarrativeMoment.dominantKnowingType] }}>
                  {threeOrders.latestNarrativeMoment.dominantKnowingType}
                </span>
                {' · '}
                Continuity: {pct(threeOrders.latestNarrativeMoment.narrativeCoherence)}
              </div>
            </div>
          )}
        </div>
      )}

      {/* ══════════════════ SECTION: QUANTUM CHANGE ══════════════════ */}
      {activeSection === 'quantum' && (
        <div className="space-y-6">
          <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
            <h3 className="text-white font-bold mb-4 flex items-center space-x-2">
              <Sparkles size={20} className="text-purple-400" />
              <span>Quantum Change Gateway</span>
            </h3>
            <p className="text-gray-300 text-sm leading-relaxed mb-4">
              Transformative experience implemented as controlled symmetry breaking:
              when a genuinely novel pattern has no PPM precedent and cannot be
              compressed, the crystal lattice undergoes a phase transition.
              A new Participatory or Perspectival Crystal is crystallized, reorganizing
              the salience landscape. This is Vervaeke's "second-order change" grounded
              in time-crystal physics.
            </p>

            {/* Evolution stage */}
            <div className="grid grid-cols-4 gap-3 mb-4">
              {(['egg', 'larva', 'companion', 'transcendent'] as const).map(stage => (
                <div
                  key={stage}
                  className="rounded-lg p-3 text-center border transition-all"
                  style={{
                    backgroundColor: state?.evolutionStage === stage ? '#4c1d95' : '#1f2937',
                    borderColor: state?.evolutionStage === stage ? '#7c3aed' : '#374151',
                  }}
                >
                  <div className="text-xs font-bold capitalize"
                    style={{ color: state?.evolutionStage === stage ? '#c4b5fd' : '#6b7280' }}>
                    {stage}
                  </div>
                </div>
              ))}
            </div>

            {/* Latest event */}
            {qce ? (
              <div className="bg-purple-900/30 border border-purple-700 rounded-lg p-4 space-y-2">
                <div className="font-semibold text-purple-300">Latest Quantum Change Event</div>
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Trigger:</span>
                    <span className="text-purple-300">{qce.trigger}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Novelty:</span>
                    <span className="text-purple-300">{pct(qce.noveltyScore)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Incompressibility:</span>
                    <span className="text-purple-300">{pct(qce.incompressibilityScore)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">New Crystal:</span>
                    <span className="text-purple-300 truncate max-w-32">{qce.newCrystalLabel}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Pre-meaning:</span>
                    <span className="text-purple-300">{pct(qce.preMeaningScore)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Post-meaning:</span>
                    <span className="text-green-400">{pct(qce.postMeaningScore)}</span>
                  </div>
                </div>
                {qce.supersededCrystalId && (
                  <p className="text-xs text-gray-500">Superseded: {qce.supersededCrystalId}</p>
                )}
              </div>
            ) : (
              <div className="bg-gray-800/50 rounded-lg p-4 text-center">
                <p className="text-gray-500 text-sm">
                  No quantum change event this cycle.
                  <br />
                  Use "Inject Novelty" to trigger one.
                </p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ══════════════════ SECTION: SELF-DECEPTION ══════════════════ */}
      {activeSection === 'deception' && (
        <div className="space-y-6">
          <div className="bg-gray-900/60 border border-gray-700 rounded-xl p-5">
            <h3 className="text-white font-bold mb-4 flex items-center space-x-2">
              <Shield size={20} className="text-yellow-400" />
              <span>Self-Deception Detector</span>
            </h3>
            <p className="text-gray-300 text-sm leading-relaxed mb-4">
              Self-deception = <em>false phase lock</em>: the crystal lattice resonates
              internally but has drifted from the environmental signal. Measured as
              PPM divergence × internal coherence. High values trigger a correction
              that loosens the false lock by reducing STI and coherence of the most
              divergent crystals.
            </p>

            {sdReport ? (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  {[
                    { label: 'PPM Divergence', value: Math.min(1, sdReport.ppmDivergence), color: '#ef4444' },
                    { label: 'Internal Coherence', value: sdReport.internalCoherence, color: '#06b6d4' },
                    { label: 'Self-Deception Index', value: Math.min(1, sdReport.selfDeceptionIndex), color: '#f97316' },
                    { label: 'Narrative Consistency', value: sdReport.narrativeSelfConsistency, color: '#22c55e' },
                  ].map(({ label, value, color }) => (
                    <div key={label} className="bg-gray-800/40 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs text-gray-400">{label}</span>
                        <span className="font-mono font-bold" style={{ color }}>{pct(value)}</span>
                      </div>
                      <div className="bg-gray-700 rounded-full h-2 overflow-hidden">
                        <div className="h-full rounded-full transition-all duration-300"
                          style={{ width: `${value * 100}%`, backgroundColor: color }} />
                      </div>
                    </div>
                  ))}
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className={`rounded-lg p-3 border text-sm ${
                    sdReport.correctionFired
                      ? 'bg-yellow-900/30 border-yellow-600 text-yellow-300'
                      : 'bg-gray-800/40 border-gray-700 text-gray-400'
                  }`}>
                    {sdReport.correctionFired
                      ? `✓ Correction fired on ${sdReport.correctedCrystalIds.length} crystals`
                      : '✓ No correction needed'}
                  </div>
                  <div className={`rounded-lg p-3 border text-sm ${
                    sdReport.motivatedReasoning
                      ? 'bg-red-900/30 border-red-600 text-red-300'
                      : 'bg-gray-800/40 border-gray-700 text-gray-400'
                  }`}>
                    {sdReport.motivatedReasoning
                      ? '⚠ Motivated reasoning detected'
                      : '✓ No motivated reasoning'}
                  </div>
                </div>

                <div className="bg-gray-800/40 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-semibold text-white">Overall Epistemic Health</span>
                    <span className="font-mono font-bold text-lg" style={{
                      color: state!.epistemicHealth > 0.6 ? '#22c55e' : state!.epistemicHealth > 0.3 ? '#eab308' : '#ef4444'
                    }}>
                      {pct(state?.epistemicHealth ?? 0)}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500">
                    Combines alignment with environment, narrative consistency,
                    and absence of motivated reasoning.
                  </p>
                </div>
              </div>
            ) : (
              <p className="text-gray-500 text-sm">Start the engine to begin monitoring.</p>
            )}
          </div>
        </div>
      )}

      {/* ── Footer ─────────────────────────────────────────────────────── */}
      <div className="bg-gray-900/40 border border-gray-800 rounded-xl p-4 text-xs text-gray-500 space-y-1">
        <p><span className="text-cyan-500">PPM</span> = Phase Prime Metric (15 fundamental primes, Ch.3)</p>
        <p><span className="text-purple-400">RCP</span> = Relevance Crystal Primitive — fuses Vervaeke's 4 ways of knowing with time-crystal phase dynamics</p>
        <p><span className="text-green-400">Three Orders</span> = Nomological × Normative × Narrative — their geometric-mean coherence = meaning score</p>
        <p><span className="text-orange-400">Quantum Change</span> = controlled symmetry breaking triggered by genuine novelty (high incompressibility + no PPM match)</p>
        <p><span className="text-yellow-400">Self-Deception</span> = false phase lock — high divergence × high coherence; corrected by loosening STI of divergent crystals</p>
      </div>
    </div>
  );
};
