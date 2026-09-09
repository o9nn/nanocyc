#lang racket

;;; Demonstration Examples for Neural Network Library
;;; Various usage examples showcasing different features

(require "nn.rkt")

;;; ============================================================================
;;; Demo 1: Basic Neural Network Usage
;;; ============================================================================

(define (demo-basic)
  (displayln "\n========================================")
  (displayln "Demo 1: Basic Neural Network")
  (displayln "========================================")
  
  ; Create a network with 2 inputs, 3 hidden neurons, 1 output
  (displayln "Creating network with architecture [2, 3, 1]...")
  (define net (create-network '(2 3 1)))
  
  ; Make a prediction
  (displayln "Making prediction with input [0.5, 0.8]...")
  (define output (forward '(0.5 0.8) net))
  (printf "Output: ~a~n" output)
  
  (displayln "Basic demo completed!"))

;;; ============================================================================
;;; Demo 2: XOR Problem
;;; ============================================================================

(define (demo-xor)
  (displayln "\n========================================")
  (displayln "Demo 2: XOR Problem")
  (displayln "========================================")
  
  ; XOR is a classic non-linearly separable problem
  (displayln "Creating XOR training data...")
  (define xor-data
    (list (make-sample '(0 0) '(0))
          (make-sample '(0 1) '(1))
          (make-sample '(1 0) '(1))
          (make-sample '(1 1) '(0))))
  
  ; Create network
  (displayln "Creating network [2, 4, 1]...")
  (define net (create-network '(2 4 1)))
  
  ; Show initial predictions
  (displayln "\nInitial predictions (untrained):")
  (printf "  XOR(0,0) = ~a~n" (predict '(0 0) net))
  (printf "  XOR(0,1) = ~a~n" (predict '(0 1) net))
  (printf "  XOR(1,0) = ~a~n" (predict '(1 0) net))
  (printf "  XOR(1,1) = ~a~n" (predict '(1 1) net))
  
  ; Train the network
  (displayln "\nTraining network for 1000 epochs...")
  (define trained-net (train xor-data net 0.5 1000))
  
  ; Show final predictions
  (displayln "\nFinal predictions (after training):")
  (printf "  XOR(0,0) = ~a (expected 0)~n" (predict '(0 0) trained-net))
  (printf "  XOR(0,1) = ~a (expected 1)~n" (predict '(0 1) trained-net))
  (printf "  XOR(1,0) = ~a (expected 1)~n" (predict '(1 0) trained-net))
  (printf "  XOR(1,1) = ~a (expected 0)~n" (predict '(1 1) trained-net))
  
  (displayln "\nXOR demo completed!"))

;;; ============================================================================
;;; Demo 3: AND Gate
;;; ============================================================================

(define (demo-and)
  (displayln "\n========================================")
  (displayln "Demo 3: AND Gate")
  (displayln "========================================")
  
  (displayln "Creating AND gate training data...")
  (define and-data
    (list (make-sample '(0 0) '(0))
          (make-sample '(0 1) '(0))
          (make-sample '(1 0) '(0))
          (make-sample '(1 1) '(1))))
  
  (displayln "Creating network [2, 2, 1]...")
  (define net (create-network '(2 2 1)))
  
  (displayln "Training network for 500 epochs...")
  (define trained-net (train and-data net 0.5 500))
  
  (displayln "\nPredictions:")
  (printf "  AND(0,0) = ~a (expected 0)~n" (predict '(0 0) trained-net))
  (printf "  AND(0,1) = ~a (expected 0)~n" (predict '(0 1) trained-net))
  (printf "  AND(1,0) = ~a (expected 0)~n" (predict '(1 0) trained-net))
  (printf "  AND(1,1) = ~a (expected 1)~n" (predict '(1 1) trained-net))
  
  (displayln "\nAND gate demo completed!"))

;;; ============================================================================
;;; Demo 4: Module-Based Network
;;; ============================================================================

(define (demo-modules)
  (displayln "\n========================================")
  (displayln "Demo 4: Module-Based Network")
  (displayln "========================================")
  
  ; Build a network using individual modules
  (displayln "Building modular network:")
  (displayln "  - Linear layer: 2 -> 3")
  (displayln "  - Tanh activation")
  (displayln "  - Linear layer: 3 -> 1")
  (displayln "  - Sigmoid activation")
  
  (define linear1 (make-linear 2 3))
  (define tanh1 (tanh-module))
  (define linear2 (make-linear 3 1))
  (define sigmoid1 (sigmoid-module))
  
  ; Compose into sequential network
  (define net (make-sequential (list linear1 tanh1 linear2 sigmoid1)))
  
  ; Forward pass
  (displayln "\nPerforming forward pass with input [0.5, 0.8]...")
  (define output (module-forward net '(0.5 0.8)))
  (printf "Output: ~a~n" output)
  
  ; Use with criterion
  (displayln "\nComputing loss with MSE criterion...")
  (define criterion (mse-criterion))
  (define loss (criterion-forward criterion output '(1.0)))
  (printf "Loss: ~a~n" loss)
  
  (displayln "\nModule demo completed!"))

;;; ============================================================================
;;; Demo 5: Activation Functions
;;; ============================================================================

(define (demo-activations)
  (displayln "\n========================================")
  (displayln "Demo 5: Activation Functions")
  (displayln "========================================")
  
  (define test-values '(-2.0 -1.0 0.0 1.0 2.0))
  
  (displayln "\nSigmoid activation:")
  (for ([x test-values])
    (printf "  sigmoid(~a) = ~a~n" x (sigmoid x)))
  
  (displayln "\nTanh activation:")
  (for ([x test-values])
    (printf "  tanh(~a) = ~a~n" x (tanh-activation x)))
  
  (displayln "\nReLU activation:")
  (for ([x test-values])
    (printf "  relu(~a) = ~a~n" x (relu x)))
  
  (displayln "\nActivation functions demo completed!"))

;;; ============================================================================
;;; Demo 6: Loss Functions (Criterions)
;;; ============================================================================

(define (demo-criterions)
  (displayln "\n========================================")
  (displayln "Demo 6: Loss Functions (Criterions)")
  (displayln "========================================")
  
  (define output '(0.8 0.6 0.4))
  (define target '(1.0 0.5 0.0))
  
  (displayln "\nMean Squared Error:")
  (define mse-crit (mse-criterion))
  (define mse-loss (criterion-forward mse-crit output target))
  (printf "  Output: ~a~n" output)
  (printf "  Target: ~a~n" target)
  (printf "  MSE Loss: ~a~n" mse-loss)
  
  (displayln "\nBinary Cross Entropy:")
  (define bce-crit (bce-criterion))
  (define bce-loss-val (criterion-forward bce-crit output target))
  (printf "  BCE Loss: ~a~n" bce-loss-val)
  
  (displayln "\nAbsolute Error:")
  (define abs-crit (abs-criterion))
  (define abs-loss-val (criterion-forward abs-crit output target))
  (printf "  Absolute Loss: ~a~n" abs-loss-val)
  
  (displayln "\nCriterions demo completed!"))

;;; ============================================================================
;;; Demo 7: Softmax for Classification
;;; ============================================================================

(define (demo-softmax)
  (displayln "\n========================================")
  (displayln "Demo 7: Softmax Classification")
  (displayln "========================================")
  
  ; Create a network for 3-class classification
  (displayln "Building classification network:")
  (displayln "  - Linear layer: 4 features -> 3 classes")
  (displayln "  - Softmax activation")
  
  (define linear (make-linear 4 3))
  (define softmax-act (softmax-module))
  (define net (make-sequential (list linear softmax-act)))
  
  ; Forward pass
  (displayln "\nClassifying input [0.5, 0.3, 0.8, 0.2]...")
  (define probs (module-forward net '(0.5 0.3 0.8 0.2)))
  (printf "Class probabilities: ~a~n" probs)
  (printf "Sum of probabilities: ~a~n" (vector-sum probs))
  
  ; Find predicted class
  (define (argmax lst)
    (define (helper lst idx max-idx max-val)
      (cond
        [(null? lst) max-idx]
        [(> (car lst) max-val)
         (helper (cdr lst) (+ idx 1) idx (car lst))]
        [else
         (helper (cdr lst) (+ idx 1) max-idx max-val)]))
    (helper (cdr lst) 1 0 (car lst)))
  
  (define predicted-class (argmax probs))
  (printf "Predicted class: ~a~n" predicted-class)
  
  (displayln "\nSoftmax demo completed!"))

;;; ============================================================================
;;; Demo 8: Vector Operations
;;; ============================================================================

(define (demo-vector-ops)
  (displayln "\n========================================")
  (displayln "Demo 8: Vector Operations")
  (displayln "========================================")
  
  (define v1 '(1 2 3))
  (define v2 '(4 5 6))
  
  (printf "\nVector 1: ~a~n" v1)
  (printf "Vector 2: ~a~n" v2)
  
  (printf "\nDot product: ~a~n" (dot-product v1 v2))
  (printf "Vector addition: ~a~n" (vector-add v1 v2))
  (printf "Vector subtraction: ~a~n" (vector-sub v2 v1))
  (printf "Scalar multiplication (2 * v1): ~a~n" (scalar-mult-vector 2 v1))
  (printf "Vector sum (v1): ~a~n" (vector-sum v1))
  (printf "Vector mean (v1): ~a~n" (vector-mean v1))
  (printf "Vector max (v1): ~a~n" (vector-max v1))
  
  (displayln "\nVector operations demo completed!"))

;;; ============================================================================
;;; Run All Demos
;;; ============================================================================

(define (run-all-demos)
  "Run all demonstration examples"
  (displayln "")
  (displayln "========================================")
  (displayln "Neural Network Library Demonstrations")
  (displayln "========================================")
  
  (demo-basic)
  (demo-xor)
  (demo-and)
  (demo-modules)
  (demo-activations)
  (demo-criterions)
  (demo-softmax)
  (demo-vector-ops)
  
  (displayln "\n========================================")
  (displayln "All demos completed!")
  (displayln "========================================"))

;;; Run demos when module is executed directly
(run-all-demos)
