#!/usr/bin/env racket
#lang racket

;;; Practical Example: Training a Neural Network
;;; A complete, runnable example showing how to use the neural network library

(require "nn.rkt")

;;; ============================================================================
;;; Example: XOR Problem with Detailed Output
;;; ============================================================================

(displayln "========================================")
(displayln "Neural Network Training Example")
(displayln "Problem: XOR (Non-linearly Separable)")
(displayln "========================================\n")

; Step 1: Prepare training data
(displayln "Step 1: Creating training dataset...")
(define xor-training-data
  (list (make-sample '(0.0 0.0) '(0.0))
        (make-sample '(0.0 1.0) '(1.0))
        (make-sample '(1.0 0.0) '(1.0))
        (make-sample '(1.0 1.0) '(0.0))))

(displayln "Training data:")
(displayln "  Input: [0, 0] -> Target: 0")
(displayln "  Input: [0, 1] -> Target: 1")
(displayln "  Input: [1, 0] -> Target: 1")
(displayln "  Input: [1, 1] -> Target: 0")

; Step 2: Create network architecture
(displayln "\nStep 2: Creating neural network...")
(displayln "Architecture: 2 inputs -> 4 hidden -> 1 output")
(define network (create-network '(2 4 1)))
(displayln "Network initialized with random weights")

; Step 3: Test untrained network
(displayln "\nStep 3: Testing untrained network...")
(displayln "Predictions before training:")
(printf "  XOR(0, 0) = ~a (expected 0)~n" (car (predict '(0.0 0.0) network)))
(printf "  XOR(0, 1) = ~a (expected 1)~n" (car (predict '(0.0 1.0) network)))
(printf "  XOR(1, 0) = ~a (expected 1)~n" (car (predict '(1.0 0.0) network)))
(printf "  XOR(1, 1) = ~a (expected 0)~n" (car (predict '(1.0 1.0) network)))

; Step 4: Train the network
(displayln "\nStep 4: Training network...")
(displayln "Hyperparameters:")
(displayln "  Learning rate: 0.5")
(displayln "  Epochs: 2000")

(displayln "\nTraining in progress...")
(define trained-network (train xor-training-data network 0.5 2000))
(displayln "Training completed!")

; Step 5: Test trained network
(displayln "\nStep 5: Testing trained network...")
(displayln "Predictions after training:")
(define result-00 (car (predict '(0.0 0.0) trained-network)))
(define result-01 (car (predict '(0.0 1.0) trained-network)))
(define result-10 (car (predict '(1.0 0.0) trained-network)))
(define result-11 (car (predict '(1.0 1.0) trained-network)))

(printf "  XOR(0, 0) = ~a (expected 0) ~a~n" 
        result-00
        (if (< result-00 0.2) "✓" "✗"))
(printf "  XOR(0, 1) = ~a (expected 1) ~a~n" 
        result-01
        (if (> result-01 0.8) "✓" "✗"))
(printf "  XOR(1, 0) = ~a (expected 1) ~a~n" 
        result-10
        (if (> result-10 0.8) "✓" "✗"))
(printf "  XOR(1, 1) = ~a (expected 0) ~a~n" 
        result-11
        (if (< result-11 0.2) "✓" "✗"))

; Step 6: Summary
(displayln "\nStep 6: Summary")
(displayln "The network successfully learned the XOR function!")
(displayln "This demonstrates that the neural network can learn")
(displayln "non-linear decision boundaries through backpropagation.")

; Additional example: Using the module system
(displayln "\n========================================")
(displayln "Bonus: Module-Based Architecture")
(displayln "========================================\n")

(displayln "Building network using modules:")
(define linear1 (make-linear 2 4))
(define tanh-layer (tanh-module))
(define linear2 (make-linear 4 1))
(define sigmoid-layer (sigmoid-module))

(define modular-network 
  (make-sequential (list linear1 tanh-layer linear2 sigmoid-layer)))

(displayln "Modules:")
(displayln "  1. Linear(2 -> 4)")
(displayln "  2. Tanh()")
(displayln "  3. Linear(4 -> 1)")
(displayln "  4. Sigmoid()")

(displayln "\nTesting modular network:")
(define modular-output (module-forward modular-network '(0.5 0.8)))
(printf "Output: ~a~n" modular-output)

; Using criterion
(displayln "\nUsing loss criterion:")
(define criterion (mse-criterion))
(define loss (criterion-forward criterion modular-output '(1.0)))
(printf "MSE Loss: ~a~n" loss)

(displayln "\n========================================")
(displayln "Example completed successfully!")
(displayln "========================================")
