#!/usr/bin/env -S guile --no-auto-compile -s
!#

;;; example.scm - Quick example of using the nn.scm library

(load "nn.scm")

;;; Example 1: Simple Network and Prediction
(display "========================================")
(newline)
(display "Example 1: Simple Neural Network")
(newline)
(display "========================================")
(newline)

; Create a 2-3-1 network (2 inputs, 3 hidden, 1 output)
(define net (create-network '(2 3 1)))

(display "Created network with layers: ")
(display (network-layers net))
(newline)

; Make predictions
(display "Testing predictions:")
(newline)
(display "  Input [0.0, 0.0] -> ")
(display (forward '(0.0 0.0) net))
(newline)
(display "  Input [0.5, 0.5] -> ")
(display (forward '(0.5 0.5) net))
(newline)
(display "  Input [1.0, 1.0] -> ")
(display (forward '(1.0 1.0) net))
(newline)

;;; Example 2: Using the Module System
(newline)
(display "========================================")
(newline)
(display "Example 2: Module-Based Architecture")
(newline)
(display "========================================")
(newline)

; Build a modular network
(define linear1 (make-linear 2 4))
(define activation1 (tanh-module))
(define linear2 (make-linear 4 1))
(define activation2 (sigmoid-module))

(define modular-net (make-sequential 
                      (list linear1 activation1 linear2 activation2)))

(display "Network: Linear(2→4) → Tanh → Linear(4→1) → Sigmoid")
(newline)
(display "Output for [0.5, 0.5]: ")
(display (module-forward modular-net '(0.5 0.5)))
(newline)

;;; Example 3: Classification with Softmax
(newline)
(display "========================================")
(newline)
(display "Example 3: Multi-Class Classification")
(newline)
(display "========================================")
(newline)

; Network for 3-class classification
(define classifier (make-sequential
                     (list (make-linear 2 3)
                           (softmax-module))))

(display "Input: [0.8, 0.3]")
(newline)
(define probs (module-forward classifier '(0.8 0.3)))
(display "Class probabilities: ")
(display probs)
(newline)
(display "Sum of probabilities: ")
(display (vector-sum probs))
(newline)

;;; Example 4: Using Different Loss Functions
(newline)
(display "========================================")
(newline)
(display "Example 4: Loss Functions")
(newline)
(display "========================================")
(newline)

(define output '(0.7))
(define target '(1.0))

(display "Output: ")
(display output)
(display ", Target: ")
(display target)
(newline)

(define mse (mse-criterion))
(define bce (bce-criterion))
(define abs-err (abs-criterion))

(display "MSE Loss: ")
(display (criterion-forward mse output target))
(newline)
(display "Binary Cross Entropy: ")
(display (criterion-forward bce output target))
(newline)
(display "Absolute Error: ")
(display (criterion-forward abs-err output target))
(newline)

;;; Example 5: Activation Functions Comparison
(newline)
(display "========================================")
(newline)
(display "Example 5: Activation Functions")
(newline)
(display "========================================")
(newline)

(define test-input '(-2.0 -1.0 0.0 1.0 2.0))
(display "Input: ")
(display test-input)
(newline)
(newline)

(display "Sigmoid: ")
(display (module-forward (sigmoid-module) test-input))
(newline)

(display "Tanh:    ")
(display (module-forward (tanh-module) test-input))
(newline)

(display "ReLU:    ")
(display (module-forward (relu-module) test-input))
(newline)

(newline)
(display "========================================")
(newline)
(display "All examples completed!")
(newline)
(display "========================================")
(newline)
