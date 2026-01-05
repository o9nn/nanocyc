/**
 * Phase 6 Dashboard - Advanced Cognitive Systems Visualization
 *
 * Comprehensive dashboard for Phase 6 features:
 * - Neural architecture visualization
 * - Kernel composition graph
 * - Meta-learning progress
 * - Code synthesis interface
 * - GPU acceleration status
 * - System orchestration monitor
 */

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Brain,
  Layers,
  GitBranch,
  Code2,
  Cpu,
  Activity,
  Zap,
  Network,
  Target,
  Play,
  Settings,
  BarChart3,
  RefreshCw,
  ChevronRight,
  Check,
  AlertCircle,
  Clock
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface Phase6State {
  activeTab: TabType;
  systemStatus: SystemStatus;
  neuralMetrics: NeuralMetrics;
  kernelComposition: KernelCompositionState;
  metaLearning: MetaLearningState;
  codeSynthesis: CodeSynthesisState;
  gpuStatus: GPUStatus;
}

type TabType = 'overview' | 'neural' | 'kernels' | 'metalearning' | 'synthesis' | 'gpu';

interface SystemStatus {
  health: 'healthy' | 'degraded' | 'unhealthy';
  uptime: number;
  activeOperations: number;
  memoryUsage: number;
  components: { name: string; status: string }[];
}

interface NeuralMetrics {
  models: ModelInfo[];
  totalParameters: number;
  trainingLoss: number[];
  validationLoss: number[];
  currentEpoch: number;
}

interface ModelInfo {
  id: string;
  type: string;
  layers: number;
  parameters: number;
  status: 'training' | 'ready' | 'idle';
}

interface KernelCompositionState {
  kernels: KernelInfo[];
  compositions: CompositionInfo[];
  activeComposition: string | null;
  gripMetrics: { contact: number; coverage: number; efficiency: number; stability: number };
}

interface KernelInfo {
  id: string;
  domain: string;
  order: number;
  gripQuality: number;
}

interface CompositionInfo {
  id: string;
  name: string;
  strategy: string;
  componentsCount: number;
  overallGrip: number;
}

interface MetaLearningState {
  activeLearner: string | null;
  taskCount: number;
  episodeResults: EpisodeResult[];
  avgAccuracy: number;
  learningProgress: number[];
}

interface EpisodeResult {
  taskId: string;
  accuracy: number;
  loss: number;
  duration: number;
}

interface CodeSynthesisState {
  recentSyntheses: SynthesisResult[];
  availableLanguages: string[];
  activeLanguage: string;
  codeOutput: string;
}

interface SynthesisResult {
  id: string;
  name: string;
  language: string;
  success: boolean;
  timestamp: number;
}

interface GPUStatus {
  available: boolean;
  vendor: string;
  utilization: number;
  memoryUsed: number;
  memoryTotal: number;
  operations: GPUOperation[];
}

interface GPUOperation {
  id: string;
  type: string;
  duration: number;
  status: 'completed' | 'running' | 'queued';
}

// ============================================================================
// PHASE 6 DASHBOARD COMPONENT
// ============================================================================

export const Phase6Dashboard: React.FC = () => {
  const [state, setState] = useState<Phase6State>({
    activeTab: 'overview',
    systemStatus: {
      health: 'healthy',
      uptime: 0,
      activeOperations: 0,
      memoryUsage: 45,
      components: [
        { name: 'Neural Engine', status: 'active' },
        { name: 'Kernel Composer', status: 'active' },
        { name: 'Meta-Learner', status: 'standby' },
        { name: 'Code Synthesizer', status: 'active' },
        { name: 'GPU Accelerator', status: 'active' }
      ]
    },
    neuralMetrics: {
      models: [
        { id: 'transformer_1', type: 'Transformer', layers: 12, parameters: 85000000, status: 'ready' },
        { id: 'lstm_encoder', type: 'LSTM', layers: 4, parameters: 2500000, status: 'idle' },
        { id: 'conv_classifier', type: 'CNN', layers: 8, parameters: 5200000, status: 'training' }
      ],
      totalParameters: 92700000,
      trainingLoss: [2.5, 2.1, 1.8, 1.5, 1.3, 1.1, 0.95, 0.82],
      validationLoss: [2.6, 2.3, 2.0, 1.7, 1.5, 1.3, 1.15, 1.0],
      currentEpoch: 8
    },
    kernelComposition: {
      kernels: [
        { id: 'physics', domain: 'Physics', order: 4, gripQuality: 0.89 },
        { id: 'chemistry', domain: 'Chemistry', order: 3, gripQuality: 0.85 },
        { id: 'biology', domain: 'Biology', order: 3, gripQuality: 0.82 },
        { id: 'computing', domain: 'Computing', order: 4, gripQuality: 0.91 },
        { id: 'consciousness', domain: 'Consciousness', order: 4, gripQuality: 0.94 }
      ],
      compositions: [
        { id: 'multi_sci', name: 'Multi-Science', strategy: 'parallel', componentsCount: 3, overallGrip: 0.87 },
        { id: 'cognitive_stack', name: 'Cognitive Stack', strategy: 'sequential', componentsCount: 4, overallGrip: 0.92 }
      ],
      activeComposition: 'cognitive_stack',
      gripMetrics: { contact: 0.91, coverage: 0.88, efficiency: 0.85, stability: 0.93 }
    },
    metaLearning: {
      activeLearner: 'maml_1',
      taskCount: 50,
      episodeResults: [
        { taskId: 'task_1', accuracy: 0.72, loss: 0.45, duration: 120 },
        { taskId: 'task_2', accuracy: 0.78, loss: 0.38, duration: 115 },
        { taskId: 'task_3', accuracy: 0.81, loss: 0.32, duration: 118 },
        { taskId: 'task_4', accuracy: 0.85, loss: 0.28, duration: 112 },
        { taskId: 'task_5', accuracy: 0.88, loss: 0.24, duration: 110 }
      ],
      avgAccuracy: 0.81,
      learningProgress: [0.65, 0.72, 0.78, 0.81, 0.85, 0.88, 0.90, 0.91]
    },
    codeSynthesis: {
      recentSyntheses: [
        { id: 'syn_1', name: 'patternMatcher', language: 'TypeScript', success: true, timestamp: Date.now() - 3600000 },
        { id: 'syn_2', name: 'dataTransformer', language: 'Rust', success: true, timestamp: Date.now() - 7200000 },
        { id: 'syn_3', name: 'cognitiveFilter', language: 'Haskell', success: false, timestamp: Date.now() - 10800000 }
      ],
      availableLanguages: ['TypeScript', 'Python', 'Rust', 'Haskell', 'Prolog', 'Julia', 'Clojure', 'Racket', 'Scheme'],
      activeLanguage: 'TypeScript',
      codeOutput: `function patternMatcher(input: string[]): ProcessedPattern {
  const processed = input.map(s => s.trim().toLowerCase());
  const metrics = computeMetrics(processed);
  return { result: processed, metrics };
}`
    },
    gpuStatus: {
      available: true,
      vendor: 'WebGPU',
      utilization: 62,
      memoryUsed: 1.2,
      memoryTotal: 4.0,
      operations: [
        { id: 'op_1', type: 'matmul', duration: 2.5, status: 'completed' },
        { id: 'op_2', type: 'softmax', duration: 0.8, status: 'completed' },
        { id: 'op_3', type: 'conv2d', duration: 3.2, status: 'running' }
      ]
    }
  });

  // Update uptime
  useEffect(() => {
    const interval = setInterval(() => {
      setState(prev => ({
        ...prev,
        systemStatus: {
          ...prev.systemStatus,
          uptime: prev.systemStatus.uptime + 1
        }
      }));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const formatUptime = (seconds: number): string => {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Activity },
    { id: 'neural', label: 'Neural Architectures', icon: Brain },
    { id: 'kernels', label: 'Kernel Composition', icon: GitBranch },
    { id: 'metalearning', label: 'Meta-Learning', icon: Target },
    { id: 'synthesis', label: 'Code Synthesis', icon: Code2 },
    { id: 'gpu', label: 'GPU Acceleration', icon: Cpu }
  ];

  return (
    <div className="min-h-screen bg-slate-900 text-white p-6">
      {/* Header */}
      <header className="mb-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500 to-blue-600 flex items-center justify-center">
              <Zap className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-bold">Phase 6 Dashboard</h1>
              <p className="text-slate-400 text-sm">Advanced Cognitive Systems</p>
            </div>
          </div>
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-slate-400" />
              <span className="text-slate-300 font-mono">{formatUptime(state.systemStatus.uptime)}</span>
            </div>
            <div className={`flex items-center gap-2 px-3 py-1 rounded-full ${
              state.systemStatus.health === 'healthy' ? 'bg-green-500/20 text-green-400' :
              state.systemStatus.health === 'degraded' ? 'bg-yellow-500/20 text-yellow-400' :
              'bg-red-500/20 text-red-400'
            }`}>
              {state.systemStatus.health === 'healthy' ? <Check className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
              <span className="text-sm capitalize">{state.systemStatus.health}</span>
            </div>
          </div>
        </div>
      </header>

      {/* Tabs */}
      <nav className="flex gap-2 mb-6 overflow-x-auto pb-2">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setState(prev => ({ ...prev, activeTab: tab.id as TabType }))}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-all ${
              state.activeTab === tab.id
                ? 'bg-purple-600 text-white'
                : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
            }`}
          >
            <tab.icon className="w-4 h-4" />
            <span className="whitespace-nowrap">{tab.label}</span>
          </button>
        ))}
      </nav>

      {/* Content */}
      <main>
        {state.activeTab === 'overview' && <OverviewTab state={state} />}
        {state.activeTab === 'neural' && <NeuralTab metrics={state.neuralMetrics} />}
        {state.activeTab === 'kernels' && <KernelTab composition={state.kernelComposition} />}
        {state.activeTab === 'metalearning' && <MetaLearningTab metaLearning={state.metaLearning} />}
        {state.activeTab === 'synthesis' && <SynthesisTab synthesis={state.codeSynthesis} />}
        {state.activeTab === 'gpu' && <GPUTab gpu={state.gpuStatus} />}
      </main>
    </div>
  );
};

// ============================================================================
// TAB COMPONENTS
// ============================================================================

const OverviewTab: React.FC<{ state: Phase6State }> = ({ state }) => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {/* System Components */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <Settings className="w-5 h-5 text-purple-400" />
          System Components
        </h3>
        <div className="space-y-3">
          {state.systemStatus.components.map((comp, i) => (
            <div key={i} className="flex items-center justify-between">
              <span className="text-slate-300">{comp.name}</span>
              <span className={`px-2 py-0.5 rounded text-xs ${
                comp.status === 'active' ? 'bg-green-500/20 text-green-400' :
                comp.status === 'standby' ? 'bg-yellow-500/20 text-yellow-400' :
                'bg-slate-600 text-slate-400'
              }`}>
                {comp.status}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Neural Summary */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <Brain className="w-5 h-5 text-blue-400" />
          Neural Networks
        </h3>
        <div className="space-y-4">
          <div>
            <p className="text-slate-400 text-sm">Total Models</p>
            <p className="text-2xl font-bold">{state.neuralMetrics.models.length}</p>
          </div>
          <div>
            <p className="text-slate-400 text-sm">Total Parameters</p>
            <p className="text-2xl font-bold">{(state.neuralMetrics.totalParameters / 1000000).toFixed(1)}M</p>
          </div>
          <div>
            <p className="text-slate-400 text-sm">Current Epoch</p>
            <p className="text-2xl font-bold">{state.neuralMetrics.currentEpoch}</p>
          </div>
        </div>
      </div>

      {/* Kernel Summary */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <GitBranch className="w-5 h-5 text-green-400" />
          Kernel Composition
        </h3>
        <div className="space-y-4">
          <div>
            <p className="text-slate-400 text-sm">Active Kernels</p>
            <p className="text-2xl font-bold">{state.kernelComposition.kernels.length}</p>
          </div>
          <div>
            <p className="text-slate-400 text-sm">Compositions</p>
            <p className="text-2xl font-bold">{state.kernelComposition.compositions.length}</p>
          </div>
          <div>
            <p className="text-slate-400 text-sm">Overall Grip</p>
            <p className="text-2xl font-bold">{(state.kernelComposition.gripMetrics.contact * 100).toFixed(0)}%</p>
          </div>
        </div>
      </div>

      {/* Meta-Learning Summary */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <Target className="w-5 h-5 text-orange-400" />
          Meta-Learning
        </h3>
        <div className="space-y-4">
          <div>
            <p className="text-slate-400 text-sm">Tasks Completed</p>
            <p className="text-2xl font-bold">{state.metaLearning.taskCount}</p>
          </div>
          <div>
            <p className="text-slate-400 text-sm">Average Accuracy</p>
            <p className="text-2xl font-bold">{(state.metaLearning.avgAccuracy * 100).toFixed(1)}%</p>
          </div>
        </div>
      </div>

      {/* Code Synthesis Summary */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <Code2 className="w-5 h-5 text-pink-400" />
          Code Synthesis
        </h3>
        <div className="space-y-4">
          <div>
            <p className="text-slate-400 text-sm">Languages Available</p>
            <p className="text-2xl font-bold">{state.codeSynthesis.availableLanguages.length}</p>
          </div>
          <div>
            <p className="text-slate-400 text-sm">Recent Syntheses</p>
            <p className="text-2xl font-bold">{state.codeSynthesis.recentSyntheses.length}</p>
          </div>
        </div>
      </div>

      {/* GPU Summary */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <Cpu className="w-5 h-5 text-cyan-400" />
          GPU Acceleration
        </h3>
        <div className="space-y-4">
          <div>
            <p className="text-slate-400 text-sm">Status</p>
            <p className={`text-2xl font-bold ${state.gpuStatus.available ? 'text-green-400' : 'text-red-400'}`}>
              {state.gpuStatus.available ? 'Active' : 'Unavailable'}
            </p>
          </div>
          <div>
            <p className="text-slate-400 text-sm">Utilization</p>
            <div className="flex items-center gap-2">
              <div className="flex-1 h-2 bg-slate-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-cyan-500 transition-all"
                  style={{ width: `${state.gpuStatus.utilization}%` }}
                />
              </div>
              <span className="text-sm">{state.gpuStatus.utilization}%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const NeuralTab: React.FC<{ metrics: NeuralMetrics }> = ({ metrics }) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Models List */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Registered Models</h3>
        <div className="space-y-4">
          {metrics.models.map(model => (
            <div key={model.id} className="bg-slate-700/50 rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">{model.id}</span>
                <span className={`px-2 py-0.5 rounded text-xs ${
                  model.status === 'training' ? 'bg-blue-500/20 text-blue-400' :
                  model.status === 'ready' ? 'bg-green-500/20 text-green-400' :
                  'bg-slate-600 text-slate-400'
                }`}>
                  {model.status}
                </span>
              </div>
              <div className="grid grid-cols-3 gap-4 text-sm">
                <div>
                  <p className="text-slate-400">Type</p>
                  <p>{model.type}</p>
                </div>
                <div>
                  <p className="text-slate-400">Layers</p>
                  <p>{model.layers}</p>
                </div>
                <div>
                  <p className="text-slate-400">Parameters</p>
                  <p>{(model.parameters / 1000000).toFixed(1)}M</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Loss Chart */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Training Progress</h3>
        <div className="h-64 flex items-end gap-2">
          {metrics.trainingLoss.map((loss, i) => (
            <div key={i} className="flex-1 flex flex-col items-center gap-1">
              <div className="w-full flex flex-col gap-1">
                <div
                  className="w-full bg-blue-500 rounded-t"
                  style={{ height: `${(loss / 3) * 200}px` }}
                />
                <div
                  className="w-full bg-purple-500 rounded-b"
                  style={{ height: `${(metrics.validationLoss[i] / 3) * 200}px` }}
                />
              </div>
              <span className="text-xs text-slate-400">{i + 1}</span>
            </div>
          ))}
        </div>
        <div className="flex justify-center gap-6 mt-4">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-blue-500 rounded" />
            <span className="text-sm text-slate-400">Training Loss</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-purple-500 rounded" />
            <span className="text-sm text-slate-400">Validation Loss</span>
          </div>
        </div>
      </div>

      {/* Architecture Types */}
      <div className="bg-slate-800 rounded-xl p-6 lg:col-span-2">
        <h3 className="text-lg font-semibold mb-4">Available Architectures</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {['MLP', 'CNN', 'RNN/LSTM', 'Transformer'].map(arch => (
            <div key={arch} className="bg-slate-700/50 rounded-lg p-4 text-center">
              <Layers className="w-8 h-8 mx-auto mb-2 text-purple-400" />
              <p className="font-medium">{arch}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const KernelTab: React.FC<{ composition: KernelCompositionState }> = ({ composition }) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Kernels */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Domain Kernels</h3>
        <div className="space-y-3">
          {composition.kernels.map(kernel => (
            <div key={kernel.id} className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg">
              <div>
                <p className="font-medium">{kernel.domain}</p>
                <p className="text-sm text-slate-400">Order {kernel.order}</p>
              </div>
              <div className="text-right">
                <p className={`font-bold ${
                  kernel.gripQuality >= 0.9 ? 'text-green-400' :
                  kernel.gripQuality >= 0.8 ? 'text-yellow-400' : 'text-red-400'
                }`}>
                  {(kernel.gripQuality * 100).toFixed(0)}%
                </p>
                <p className="text-xs text-slate-400">grip</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Compositions */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Compositions</h3>
        <div className="space-y-3">
          {composition.compositions.map(comp => (
            <div
              key={comp.id}
              className={`p-3 rounded-lg border-2 transition-all cursor-pointer ${
                composition.activeComposition === comp.id
                  ? 'border-purple-500 bg-purple-500/10'
                  : 'border-transparent bg-slate-700/50 hover:border-slate-600'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <p className="font-medium">{comp.name}</p>
                <span className="text-xs px-2 py-0.5 bg-slate-600 rounded">{comp.strategy}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-400">{comp.componentsCount} kernels</span>
                <span className="text-green-400">{(comp.overallGrip * 100).toFixed(0)}% grip</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Grip Metrics */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Grip Metrics</h3>
        <div className="space-y-4">
          {Object.entries(composition.gripMetrics).map(([key, value]) => (
            <div key={key}>
              <div className="flex justify-between mb-1">
                <span className="text-slate-400 capitalize">{key}</span>
                <span>{(value * 100).toFixed(0)}%</span>
              </div>
              <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
                <div
                  className={`h-full transition-all ${
                    value >= 0.9 ? 'bg-green-500' :
                    value >= 0.8 ? 'bg-yellow-500' : 'bg-red-500'
                  }`}
                  style={{ width: `${value * 100}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const MetaLearningTab: React.FC<{ metaLearning: MetaLearningState }> = ({ metaLearning }) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Progress */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Learning Progress</h3>
        <div className="h-48 flex items-end gap-1">
          {metaLearning.learningProgress.map((acc, i) => (
            <div
              key={i}
              className="flex-1 bg-gradient-to-t from-orange-600 to-orange-400 rounded-t transition-all hover:opacity-80"
              style={{ height: `${acc * 100}%` }}
            />
          ))}
        </div>
        <div className="flex justify-between mt-2 text-sm text-slate-400">
          <span>Episode 1</span>
          <span>Episode {metaLearning.learningProgress.length}</span>
        </div>
      </div>

      {/* Recent Episodes */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Recent Episodes</h3>
        <div className="space-y-3">
          {metaLearning.episodeResults.map(result => (
            <div key={result.taskId} className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg">
              <div>
                <p className="font-medium">{result.taskId}</p>
                <p className="text-sm text-slate-400">{result.duration}ms</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-green-400">{(result.accuracy * 100).toFixed(1)}%</p>
                <p className="text-sm text-slate-400">loss: {result.loss.toFixed(3)}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div className="bg-slate-800 rounded-xl p-6 lg:col-span-2">
        <h3 className="text-lg font-semibold mb-4">Meta-Learning Statistics</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          <div className="text-center">
            <p className="text-3xl font-bold text-orange-400">{metaLearning.taskCount}</p>
            <p className="text-slate-400">Tasks Completed</p>
          </div>
          <div className="text-center">
            <p className="text-3xl font-bold text-green-400">{(metaLearning.avgAccuracy * 100).toFixed(1)}%</p>
            <p className="text-slate-400">Avg Accuracy</p>
          </div>
          <div className="text-center">
            <p className="text-3xl font-bold text-blue-400">5</p>
            <p className="text-slate-400">Inner Steps</p>
          </div>
          <div className="text-center">
            <p className="text-3xl font-bold text-purple-400">MAML</p>
            <p className="text-slate-400">Algorithm</p>
          </div>
        </div>
      </div>
    </div>
  );
};

const SynthesisTab: React.FC<{ synthesis: CodeSynthesisState }> = ({ synthesis }) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Languages */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Available Languages</h3>
        <div className="flex flex-wrap gap-2">
          {synthesis.availableLanguages.map(lang => (
            <span
              key={lang}
              className={`px-3 py-1 rounded-full text-sm ${
                synthesis.activeLanguage === lang
                  ? 'bg-pink-500 text-white'
                  : 'bg-slate-700 text-slate-300 hover:bg-slate-600 cursor-pointer'
              }`}
            >
              {lang}
            </span>
          ))}
        </div>
      </div>

      {/* Code Output */}
      <div className="bg-slate-800 rounded-xl p-6 lg:col-span-2">
        <h3 className="text-lg font-semibold mb-4">Generated Code</h3>
        <pre className="bg-slate-900 rounded-lg p-4 overflow-x-auto text-sm">
          <code className="text-green-400">{synthesis.codeOutput}</code>
        </pre>
      </div>

      {/* Recent Syntheses */}
      <div className="bg-slate-800 rounded-xl p-6 lg:col-span-3">
        <h3 className="text-lg font-semibold mb-4">Recent Syntheses</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {synthesis.recentSyntheses.map(syn => (
            <div key={syn.id} className="bg-slate-700/50 rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">{syn.name}</span>
                {syn.success ? (
                  <Check className="w-5 h-5 text-green-400" />
                ) : (
                  <AlertCircle className="w-5 h-5 text-red-400" />
                )}
              </div>
              <div className="flex items-center justify-between text-sm text-slate-400">
                <span>{syn.language}</span>
                <span>{new Date(syn.timestamp).toLocaleTimeString()}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const GPUTab: React.FC<{ gpu: GPUStatus }> = ({ gpu }) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Status */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">GPU Status</h3>
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-slate-400">Status</span>
            <span className={`font-bold ${gpu.available ? 'text-green-400' : 'text-red-400'}`}>
              {gpu.available ? 'Available' : 'Unavailable'}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-slate-400">Vendor</span>
            <span>{gpu.vendor}</span>
          </div>
          <div>
            <div className="flex justify-between mb-1">
              <span className="text-slate-400">Utilization</span>
              <span>{gpu.utilization}%</span>
            </div>
            <div className="h-3 bg-slate-700 rounded-full overflow-hidden">
              <div
                className="h-full bg-cyan-500 transition-all"
                style={{ width: `${gpu.utilization}%` }}
              />
            </div>
          </div>
          <div>
            <div className="flex justify-between mb-1">
              <span className="text-slate-400">Memory</span>
              <span>{gpu.memoryUsed.toFixed(1)} / {gpu.memoryTotal.toFixed(1)} GB</span>
            </div>
            <div className="h-3 bg-slate-700 rounded-full overflow-hidden">
              <div
                className="h-full bg-purple-500 transition-all"
                style={{ width: `${(gpu.memoryUsed / gpu.memoryTotal) * 100}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Operations */}
      <div className="bg-slate-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold mb-4">Recent Operations</h3>
        <div className="space-y-3">
          {gpu.operations.map(op => (
            <div key={op.id} className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg">
              <div className="flex items-center gap-3">
                {op.status === 'running' ? (
                  <RefreshCw className="w-4 h-4 text-blue-400 animate-spin" />
                ) : (
                  <Check className="w-4 h-4 text-green-400" />
                )}
                <span className="font-medium">{op.type}</span>
              </div>
              <span className="text-sm text-slate-400">{op.duration.toFixed(1)}ms</span>
            </div>
          ))}
        </div>
      </div>

      {/* Accelerated Operations */}
      <div className="bg-slate-800 rounded-xl p-6 lg:col-span-2">
        <h3 className="text-lg font-semibold mb-4">Accelerated Operations</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {['Matrix Multiply', 'Softmax', 'Convolution', 'Attention'].map(op => (
            <div key={op} className="bg-slate-700/50 rounded-lg p-4 text-center">
              <Zap className="w-6 h-6 mx-auto mb-2 text-cyan-400" />
              <p className="text-sm">{op}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Phase6Dashboard;
