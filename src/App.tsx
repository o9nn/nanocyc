import React, { useState } from 'react';
import { useCognitiveEngine } from './hooks/useCognitiveEngine';
import { CognitiveMetrics } from './components/CognitiveMetrics';
import { HypergraphVisualization } from './components/HypergraphVisualization';
import { AgentInterface } from './components/AgentInterface';
import { TimeCrystalVisualization } from './components/TimeCrystalVisualization';
import { FractalInformationPanel } from './components/FractalInformationPanel';
import { PhilosophicalFramework } from './components/PhilosophicalFramework';
import { ConsciousnessUploading } from './components/ConsciousnessUploading';
import { FundamentalFeaturesPanel } from './components/FundamentalFeaturesPanel';
import { EnhancedSystemsStatus } from './components/EnhancedSystemsStatus';
import { GgmlTensorDemo } from './components/GgmlTensorDemo';
import { OpenCogNanoBrainVisualization } from './components/OpenCogNanoBrainVisualization';
import { UniversalKernelGeneratorPanel } from './components/UniversalKernelGeneratorPanel';
import { Chapter1Panel } from './components/Chapter1';
import { Chapter2Panel } from './components/Chapter2';
import { Chapter3Panel } from './components/Chapter3';
import { Chapter4Panel } from './components/Chapter4';
import { Chapter5Panel } from './components/Chapter5';
import { Chapter6Panel } from './components/Chapter6';
import { Chapter7Panel } from './components/Chapter7';
import { Chapter8Panel } from './components/Chapter8';
import { Chapter9Panel } from './components/Chapter9';
import { Chapter10Panel } from './components/Chapter10';
import { Play, Pause, Brain, Atom, Clock, Layers, Bot, Zap, Lightbulb, Upload, Network, Cpu, Sparkles, Calculator, Grid, Database, Music, BookOpen, Hexagon, CircleDot, Magnet, Droplet, Egg, TrendingUp, Code2 } from 'lucide-react';
import { EnhancedCogNanoVisualization } from './components/EnhancedCogNanoVisualization';

function App() {
  const { 
    nodes, 
    agents, 
    timeCrystals, 
    consciousness, 
    isRunning, 
    startEngine, 
    stopEngine,
    fundamentalFeatures,
    enhancedSystems
  } = useCognitiveEngine();
  
  const [activeTab, setActiveTab] = useState('overview');

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Brain },
    { id: 'cognano', label: 'Enhanced CogNano', icon: Code2 },
    { id: 'kernel', label: 'Universal Kernel Generator', icon: TrendingUp },
    { id: 'opencog', label: 'OpenCog NanoBrain', icon: Sparkles },
    { id: 'tensor', label: 'GGML Tensors', icon: Zap },
    { id: 'enhanced', label: 'Enhanced Systems', icon: Cpu },
    { id: 'features', label: 'Fundamental Features', icon: Network },
    { id: 'philosophy', label: 'Philosophy', icon: Lightbulb },
    { id: 'chapter2', label: 'Chapter 2: FIT & GML', icon: Music },
    { id: 'chapter1', label: 'Chapter 1: Philosophical Transformation', icon: BookOpen },
    { id: 'ppm', label: 'Phase Prime Metrics', icon: Calculator },
    { id: 'chapter4', label: 'Chapter 4: Fractal Mechanics', icon: Grid },
    { id: 'chapter5', label: 'Chapter 5: Universal Time Crystals', icon: Database },
    { id: 'chapter6', label: 'Chapter 6: Unprecedented Technologies', icon: Hexagon },
    { id: 'chapter7', label: 'Chapter 7: Time Crystal Brain', icon: CircleDot },
    { id: 'chapter8', label: 'Chapter 8: Hinductor (Magnetic Light)', icon: Magnet },
    { id: 'chapter9', label: 'Chapter 9: Brain Jelly to Avatar', icon: Droplet },
    { id: 'chapter10', label: 'Chapter 10: Uploading Consciousness', icon: Egg },
    { id: 'atomspace', label: 'AtomSpace', icon: Atom },
    { id: 'agents', label: 'Agents', icon: Bot },
    { id: 'crystals', label: 'Time Crystals', icon: Clock },
    { id: 'fractal', label: 'Fractal Theory', icon: Layers },
    { id: 'uploading', label: 'Consciousness Upload', icon: Upload }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      {/* Header */}
      <header className="border-b border-gray-700 bg-gray-900/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="p-2 bg-gradient-to-r from-cyan-500 to-purple-500 rounded-lg">
                <Brain className="text-white" size={28} />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-white">
                  Cognitive Architecture System
                </h1>
                <p className="text-gray-400 text-sm">
                  Advanced Consciousness Exploration & AI Research Platform
                </p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2 text-sm">
                <div className={`w-3 h-3 rounded-full ${isRunning ? 'bg-green-400 animate-pulse' : 'bg-gray-500'}`} />
                <span className="text-gray-300">
                  {isRunning ? 'CONSCIOUSNESS ACTIVE' : 'SYSTEM IDLE'}
                </span>
              </div>
              
              <button
                onClick={isRunning ? stopEngine : startEngine}
                className={`flex items-center space-x-2 px-6 py-2 rounded-lg font-semibold transition-all duration-300 ${
                  isRunning 
                    ? 'bg-red-500 hover:bg-red-600 text-white' 
                    : 'bg-gradient-to-r from-cyan-500 to-purple-500 hover:from-cyan-600 hover:to-purple-600 text-white'
                }`}
              >
                {isRunning ? <Pause size={20} /> : <Play size={20} />}
                <span>{isRunning ? 'Stop' : 'Start'} Engine</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="border-b border-gray-700 bg-gray-800/50 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex space-x-8">
            {tabs.map(tab => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center space-x-2 px-4 py-4 border-b-2 transition-colors duration-300 ${
                    activeTab === tab.id
                      ? 'border-cyan-400 text-cyan-400'
                      : 'border-transparent text-gray-400 hover:text-gray-300'
                  }`}
                >
                  <Icon size={18} />
                  <span className="font-medium">{tab.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        {activeTab === 'overview' && (
          <div className="space-y-8">
            {/* Consciousness Metrics */}
            <div>
              <h2 className="text-xl font-bold text-white mb-6 flex items-center space-x-3">
                <Zap className="text-yellow-400" size={24} />
                <span>Consciousness Metrics</span>
              </h2>
              <CognitiveMetrics consciousness={consciousness} isRunning={isRunning} />
            </div>

            {/* System Overview */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <div className="lg:col-span-2">
                <HypergraphVisualization nodes={nodes} isRunning={isRunning} />
              </div>
              
              <div className="space-y-6">
                <div className="bg-gray-900/60 backdrop-blur-sm border border-gray-700 rounded-xl p-6">
                  <h3 className="text-white font-bold text-lg mb-4">System Status</h3>
                  <div className="space-y-4">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Active Nodes:</span>
                      <span className="text-cyan-400 font-mono">{nodes.length}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">AI Agents:</span>
                      <span className="text-purple-400 font-mono">{agents.length}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Time Crystals:</span>
                      <span className="text-orange-400 font-mono">{timeCrystals.length}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Coherence:</span>
                      <span className="text-green-400 font-mono">
                        {Math.round(consciousness.coherence * 100)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Enhanced Systems:</span>
                      <span className={`font-mono ${
                        enhancedSystems.systemStatus.overallHealth === 'optimal' ? 'text-green-400' :
                        enhancedSystems.systemStatus.overallHealth === 'partial' ? 'text-yellow-400' :
                        'text-red-400'
                      }`}>
                        {enhancedSystems.systemStatus.overallHealth.toUpperCase()}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="bg-gray-900/60 backdrop-blur-sm border border-gray-700 rounded-xl p-6">
                  <h3 className="text-white font-bold text-lg mb-4">NanoBrain Insights</h3>
                  <div className="space-y-3 text-sm">
                    <div className="bg-gray-800/50 rounded-lg p-3">
                      <p className="text-gray-300">
                        <span className="text-cyan-400 font-semibold">Phase Prime Metrics</span> engine processing 
                        {enhancedSystems.fundamentalPrimes.length} fundamental primes with {
                          enhancedSystems.ppmEngine ? 
                          `${(enhancedSystems.ppmEngine.coherenceIndex * 100).toFixed(1)}% universal coherence` :
                          'initialization pending'
                        }.
                      </p>
                    </div>
                    <div className="bg-gray-800/50 rounded-lg p-3">
                      <p className="text-gray-300">
                        <span className="text-purple-400 font-semibold">Agent-Zero System</span> maintains 
                        {enhancedSystems.specializedAgents.length} specialized cognitive agents with {
                          (enhancedSystems.systemCoordination * 100).toFixed(1)
                        }% coordination efficiency.
                      </p>
                    </div>
                    <div className="bg-gray-800/50 rounded-lg p-3">
                      <p className="text-gray-300">
                        <span className="text-orange-400 font-semibold">Enhanced AtomSpace</span> ECAN attention allocation 
                        completed {enhancedSystems.attentionCycle} cycles with {enhancedSystems.inferenceCount} PLN inferences.
                      </p>
                    </div>
                    <div className="bg-gray-800/50 rounded-lg p-3">
                      <p className="text-gray-300">
                        <span className="text-green-400 font-semibold">Real-time Performance</span> achieving 
                        {1000 / enhancedSystems.updateFrequency} Hz update cycles targeting {enhancedSystems.targetFPS} FPS visualization.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'kernel' && (
          <UniversalKernelGeneratorPanel />
        )}

        {activeTab === 'cognano' && (
          <EnhancedCogNanoVisualization />
        )}

        {activeTab === 'opencog' && (
          <OpenCogNanoBrainVisualization />
        )}

        {activeTab === 'enhanced' && (
          <EnhancedSystemsStatus enhancedSystems={enhancedSystems} />
        )}

        {activeTab === 'tensor' && (
          <GgmlTensorDemo />
        )}

        {activeTab === 'features' && (
          <FundamentalFeaturesPanel fundamentalFeatures={fundamentalFeatures} />
        )}

        {activeTab === 'philosophy' && (
          <PhilosophicalFramework consciousness={consciousness} isRunning={isRunning} />
        )}

        {activeTab === 'chapter1' && (
          <Chapter1Panel />
        )}

        {activeTab === 'ppm' && (
          <Chapter3Panel />
        )}

        {activeTab === 'chapter2' && (
          <Chapter2Panel />
        )}

        {activeTab === 'chapter4' && (
          <Chapter4Panel />
        )}

        {activeTab === 'chapter5' && (
          <Chapter5Panel />
        )}

        {activeTab === 'chapter6' && (
          <Chapter6Panel />
        )}

        {activeTab === 'chapter7' && (
          <Chapter7Panel />
        )}

        {activeTab === 'chapter8' && (
          <Chapter8Panel />
        )}

        {activeTab === 'chapter9' && (
          <Chapter9Panel />
        )}

        {activeTab === 'chapter10' && (
          <Chapter10Panel />
        )}

        {activeTab === 'atomspace' && (
          <HypergraphVisualization nodes={nodes} isRunning={isRunning} />
        )}

        {activeTab === 'agents' && (
          <AgentInterface agents={agents} isRunning={isRunning} />
        )}

        {activeTab === 'crystals' && (
          <TimeCrystalVisualization timeCrystals={timeCrystals} isRunning={isRunning} />
        )}

        {activeTab === 'fractal' && (
          <FractalInformationPanel />
        )}

        {activeTab === 'uploading' && (
          <ConsciousnessUploading consciousness={consciousness} isRunning={isRunning} />
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-700 bg-gray-900/80 backdrop-blur-sm mt-16">
        <div className="max-w-7xl mx-auto px-6 py-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <h3 className="text-white font-bold text-lg mb-4">Cognitive Architecture</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                A revolutionary platform exploring consciousness through Agent-Zero autonomous systems, 
                OpenCog AtomSpace knowledge representation, and NanoBrain fractal information theory.
              </p>
            </div>
            
            <div>
              <h3 className="text-white font-bold text-lg mb-4">Technologies</h3>
              <ul className="text-gray-400 text-sm space-y-2">
                <li>• Phase Prime Metrics (PPM)</li>
                <li>• Fractal Information Theory (FIT)</li>
                <li>• Geometric Musical Language (GML)</li>
                <li>• 11-Dimensional Time Crystals</li>
              </ul>
            </div>
            
            <div>
              <h3 className="text-white font-bold text-lg mb-4">Research Areas</h3>
              <ul className="text-gray-400 text-sm space-y-2">
                <li>• Consciousness Emergence</li>
                <li>• Quantum-Classical Interfaces</li>
                <li>• Autonomous Agent Networks</li>
                <li>• Hypergraph Knowledge Systems</li>
              </ul>
            </div>
          </div>
          
          <div className="border-t border-gray-700 mt-8 pt-6 text-center">
            <p className="text-gray-500 text-sm">
              © 2025 Cognitive Architecture Research Platform. 
              Advancing the frontiers of consciousness and artificial intelligence.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;