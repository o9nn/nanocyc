;;; Test file for nn.scm
;;; Run with: scheme --load test-nn.scm
;;; Or with Guile: guile -l nn.scm -l test-nn.scm

(load "nn.scm")

;;; ============================================================================
;;; Test Framework
;;; ============================================================================

(define test-count 0)
(define test-passed 0)
(define test-failed 0)

(define (assert-true condition message)
  "Assert that condition is true"
  (set! test-count (+ test-count 1))
  (if condition
      (begin
        (set! test-passed (+ test-passed 1))
        (display "  ✓ PASS: ")
        (display message)
        (newline))
      (begin
        (set! test-failed (+ test-failed 1))
        (display "  ✗ FAIL: ")
        (display message)
        (newline))))

(define (assert-equal actual expected message)
  "Assert that actual equals expected"
  (assert-true (equal? actual expected)
               (string-append message 
                            " (expected: " (format #f "~a" expected)
                            ", got: " (format #f "~a" actual) ")")))

(define (assert-approx actual expected tolerance message)
  "Assert that actual is approximately equal to expected"
  (assert-true (< (abs (- actual expected)) tolerance)
               (string-append message
                            " (expected: " (format #f "~a" expected)
                            ", got: " (format #f "~a" actual)
                            ", tolerance: " (format #f "~a" tolerance) ")")))

(define (test-summary)
  "Display test summary"
  (newline)
  (display "=====================================")
  (newline)
  (display "Test Summary:")
  (newline)
  (display "  Total:  ")
  (display test-count)
  (newline)
  (display "  Passed: ")
  (display test-passed)
  (newline)
  (display "  Failed: ")
  (display test-failed)
  (newline)
  (display "=====================================")
  (newline)
  (if (> test-failed 0)
      (exit 1)))

;;; ============================================================================
;;; Tests for Activation Functions
;;; ============================================================================

(define (test-sigmoid)
  (display "Test: Sigmoid activation function")
  (newline)
  (let ((y0 (sigmoid 0))
        (y1 (sigmoid 100))
        (y2 (sigmoid -100)))
    (assert-approx y0 0.5 0.01 "sigmoid(0) should be ~0.5")
    (assert-true (> y1 0.99) "sigmoid(100) should be close to 1")
    (assert-true (< y2 0.01) "sigmoid(-100) should be close to 0")))

(define (test-tanh)
  (display "Test: Tanh activation function")
  (newline)
  (let ((y0 (tanh-activation 0))
        (y1 (tanh-activation 10))
        (y2 (tanh-activation -10)))
    (assert-approx y0 0.0 0.01 "tanh(0) should be ~0")
    (assert-true (> y1 0.99) "tanh(10) should be close to 1")
    (assert-true (< y2 -0.99) "tanh(-10) should be close to -1")))

(define (test-relu)
  (display "Test: ReLU activation function")
  (newline)
  (assert-equal (relu 5.0) 5.0 "relu(5) should be 5")
  (assert-equal (relu -3.0) 0.0 "relu(-3) should be 0")
  (assert-equal (relu 0.0) 0.0 "relu(0) should be 0"))

;;; ============================================================================
;;; Tests for Vector Operations
;;; ============================================================================

(define (test-vector-ops)
  (display "Test: Vector operations")
  (newline)
  (assert-equal (dot-product '(1 2 3) '(4 5 6)) 32 "dot product [1,2,3]·[4,5,6]")
  (assert-equal (vector-add '(1 2) '(3 4)) '(4 6) "vector addition [1,2]+[3,4]")
  (assert-equal (vector-sub '(5 7) '(2 3)) '(3 4) "vector subtraction [5,7]-[2,3]")
  (assert-equal (scalar-mult-vector 2 '(1 2 3)) '(2 4 6) "scalar multiplication 2*[1,2,3]"))

(define (test-vector-reductions)
  (display "Test: Vector reductions")
  (newline)
  (assert-equal (vector-sum '(1 2 3 4)) 10 "vector sum")
  (assert-equal (vector-mean '(2 4 6 8)) 5 "vector mean")
  (assert-equal (vector-max '(1 5 3 2)) 5 "vector max"))

;;; ============================================================================
;;; Tests for Network Creation
;;; ============================================================================

(define (test-create-network)
  (display "Test: Network creation")
  (newline)
  (let ((net (create-network '(2 3 1))))
    (assert-equal (car net) 'network "Network should be tagged")
    (assert-equal (network-layers net) '(2 3 1) "Network should have correct layer sizes")
    (assert-true (not (null? (network-weights net))) "Network should have weights")))

(define (test-neuron-creation)
  (display "Test: Neuron creation")
  (newline)
  (let ((neuron (make-neuron 3)))
    (assert-equal (car neuron) 'neuron "Neuron should be tagged")
    (assert-equal (length (neuron-weights neuron)) 3 "Neuron should have 3 weights")
    (assert-true (number? (neuron-bias neuron)) "Neuron should have a bias")))

;;; ============================================================================
;;; Tests for Forward Propagation
;;; ============================================================================

(define (test-forward-propagation)
  (display "Test: Forward propagation")
  (newline)
  (let* ((net (create-network '(2 3 1)))
         (output (forward '(0.5 0.5) net)))
    (assert-equal (length output) 1 "Output should have 1 element")
    (assert-true (and (>= (car output) 0) (<= (car output) 1))
                "Output should be between 0 and 1 (sigmoid output)")))

;;; ============================================================================
;;; Tests for Loss Functions
;;; ============================================================================

(define (test-mse-loss)
  (display "Test: MSE loss")
  (newline)
  (let ((loss1 (mse-loss '(0.5) '(0.5)))
        (loss2 (mse-loss '(0.0) '(1.0))))
    (assert-approx loss1 0.0 0.001 "MSE loss for identical values should be 0")
    (assert-approx loss2 1.0 0.001 "MSE loss for [0] vs [1] should be 1")))

;;; ============================================================================
;;; Tests for Module System
;;; ============================================================================

(define (test-sigmoid-module)
  (display "Test: Sigmoid module")
  (newline)
  (let* ((module (sigmoid-module))
         (output (module-forward module '(0 2 -2))))
    (assert-equal (length output) 3 "Output should have 3 elements")
    (assert-approx (car output) 0.5 0.01 "sigmoid(0) in module")))

(define (test-tanh-module)
  (display "Test: Tanh module")
  (newline)
  (let* ((module (tanh-module))
         (output (module-forward module '(0 1 -1))))
    (assert-equal (length output) 3 "Output should have 3 elements")
    (assert-approx (car output) 0.0 0.01 "tanh(0) in module")))

(define (test-relu-module)
  (display "Test: ReLU module")
  (newline)
  (let* ((module (relu-module))
         (output (module-forward module '(-1 0 1 5))))
    (assert-equal output '(0.0 0.0 1.0 5.0) "ReLU module output")))

(define (test-linear-module)
  (display "Test: Linear module")
  (newline)
  (let* ((module (make-linear 2 3))
         (output (module-forward module '(1.0 1.0))))
    (assert-equal (length output) 3 "Linear module output size")))

(define (test-identity-module)
  (display "Test: Identity module")
  (newline)
  (let* ((module (make-identity))
         (input '(1 2 3))
         (output (module-forward module input)))
    (assert-equal output input "Identity module should return input unchanged")))

(define (test-sequential-module)
  (display "Test: Sequential module")
  (newline)
  (let* ((linear (make-linear 2 3))
         (sigmoid (sigmoid-module))
         (seq (make-sequential (list linear sigmoid)))
         (output (module-forward seq '(0.5 0.5))))
    (assert-equal (length output) 3 "Sequential output size")
    (assert-true (and (>= (car output) 0) (<= (car output) 1))
                "Sequential output should be in sigmoid range")))

;;; ============================================================================
;;; Tests for Criterion Modules
;;; ============================================================================

(define (test-mse-criterion)
  (display "Test: MSE criterion")
  (newline)
  (let* ((criterion (mse-criterion))
         (loss (criterion-forward criterion '(0.5) '(0.5))))
    (assert-approx loss 0.0 0.001 "MSE criterion for identical values")))

(define (test-class-nll-criterion)
  (display "Test: Class NLL criterion")
  (newline)
  (let* ((criterion (class-nll-criterion))
         (output '(-0.5 -1.5 -0.1))  ; log probabilities
         (target 2)  ; class index
         (loss (criterion-forward criterion output target)))
    (assert-approx loss 0.1 0.001 "Class NLL criterion")))

;;; ============================================================================
;;; Tests for Softmax
;;; ============================================================================

(define (test-softmax)
  (display "Test: Softmax function")
  (newline)
  (let ((output (softmax '(1.0 2.0 3.0))))
    (assert-equal (length output) 3 "Softmax output length")
    (assert-approx (vector-sum output) 1.0 0.001 "Softmax should sum to 1")))

(define (test-log-softmax)
  (display "Test: LogSoftmax function")
  (newline)
  (let ((output (log-softmax '(1.0 2.0 3.0))))
    (assert-equal (length output) 3 "LogSoftmax output length")
    (assert-true (< (car output) 0) "LogSoftmax values should be negative")))

;;; ============================================================================
;;; Integration Tests
;;; ============================================================================

(define (test-simple-training)
  (display "Test: Simple training (few iterations)")
  (newline)
  (let* ((net (create-network '(2 3 1)))
         (samples (list (make-sample '(0 0) '(0))
                       (make-sample '(1 1) '(1))))
         (trained-net (train samples net 0.5 5)))  ; Just 5 epochs for quick test
    (assert-equal (car trained-net) 'network "Trained network should still be a network")
    (assert-equal (network-layers trained-net) '(2 3 1) "Training should preserve structure")))

(define (test-module-composition)
  (display "Test: Module composition")
  (newline)
  (let* ((linear1 (make-linear 2 3))
         (tanh1 (tanh-module))
         (linear2 (make-linear 3 1))
         (sigmoid1 (sigmoid-module))
         (seq (make-sequential (list linear1 tanh1 linear2 sigmoid1)))
         (output (module-forward seq '(0.5 0.5))))
    (assert-equal (length output) 1 "Composed module output size")
    (assert-true (and (>= (car output) 0) (<= (car output) 1))
                "Final output should be in sigmoid range")))

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
      (let* ((input (car case))
             (target (cadr case))
             (expected-output (caddr case))
             (expected-loss (cadddr case))
             (output (forward input fixture-network))
             (loss (mse-loss output target)))
        (assert-approx (car output) expected-output fixture-tolerance
          (string-append "consistency output for input "
                         (format #f "~a" input)))
        (assert-approx loss expected-loss fixture-tolerance
          (string-append "consistency loss for input "
                         (format #f "~a" input)))))
    fixture-cases))

;;; ============================================================================
;;; Run All Tests
;;; ============================================================================

(define (run-all-tests)
  (display "")
  (newline)
  (display "=====================================")
  (newline)
  (display "Running Neural Network Tests")
  (newline)
  (display "=====================================")
  (newline)
  (newline)
  
  (display "--- Activation Functions ---")
  (newline)
  (test-sigmoid)
  (test-tanh)
  (test-relu)
  (newline)
  
  (display "--- Vector Operations ---")
  (newline)
  (test-vector-ops)
  (test-vector-reductions)
  (newline)
  
  (display "--- Network Creation ---")
  (newline)
  (test-create-network)
  (test-neuron-creation)
  (newline)
  
  (display "--- Forward Propagation ---")
  (newline)
  (test-forward-propagation)
  (newline)
  
  (display "--- Loss Functions ---")
  (newline)
  (test-mse-loss)
  (newline)
  
  (display "--- Module System ---")
  (newline)
  (test-sigmoid-module)
  (test-tanh-module)
  (test-relu-module)
  (test-linear-module)
  (test-identity-module)
  (test-sequential-module)
  (newline)
  
  (display "--- Criterion Modules ---")
  (newline)
  (test-mse-criterion)
  (test-class-nll-criterion)
  (newline)
  
  (display "--- Softmax Functions ---")
  (newline)
  (test-softmax)
  (test-log-softmax)
  (newline)
  
  (display "--- Integration Tests ---")
  (newline)
  (test-simple-training)
  (test-module-composition)
  (newline)

  (display "--- Cross-Implementation Consistency ---")
  (newline)
  (test-consistency)
  (newline)

  (test-summary))

;;; Run tests if this file is loaded directly
(display "Test suite loaded. Run (run-all-tests) to execute all tests.")
(newline)
