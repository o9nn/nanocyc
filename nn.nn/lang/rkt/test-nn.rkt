#lang racket

;;; Test Suite for Neural Network Implementation
;;; Comprehensive tests for nn.rkt

(require "nn.rkt")

;;; Seed the RNG so the training tests are deterministic in CI (the unseeded
;;; random-weight initialisation makes "network learns * input" flaky).
(random-seed 42)

;;; ============================================================================
;;; Test Framework
;;; ============================================================================

(define test-count 0)
(define test-passed 0)
(define test-failed 0)

(define (assert-equal actual expected test-name)
  "Test that actual equals expected"
  (set! test-count (+ test-count 1))
  (if (equal? actual expected)
      (begin
        (set! test-passed (+ test-passed 1))
        (printf "✓ ~a~n" test-name))
      (begin
        (set! test-failed (+ test-failed 1))
        (printf "✗ ~a: Expected ~a, got ~a~n" test-name expected actual))))

(define (assert-true condition test-name)
  "Test that condition is true"
  (set! test-count (+ test-count 1))
  (if condition
      (begin
        (set! test-passed (+ test-passed 1))
        (printf "✓ ~a~n" test-name))
      (begin
        (set! test-failed (+ test-failed 1))
        (printf "✗ ~a: Expected true, got false~n" test-name))))

(define (assert-near actual expected tolerance test-name)
  "Test that actual is within tolerance of expected"
  (set! test-count (+ test-count 1))
  (if (< (abs (- actual expected)) tolerance)
      (begin
        (set! test-passed (+ test-passed 1))
        (printf "✓ ~a~n" test-name))
      (begin
        (set! test-failed (+ test-failed 1))
        (printf "✗ ~a: Expected ~a ± ~a, got ~a~n" 
                test-name expected tolerance actual))))

(define (print-test-summary)
  "Print test results summary"
  (displayln "")
  (displayln "==========================================")
  (printf "Test Results: ~a/~a passed~n" test-passed test-count)
  (if (> test-failed 0)
      (printf "FAILED: ~a tests failed~n" test-failed)
      (displayln "SUCCESS: All tests passed!"))
  (displayln "==========================================")
  (when (> test-failed 0)
    (exit 1)))

;;; ============================================================================
;;; Activation Function Tests
;;; ============================================================================

(define (test-activation-functions)
  (displayln "\n=== Testing Activation Functions ===")
  
  ;; Sigmoid tests
  (assert-near (sigmoid 0) 0.5 0.001 "sigmoid(0) = 0.5")
  (assert-true (> (sigmoid 5) 0.99) "sigmoid(5) > 0.99")
  (assert-true (< (sigmoid -5) 0.01) "sigmoid(-5) < 0.01")
  
  ;; Tanh tests
  (assert-near (tanh-activation 0) 0.0 0.001 "tanh(0) = 0")
  (assert-true (> (tanh-activation 5) 0.99) "tanh(5) > 0.99")
  (assert-true (< (tanh-activation -5) -0.99) "tanh(-5) < -0.99")
  
  ;; ReLU tests
  (assert-equal (relu -5) 0.0 "relu(-5) = 0")
  (assert-equal (relu 0) 0.0 "relu(0) = 0")
  (assert-equal (relu 5) 5.0 "relu(5) = 5")
  
  ;; Sigmoid derivative tests
  (assert-near (sigmoid-derivative 0) 0.25 0.001 "sigmoid'(0) ≈ 0.25")
  
  ;; Tanh derivative tests
  (assert-near (tanh-derivative 0) 1.0 0.001 "tanh'(0) = 1")
  
  ;; ReLU derivative tests
  (assert-equal (relu-derivative -5) 0.0 "relu'(-5) = 0")
  (assert-equal (relu-derivative 5) 1.0 "relu'(5) = 1"))

;;; ============================================================================
;;; Vector Operation Tests
;;; ============================================================================

(define (test-vector-operations)
  (displayln "\n=== Testing Vector Operations ===")
  
  ;; Dot product
  (assert-equal (dot-product '(1 2 3) '(4 5 6)) 32 "dot-product")
  (assert-equal (dot-product '(1 0) '(0 1)) 0 "dot-product orthogonal")
  
  ;; Vector addition
  (assert-equal (vector-add '(1 2 3) '(4 5 6)) '(5 7 9) "vector-add")
  
  ;; Vector subtraction
  (assert-equal (vector-sub '(5 7 9) '(1 2 3)) '(4 5 6) "vector-sub")
  
  ;; Scalar multiplication
  (assert-equal (scalar-mult-vector 2 '(1 2 3)) '(2 4 6) "scalar-mult-vector")
  
  ;; Vector sum
  (assert-equal (vector-sum '(1 2 3 4)) 10 "vector-sum")
  
  ;; Vector mean
  (assert-equal (vector-mean '(1 2 3 4)) 2.5 "vector-mean")
  
  ;; Vector max
  (assert-equal (vector-max '(1 5 3 2)) 5 "vector-max"))

;;; ============================================================================
;;; Matrix Operation Tests
;;; ============================================================================

(define (test-matrix-operations)
  (displayln "\n=== Testing Matrix Operations ===")
  
  ;; Matrix-vector multiplication
  (let ([matrix '((1 2) (3 4))]
        [vector '(5 6)])
    (assert-equal (matrix-vector-mult matrix vector) '(17 39) 
                  "matrix-vector-mult"))
  
  ;; Matrix transpose
  (let ([matrix '((1 2 3) (4 5 6))])
    (assert-equal (transpose-matrix matrix) '((1 4) (2 5) (3 6))
                  "transpose-matrix")))

;;; ============================================================================
;;; Network Structure Tests
;;; ============================================================================

(define (test-network-structure)
  (displayln "\n=== Testing Network Structure ===")
  
  ;; Create network
  (let ([net (create-network '(2 3 1))])
    (assert-equal (car net) 'network "network type tag")
    (assert-equal (network-layers net) '(2 3 1) "network layer sizes")
    (assert-equal (length (network-weights net)) 2 "number of weight layers"))
  
  ;; Neuron structure
  (let ([neuron (make-neuron 3)])
    (assert-equal (car neuron) 'neuron "neuron type tag")
    (assert-equal (length (neuron-weights neuron)) 3 "neuron weight count")
    (assert-true (number? (neuron-bias neuron)) "neuron has bias"))
  
  ;; Layer structure
  (let ([layer (make-layer 3 2)])
    (assert-equal (length layer) 2 "layer neuron count")
    (assert-equal (car (car layer)) 'neuron "layer contains neurons")))

;;; ============================================================================
;;; Forward Propagation Tests
;;; ============================================================================

(define (test-forward-propagation)
  (displayln "\n=== Testing Forward Propagation ===")
  
  ;; Simple forward pass
  (let ([net (create-network '(2 3 1))]
        [input '(0.5 0.8)])
    (let ([output (forward input net)])
      (assert-equal (length output) 1 "output size correct")
      (assert-true (and (> (car output) 0) (< (car output) 1)) 
                   "output in sigmoid range")))
  
  ;; Predict (alias test)
  (let ([net (create-network '(2 2 1))]
        [input '(0.5 0.5)])
    (let ([output1 (forward input net)]
          [output2 (predict input net)])
      (assert-equal output1 output2 "predict equals forward"))))

;;; ============================================================================
;;; Loss Function Tests
;;; ============================================================================

(define (test-loss-functions)
  (displayln "\n=== Testing Loss Functions ===")
  
  ;; MSE loss
  (assert-near (mse-loss '(0.8) '(1.0)) 0.04 0.001 "MSE loss")
  (assert-equal (mse-loss '(1.0 2.0) '(1.0 2.0)) 0.0 "MSE loss perfect match")
  
  ;; MSE loss derivative
  (let ([derivative (mse-loss-derivative '(0.8) '(1.0))])
    (assert-near (car derivative) -0.4 0.001 "MSE loss derivative"))
  
  ;; Absolute loss
  (assert-equal (abs-loss '(1 2 3) '(2 3 5)) 4.0 "absolute loss"))

;;; ============================================================================
;;; Module System Tests
;;; ============================================================================

(define (test-module-system)
  (displayln "\n=== Testing Module System ===")
  
  ;; Linear module
  (let ([linear (make-linear 2 3)])
    (assert-equal (car linear) 'linear "linear module type")
    (let ([output (module-forward linear '(0.5 0.8))])
      (assert-equal (length output) 3 "linear output size")))
  
  ;; Sigmoid module
  (let ([sigmoid-mod (sigmoid-module)])
    (assert-equal sigmoid-mod '(sigmoid) "sigmoid module structure")
    (let ([output (module-forward sigmoid-mod '(0 5 -5))])
      (assert-equal (length output) 3 "sigmoid module output size")
      (assert-near (car output) 0.5 0.01 "sigmoid(0) ≈ 0.5")))
  
  ;; Tanh module
  (let ([tanh-mod (tanh-module)])
    (let ([output (module-forward tanh-mod '(0 1 -1))])
      (assert-equal (length output) 3 "tanh module output size")))
  
  ;; ReLU module
  (let ([relu-mod (relu-module)])
    (let ([output (module-forward relu-mod '(-1 0 1))])
      (assert-equal output '(0.0 0.0 1.0) "ReLU module output")))
  
  ;; Identity module
  (let ([identity (make-identity)])
    (let ([input '(1 2 3)])
      (assert-equal (module-forward identity input) input "identity module")))
  
  ;; Sequential module
  (let* ([linear1 (make-linear 2 3)]
         [sigmoid1 (sigmoid-module)]
         [seq (make-sequential (list linear1 sigmoid1))])
    (assert-equal (car seq) 'sequential "sequential module type")
    (let ([output (module-forward seq '(0.5 0.8))])
      (assert-equal (length output) 3 "sequential output size")
      (assert-true (andmap (lambda (x) (and (>= x 0) (<= x 1))) output)
                   "sequential output in range"))))

;;; ============================================================================
;;; Softmax Tests
;;; ============================================================================

(define (test-softmax)
  (displayln "\n=== Testing Softmax ===")
  
  ;; Softmax
  (let ([output (softmax '(1.0 2.0 3.0))])
    (assert-equal (length output) 3 "softmax output size")
    (assert-near (vector-sum output) 1.0 0.001 "softmax sums to 1")
    (assert-true (< (car output) (cadr output)) "softmax preserves order"))
  
  ;; Log-softmax
  (let ([output (log-softmax '(1.0 2.0 3.0))])
    (assert-equal (length output) 3 "log-softmax output size")
    (assert-true (andmap negative? output) "log-softmax all negative"))
  
  ;; Softmax module
  (let* ([softmax-mod (softmax-module)]
         [output (module-forward softmax-mod '(1.0 2.0 3.0))])
    (assert-near (vector-sum output) 1.0 0.001 "softmax module sums to 1")))

;;; ============================================================================
;;; Criterion Tests
;;; ============================================================================

(define (test-criterions)
  (displayln "\n=== Testing Criterions ===")
  
  ;; MSE criterion
  (let ([criterion (mse-criterion)])
    (assert-equal criterion '(mse-criterion) "MSE criterion structure")
    (let ([loss (criterion-forward criterion '(0.8) '(1.0))])
      (assert-near loss 0.04 0.001 "MSE criterion loss")))
  
  ;; BCE criterion
  (let ([criterion (bce-criterion)])
    (let ([loss (criterion-forward criterion '(0.9) '(1.0))])
      (assert-true (> loss 0) "BCE criterion positive loss")))
  
  ;; Absolute criterion
  (let ([criterion (abs-criterion)])
    (let ([loss (criterion-forward criterion '(1 2 3) '(2 3 4))])
      (assert-equal loss 3.0 "Absolute criterion loss")))
  
  ;; ClassNLL criterion
  (let ([criterion (class-nll-criterion)])
    (let ([loss (criterion-forward criterion '(-0.5 -1.0 -2.0) 0)])
      (assert-equal loss 0.5 "ClassNLL criterion loss"))))

;;; ============================================================================
;;; Training Sample Tests
;;; ============================================================================

(define (test-training-samples)
  (displayln "\n=== Testing Training Samples ===")
  
  ;; Create sample
  (let ([sample (make-sample '(0 1) '(1))])
    (assert-equal (car sample) 'sample "sample type tag")
    (assert-equal (sample-input sample) '(0 1) "sample input")
    (assert-equal (sample-target sample) '(1) "sample target")))

;;; ============================================================================
;;; Integration Tests
;;; ============================================================================

(define (test-integration)
  (displayln "\n=== Testing Integration ===")
  
  ;; Simple training test
  (let* ([net (create-network '(2 2 1))]
         [samples (list (make-sample '(0 0) '(0))
                       (make-sample '(1 1) '(1)))]
         [trained-net (train samples net 0.5 10)])
    (assert-equal (car trained-net) 'network "trained network type")
    (assert-equal (network-layers trained-net) '(2 2 1) "trained network structure"))
  
  ;; Module-based network with criterion
  (let* ([linear (make-linear 2 3)]
         [sigmoid1 (sigmoid-module)]
         [net (make-sequential (list linear sigmoid1))]
         [criterion (mse-criterion)]
         [output (module-forward net '(0.5 0.8))]
         [loss (criterion-forward criterion output '(1.0 0.0 0.5))])
    (assert-true (>= loss 0) "loss is non-negative"))
  
  ;; End-to-end simple learning
  (let* ([net (create-network '(1 4 1))]
         [samples (list (make-sample '(0.0) '(0.0))
                       (make-sample '(1.0) '(1.0)))]
         [trained-net (train samples net 0.5 1000)]
         [output1 (predict '(0.0) trained-net)]
         [output2 (predict '(1.0) trained-net)])
    (assert-true (< (car output1) 0.4) "network learns low input")
    (assert-true (> (car output2) 0.6) "network learns high input")))

;;; ============================================================================
;;; Cross-Implementation Consistency (docs/fixtures/xor_fixture.json)
;;; ============================================================================
;;;
;;; Builds the fixed 2-2-1 sigmoid MLP shared with every other port and
;;; asserts the forward output and MSE loss to a tight tolerance, guaranteeing
;;; all implementations agree numerically on one deterministic fixture.

(define fixture-tolerance 1e-6)

;;; weights[layer][neuron] = (neuron (w...) b), mirroring the JSON fixture.
(define fixture-weights
  (list
    (list
      (list 'neuron (list 0.5 -0.5) 0.1)
      (list 'neuron (list -0.25 0.75) -0.2))
    (list
      (list 'neuron (list 0.6 -0.4) 0.05))))

(define fixture-network
  (list 'network (list 2 2 1) fixture-weights))

;;; (input target expected-output expected-loss) per case.
(define fixture-cases
  (list
    (list (list 0 0) (list 0) 0.5460989866 0.2982241032)
    (list (list 0 1) (list 1) 0.5092822253 0.2408039344)
    (list (list 1 0) (list 1) 0.5699505688 0.1849425133)
    (list (list 1 1) (list 0) 0.5337512224 0.2848903675)))

(define (test-consistency)
  "Cross-implementation consistency: forward output + MSE loss"
  (for-each
    (lambda (case)
      (let* ([input (car case)]
             [target (cadr case)]
             [expected-output (caddr case)]
             [expected-loss (cadddr case)]
             [output (forward input fixture-network)]
             [loss (mse-loss output target)])
        (assert-near (car output) expected-output fixture-tolerance
          (format "consistency output for input ~a" input))
        (assert-near loss expected-loss fixture-tolerance
          (format "consistency loss for input ~a" input))))
    fixture-cases))

;;; ============================================================================
;;; Run All Tests
;;; ============================================================================

(define (run-all-tests)
  "Run all test suites"
  (displayln "")
  (displayln "==========================================")
  (displayln "Neural Network Test Suite")
  (displayln "==========================================")
  
  (test-activation-functions)
  (test-vector-operations)
  (test-matrix-operations)
  (test-network-structure)
  (test-forward-propagation)
  (test-loss-functions)
  (test-module-system)
  (test-softmax)
  (test-criterions)
  (test-training-samples)
  (test-integration)
  (test-consistency)

  (print-test-summary))

;;; Run tests when module is executed directly
(run-all-tests)
