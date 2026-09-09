;;; demo.scm - Demonstration examples for nn.scm
;;; Run with: scheme --load demo.scm
;;; Or with Guile: guile -l nn.scm -l demo.scm

(load "nn.scm")

;;; ============================================================================
;;; Demo 1: Basic Network Creation and Prediction
;;; ============================================================================

(define (demo-basic)
  (display "")
  (newline)
  (display "=== Demo 1: Basic Network Creation ===")
  (newline)
  (display "Creating a 2-3-1 network...")
  (newline)
  
  (let ((net (create-network '(2 3 1))))
    (display "Network created with layers: ")
    (display (network-layers net))
    (newline)
    
    (display "Testing forward propagation with input [0.5, 0.8]...")
    (newline)
    (let ((output (forward '(0.5 0.8) net)))
      (display "Output: ")
      (display output)
      (newline))))

;;; ============================================================================
;;; Demo 2: XOR Problem
;;; ============================================================================

(define (demo-xor)
  (display "")
  (newline)
  (display "=== Demo 2: XOR Problem ===")
  (newline)
  (display "Training network to learn XOR function...")
  (newline)
  
  (let* ((net (create-network '(2 4 1)))
         (xor-data (list (make-sample '(0 0) '(0))
                        (make-sample '(0 1) '(1))
                        (make-sample '(1 0) '(1))
                        (make-sample '(1 1) '(0)))))
    
    (display "Training for 1000 epochs with learning rate 0.5...")
    (newline)
    (let ((trained-net (train xor-data net 0.5 1000)))
      
      (display "")
      (newline)
      (display "Testing predictions:")
      (newline)
      
      (let ((out1 (forward '(0 0) trained-net)))
        (display "  XOR(0, 0) = ")
        (display out1)
        (display " (expected: ~0)")
        (newline))
      
      (let ((out2 (forward '(0 1) trained-net)))
        (display "  XOR(0, 1) = ")
        (display out2)
        (display " (expected: ~1)")
        (newline))
      
      (let ((out3 (forward '(1 0) trained-net)))
        (display "  XOR(1, 0) = ")
        (display out3)
        (display " (expected: ~1)")
        (newline))
      
      (let ((out4 (forward '(1 1) trained-net)))
        (display "  XOR(1, 1) = ")
        (display out4)
        (display " (expected: ~0)")
        (newline)))))

;;; ============================================================================
;;; Demo 3: AND Gate
;;; ============================================================================

(define (demo-and)
  (display "")
  (newline)
  (display "=== Demo 3: AND Gate ===")
  (newline)
  (display "Training network to learn AND function...")
  (newline)
  
  (let* ((net (create-network '(2 2 1)))
         (and-data (list (make-sample '(0 0) '(0))
                        (make-sample '(0 1) '(0))
                        (make-sample '(1 0) '(0))
                        (make-sample '(1 1) '(1)))))
    
    (display "Training for 500 epochs with learning rate 0.5...")
    (newline)
    (let ((trained-net (train and-data net 0.5 500)))
      
      (display "")
      (newline)
      (display "Testing predictions:")
      (newline)
      
      (let ((out1 (forward '(0 0) trained-net)))
        (display "  AND(0, 0) = ")
        (display out1)
        (display " (expected: ~0)")
        (newline))
      
      (let ((out2 (forward '(0 1) trained-net)))
        (display "  AND(0, 1) = ")
        (display out2)
        (display " (expected: ~0)")
        (newline))
      
      (let ((out3 (forward '(1 0) trained-net)))
        (display "  AND(1, 0) = ")
        (display out3)
        (display " (expected: ~0)")
        (newline))
      
      (let ((out4 (forward '(1 1) trained-net)))
        (display "  AND(1, 1) = ")
        (display out4)
        (display " (expected: ~1)")
        (newline)))))

;;; ============================================================================
;;; Demo 4: Module-Based Network
;;; ============================================================================

(define (demo-modules)
  (display "")
  (newline)
  (display "=== Demo 4: Module-Based Architecture ===")
  (newline)
  (display "Building a network using modules...")
  (newline)
  
  (let* ((linear1 (make-linear 2 4))
         (tanh1 (tanh-module))
         (linear2 (make-linear 4 3))
         (sigmoid1 (sigmoid-module))
         (net (make-sequential (list linear1 tanh1 linear2 sigmoid1))))
    
    (display "Network structure: Linear(2→4) → Tanh → Linear(4→3) → Sigmoid")
    (newline)
    
    (display "Testing with input [0.5, 0.5]...")
    (newline)
    (let ((output (module-forward net '(0.5 0.5))))
      (display "Output: ")
      (display output)
      (newline))))

;;; ============================================================================
;;; Demo 5: Using Different Activation Functions
;;; ============================================================================

(define (demo-activations)
  (display "")
  (newline)
  (display "=== Demo 5: Activation Functions ===")
  (newline)
  
  (let ((input '(-2 -1 0 1 2)))
    (display "Input: ")
    (display input)
    (newline)
    (newline)
    
    (let* ((sigmoid-mod (sigmoid-module))
           (tanh-mod (tanh-module))
           (relu-mod (relu-module))
           (sigmoid-out (module-forward sigmoid-mod input))
           (tanh-out (module-forward tanh-mod input))
           (relu-out (module-forward relu-mod input)))
      
      (display "Sigmoid output: ")
      (display sigmoid-out)
      (newline)
      
      (display "Tanh output:    ")
      (display tanh-out)
      (newline)
      
      (display "ReLU output:    ")
      (display relu-out)
      (newline))))

;;; ============================================================================
;;; Demo 6: Loss Functions / Criterions
;;; ============================================================================

(define (demo-criterions)
  (display "")
  (newline)
  (display "=== Demo 6: Loss Functions (Criterions) ===")
  (newline)
  
  (let ((output '(0.8))
        (target '(1.0)))
    
    (display "Output: ")
    (display output)
    (display ", Target: ")
    (display target)
    (newline)
    (newline)
    
    (let ((mse-crit (mse-criterion))
          (abs-crit (abs-criterion)))
      
      (let ((mse-loss (criterion-forward mse-crit output target))
            (abs-loss (criterion-forward abs-crit output target)))
        
        (display "MSE Loss: ")
        (display mse-loss)
        (newline)
        
        (display "Absolute Loss: ")
        (display abs-loss)
        (newline)))))

;;; ============================================================================
;;; Demo 7: Softmax and Classification
;;; ============================================================================

(define (demo-softmax)
  (display "")
  (newline)
  (display "=== Demo 7: Softmax for Classification ===")
  (newline)
  
  (let* ((logits '(2.0 1.0 0.1))
         (softmax-mod (softmax-module))
         (log-softmax-mod (log-softmax-module))
         (probs (module-forward softmax-mod logits))
         (log-probs (module-forward log-softmax-mod logits)))
    
    (display "Logits: ")
    (display logits)
    (newline)
    
    (display "Softmax (probabilities): ")
    (display probs)
    (newline)
    (display "Sum of probabilities: ")
    (display (vector-sum probs))
    (newline)
    (newline)
    
    (display "LogSoftmax: ")
    (display log-probs)
    (newline)
    
    ;; Classification example
    (display "")
    (newline)
    (display "Classification example:")
    (newline)
    (display "Predicted class: ")
    (let ((max-idx (let loop ((lst probs) (idx 0) (max-idx 0) (max-val (car probs)))
                     (if (null? lst)
                         max-idx
                         (if (> (car lst) max-val)
                             (loop (cdr lst) (+ idx 1) idx (car lst))
                             (loop (cdr lst) (+ idx 1) max-idx max-val))))))
      (display max-idx)
      (display " (with probability ")
      (display (list-ref probs max-idx))
      (display ")")
      (newline))))

;;; ============================================================================
;;; Run All Demos
;;; ============================================================================

(define (run-all-demos)
  (display "")
  (newline)
  (display "=====================================")
  (newline)
  (display "Neural Network Demonstrations")
  (newline)
  (display "=====================================")
  (newline)
  
  (demo-basic)
  (demo-and)
  (demo-activations)
  (demo-modules)
  (demo-criterions)
  (demo-softmax)
  
  ;; Skip XOR demo in batch mode as it takes longer
  (display "")
  (newline)
  (display "Note: XOR demo skipped in batch mode. Run (demo-xor) separately.")
  (newline)
  
  (display "")
  (newline)
  (display "=====================================")
  (newline)
  (display "All demos completed!")
  (newline)
  (display "=====================================")
  (newline))

;;; ============================================================================
;;; Usage Instructions
;;; ============================================================================

(display "Demo suite loaded successfully!")
(newline)
(display "Available demos:")
(newline)
(display "  (demo-basic)       - Basic network creation and prediction")
(newline)
(display "  (demo-xor)         - XOR problem (takes ~1-2 seconds)")
(newline)
(display "  (demo-and)         - AND gate learning")
(newline)
(display "  (demo-modules)     - Module-based architecture")
(newline)
(display "  (demo-activations) - Different activation functions")
(newline)
(display "  (demo-criterions)  - Loss functions")
(newline)
(display "  (demo-softmax)     - Softmax for classification")
(newline)
(display "  (run-all-demos)    - Run all demos (except XOR)")
(newline)
(newline)
(display "Example: (demo-basic)")
(newline)
