/**
 * Enhanced CogNano Visualization Component
 * 
 * Displays real-time learnability metrics and cognitive transformation results
 */

import React, { useState, useEffect } from 'react';
import { Brain, Zap, Code, TrendingUp, Activity } from 'lucide-react';
import { 
  createEnhancedCogNanoAgent,
  EnhancedCogNanoAgent
} from '../core/EnhancedCogNanoAgent';
import { ExampleCognitiveIdeas } from '../core/CognitiveGripFabric';

interface EnhancedCogNanoVisualizationProps {
  className?: string;
}

export const EnhancedCogNanoVisualization: React.FC<EnhancedCogNanoVisualizationProps> = ({ 
  className = '' 
}) => {
  const [agent, setAgent] = useState<EnhancedCogNanoAgent | null>(null);
  const [isTraining, setIsTraining] = useState(false);
  const [isTransforming, setIsTransforming] = useState(false);
  const [trainingStep, setTrainingStep] = useState(0);
  const [currentLoss, setCurrentLoss] = useState(0);
  const [transformationCount, setTransformationCount] = useState(0);
  const [activeLanguage, setActiveLanguage] = useState('Racket');

  // Initialize agent
  useEffect(() => {
    const newAgent = createEnhancedCogNanoAgent('default');
    setAgent(newAgent);
  }, []);

  // Training loop
  const startTraining = () => {
    if (!agent || isTraining) return;
    
    setIsTraining(true);
    
    const trainLoop = setInterval(() => {
      // Generate random patterns
      const inputPattern = new Float32Array(64).fill(0).map(() => Math.random());
      const targetPattern = new Float32Array(32).fill(0).map(() => Math.random());
      
      const loss = agent.trainOnPattern(inputPattern, targetPattern);
      
      setCurrentLoss(loss);
      setTrainingStep(prev => prev + 1);
      
      // Stop after 20 steps
      if (trainingStep >= 19) {
        clearInterval(trainLoop);
        setIsTraining(false);
      }
    }, 200);
  };

  // Transformation demo
  const startTransformation = async () => {
    if (!agent || isTransforming) return;
    
    setIsTransforming(true);
    
    const ideas = Object.values(ExampleCognitiveIdeas);
    
    for (const idea of ideas) {
      const result = agent.transformCognitiveIdea(idea);
      setActiveLanguage(result.selected_language);
      setTransformationCount(prev => prev + 1);
      
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    setIsTransforming(false);
  };

  const metrics = agent?.getLearnabilityMetrics();
  const state = agent?.getState();

  return (
    <div className={`bg-gray-900 rounded-xl p-6 border border-cyan-500/30 ${className}`}>
      <div className="flex items-center gap-3 mb-6">
        <Brain className="w-8 h-8 text-cyan-400" />
        <div>
          <h2 className="text-2xl font-bold text-cyan-400">Enhanced CogNano Agent</h2>
          <p className="text-sm text-gray-400">Learnability Embeddings + Cognitive Grip Fabric</p>
        </div>
      </div>

      {/* Status Bar */}
      <div className="bg-gray-800 rounded-lg p-4 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Activity className="w-5 h-5 text-green-400" />
            <span className="text-sm text-gray-300">Status:</span>
            <span className="text-sm font-semibold text-green-400">
              {state?.status || 'initializing'}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <Code className="w-5 h-5 text-purple-400" />
            <span className="text-sm text-gray-300">Active Language:</span>
            <span className="text-sm font-semibold text-purple-400">
              {activeLanguage}
            </span>
          </div>
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="bg-gray-800 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp className="w-5 h-5 text-blue-400" />
            <h3 className="text-sm font-semibold text-gray-300">Training Steps</h3>
          </div>
          <p className="text-2xl font-bold text-blue-400">
            {metrics?.total_training_steps || 0}
          </p>
          <p className="text-xs text-gray-500 mt-1">
            Current Loss: {currentLoss.toFixed(4)}
          </p>
        </div>

        <div className="bg-gray-800 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <Zap className="w-5 h-5 text-yellow-400" />
            <h3 className="text-sm font-semibold text-gray-300">Learning Rate</h3>
          </div>
          <p className="text-2xl font-bold text-yellow-400">
            {metrics?.learning_rate.toFixed(3) || '0.000'}
          </p>
          <p className="text-xs text-gray-500 mt-1">
            Avg Loss: {metrics?.average_loss.toFixed(4) || '0.0000'}
          </p>
        </div>

        <div className="bg-gray-800 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <Brain className="w-5 h-5 text-purple-400" />
            <h3 className="text-sm font-semibold text-gray-300">Ideas Processed</h3>
          </div>
          <p className="text-2xl font-bold text-purple-400">
            {state?.cognitive_ideas_processed || 0}
          </p>
          <p className="text-xs text-gray-500 mt-1">
            Transformations: {transformationCount}
          </p>
        </div>

        <div className="bg-gray-800 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <Activity className="w-5 h-5 text-green-400" />
            <h3 className="text-sm font-semibold text-gray-300">Convergence</h3>
          </div>
          <p className="text-2xl font-bold text-green-400">
            {((metrics?.convergence_score || 0) * 100).toFixed(1)}%
          </p>
          <p className="text-xs text-gray-500 mt-1">
            Quality Score
          </p>
        </div>
      </div>

      {/* Control Buttons */}
      <div className="flex gap-4">
        <button
          onClick={startTraining}
          disabled={isTraining || !agent}
          className={`flex-1 px-4 py-3 rounded-lg font-semibold transition-colors ${
            isTraining || !agent
              ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
              : 'bg-blue-600 hover:bg-blue-700 text-white'
          }`}
        >
          {isTraining ? (
            <>
              <Activity className="w-4 h-4 inline mr-2 animate-spin" />
              Training... Step {trainingStep}
            </>
          ) : (
            <>
              <TrendingUp className="w-4 h-4 inline mr-2" />
              Start Training
            </>
          )}
        </button>

        <button
          onClick={startTransformation}
          disabled={isTransforming || !agent}
          className={`flex-1 px-4 py-3 rounded-lg font-semibold transition-colors ${
            isTransforming || !agent
              ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
              : 'bg-purple-600 hover:bg-purple-700 text-white'
          }`}
        >
          {isTransforming ? (
            <>
              <Activity className="w-4 h-4 inline mr-2 animate-spin" />
              Transforming...
            </>
          ) : (
            <>
              <Code className="w-4 h-4 inline mr-2" />
              Transform Ideas
            </>
          )}
        </button>
      </div>

      {/* Training Progress Bar */}
      {isTraining && (
        <div className="mt-4 bg-gray-800 rounded-lg p-3">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs text-gray-400">Training Progress</span>
            <span className="text-xs text-gray-400">{trainingStep}/20</span>
          </div>
          <div className="w-full bg-gray-700 rounded-full h-2">
            <div 
              className="bg-blue-500 h-2 rounded-full transition-all duration-200"
              style={{ width: `${(trainingStep / 20) * 100}%` }}
            />
          </div>
        </div>
      )}

      {/* Language Support */}
      <div className="mt-6 bg-gray-800 rounded-lg p-4">
        <h3 className="text-sm font-semibold text-gray-300 mb-3">
          Supported Languages
        </h3>
        <div className="flex flex-wrap gap-2">
          {['Racket', 'Clojure', 'Scheme', 'Perl', 'Raku'].map((lang) => (
            <span
              key={lang}
              className={`px-3 py-1 rounded-full text-xs font-medium ${
                lang === activeLanguage
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-700 text-gray-400'
              }`}
            >
              {lang}
            </span>
          ))}
        </div>
      </div>

      {/* Info Panel */}
      <div className="mt-6 bg-gray-800/50 rounded-lg p-4 border border-cyan-500/20">
        <h3 className="text-sm font-semibold text-cyan-400 mb-2">
          System Capabilities
        </h3>
        <ul className="text-xs text-gray-400 space-y-1">
          <li>✓ Neural embeddings inspired by Torch7 nn</li>
          <li>✓ Multi-language cognitive transformations</li>
          <li>✓ Adaptive learning with gradient descent</li>
          <li>✓ Cross-paradigm idea implementation</li>
          <li>✓ Real-time metrics and monitoring</li>
        </ul>
      </div>
    </div>
  );
};
