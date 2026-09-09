#lang racket

;;; Neural Network Implementation in Pure Racket
;;; A minimal, pure Racket implementation of feedforward neural networks
;;; with backpropagation training and modular architecture.
;;;
;;; This implementation provides:
;;; - Feedforward neural networks with arbitrary layer sizes
;;; - Multiple activation functions (sigmoid, tanh, relu)
;;; - Backpropagation training algorithm
;;; - Modular architecture with containers and modules
;;; - Multiple loss criterions
;;; - Vector and matrix operations

;;; ============================================================================
;;; Utility Functions - Random Number Generation
;;; ============================================================================

(provide (all-defined-out))

(define (random-real)
  "Generate a random real number between 0 and 1"
  (/ (random 10000) 10000.0))

(define (random-weight)
  "Generate a random weight between -0.5 and 0.5"
  (- (random-real) 0.5))

;;; ============================================================================
;;; Mathematical Functions
;;; ============================================================================

(define (exp-safe x)
  "Safe exponential function that handles overflow"
  (cond
    [(> x 20) (exp 20)]
    [(< x -20) (exp -20)]
    [else (exp x)]))

(define (sigmoid x)
  "Sigmoid activation function: 1 / (1 + exp(-x))"
  (/ 1.0 (+ 1.0 (exp-safe (- x)))))

(define (sigmoid-derivative x)
  "Derivative of sigmoid: sigmoid(x) * (1 - sigmoid(x))"
  (let ([s (sigmoid x)])
    (* s (- 1.0 s))))

(define (tanh-activation x)
  "Hyperbolic tangent activation function"
  (tanh x))

(define (tanh-derivative x)
  "Derivative of tanh: 1 - tanh(x)^2"
  (let ([t (tanh x)])
    (- 1.0 (* t t))))

(define (relu x)
  "ReLU activation function: max(0, x)"
  (max 0.0 x))

(define (relu-derivative x)
  "Derivative of ReLU: 1 if x > 0, else 0"
  (if (> x 0.0) 1.0 0.0))

;;; ============================================================================
;;; Vector Operations
;;; ============================================================================

(define (vector-map f v)
  "Apply function f to each element of vector v"
  (map f v))

(define (vector-map2 f v1 v2)
  "Apply binary function f to corresponding elements of v1 and v2"
  (map f v1 v2))

(define (dot-product v1 v2)
  "Compute dot product of two vectors"
  (apply + (vector-map2 * v1 v2)))

(define (vector-add v1 v2)
  "Add two vectors element-wise"
  (vector-map2 + v1 v2))

(define (vector-sub v1 v2)
  "Subtract v2 from v1 element-wise"
  (vector-map2 - v1 v2))

(define (scalar-mult-vector s v)
  "Multiply vector by scalar"
  (vector-map (lambda (x) (* s x)) v))

(define (vector-sum v)
  "Sum all elements in vector"
  (apply + v))

(define (vector-mean v)
  "Compute mean of vector elements"
  (/ (vector-sum v) (* 1.0 (length v))))

(define (vector-max v)
  "Find maximum element in vector"
  (apply max v))

;;; ============================================================================
;;; Matrix Operations
;;; ============================================================================

(define (matrix-vector-mult matrix vector)
  "Multiply matrix by vector, where matrix is a list of row vectors"
  (map (lambda (row) (dot-product row vector)) matrix))

(define (transpose-matrix matrix)
  "Transpose a matrix represented as list of rows"
  (apply map list matrix))

;;; ============================================================================
;;; Network Structure and Initialization
;;; ============================================================================

(define (make-neuron input-size)
  "Create a neuron with random weights and bias"
  (let ([weights (map (lambda (_) (random-weight)) (range input-size))]
        [bias (random-weight)])
    (list 'neuron weights bias)))

(define (neuron-weights neuron)
  "Extract weights from neuron"
  (cadr neuron))

(define (neuron-bias neuron)
  "Extract bias from neuron"
  (caddr neuron))

(define (make-layer input-size output-size)
  "Create a layer with output-size neurons, each with input-size inputs"
  (map (lambda (_) (make-neuron input-size)) (range output-size)))

(define (init-weights layer-sizes)
  "Initialize weights for all layers in the network"
  (if (< (length layer-sizes) 2)
      '()
      (cons (make-layer (car layer-sizes) (cadr layer-sizes))
            (init-weights (cdr layer-sizes)))))

(define (create-network layer-sizes)
  "Create a neural network with specified layer sizes"
  (let ([weights (init-weights layer-sizes)])
    (list 'network layer-sizes weights)))

(define (network-layers network)
  "Extract layer sizes from network"
  (cadr network))

(define (network-weights network)
  "Extract weights from network"
  (caddr network))

;;; ============================================================================
;;; Forward Propagation
;;; ============================================================================

(define (neuron-output neuron input)
  "Compute output of a single neuron"
  (let ([weights (neuron-weights neuron)]
        [bias (neuron-bias neuron)])
    (+ (dot-product weights input) bias)))

(define (layer-output layer input activation-fn)
  "Compute output of a layer"
  (map (lambda (neuron)
         (activation-fn (neuron-output neuron input)))
       layer))

(define (forward-propagate input weights)
  "Perform forward propagation through all layers"
  (if (null? weights)
      input
      (let ([layer-out (layer-output (car weights) input sigmoid)])
        (forward-propagate layer-out (cdr weights)))))

(define (forward input network)
  "Compute network output for given input"
  (forward-propagate input (network-weights network)))

(define (predict input network)
  "Alias for forward - compute network prediction"
  (forward input network))

;;; ============================================================================
;;; Loss Functions
;;; ============================================================================

(define (mse-loss output target)
  "Mean Squared Error loss"
  (let ([diff (vector-sub output target)])
    (/ (dot-product diff diff) (length output))))

(define (mse-loss-derivative output target)
  "Derivative of MSE loss with respect to output"
  (scalar-mult-vector (/ 2.0 (length output))
                      (vector-sub output target)))

;;; ============================================================================
;;; Backpropagation (Simplified for basic training)
;;; ============================================================================

(define (compute-layer-activations input weights)
  "Compute activations for all layers during forward pass"
  (if (null? weights)
      (list input)
      (let* ([layer-weighted (map (lambda (neuron) (neuron-output neuron input))
                                  (car weights))]
             [layer-activated (map sigmoid layer-weighted)])
        (cons input (compute-layer-activations layer-activated (cdr weights))))))

(define (update-neuron-weights neuron input delta learning-rate)
  "Update weights of a single neuron"
  (let* ([weights (neuron-weights neuron)]
         [bias (neuron-bias neuron)]
         [weight-deltas (map (lambda (x) (* learning-rate delta x)) input)]
         [new-weights (vector-map2 - weights weight-deltas)]
         [new-bias (- bias (* learning-rate delta))])
    (list 'neuron new-weights new-bias)))

(define (update-layer-weights layer input deltas learning-rate)
  "Update weights for all neurons in a layer"
  (map (lambda (neuron delta)
         (update-neuron-weights neuron input delta learning-rate))
       layer deltas))

;;; ============================================================================
;;; Training
;;; ============================================================================

(define (train-step input target network learning-rate)
  "Perform one training step (forward + backward pass)"
  (let* ([weights (network-weights network)]
         [layer-sizes (network-layers network)]
         [activations (compute-layer-activations input weights)]
         [output (car (reverse activations))]
         [loss (mse-loss output target)]
         [output-delta (mse-loss-derivative output target)])
    ;; Simplified weight update for output layer only
    (let* ([last-layer (car (reverse weights))]
           [last-activation (if (< (length activations) 2)
                               input
                               (list-ref activations (- (length activations) 2)))]
           [pre-activation (map (lambda (neuron) (neuron-output neuron last-activation))
                               last-layer)]
           [output-deltas (vector-map2 (lambda (od pa) (* od (sigmoid-derivative pa)))
                                       output-delta pre-activation)]
           [updated-last-layer (update-layer-weights last-layer last-activation 
                                                     output-deltas learning-rate)]
           [updated-weights (append (reverse (cdr (reverse weights)))
                                   (list updated-last-layer))])
      (list 'network layer-sizes updated-weights))))

(define (train-epoch samples network learning-rate)
  "Train network for one epoch on all samples"
  (if (null? samples)
      network
      (let* ([sample (car samples)]
             [input (cadr sample)]
             [target (caddr sample)]
             [updated-network (train-step input target network learning-rate)])
        (train-epoch (cdr samples) updated-network learning-rate))))

(define (train samples network learning-rate epochs)
  "Train network for specified number of epochs"
  (if (<= epochs 0)
      network
      (let ([updated-network (train-epoch samples network learning-rate)])
        (train samples updated-network learning-rate (- epochs 1)))))

;;; ============================================================================
;;; Module-Based Architecture
;;; ============================================================================

;;; Module types:
;;; - ('sigmoid) - Sigmoid activation module
;;; - ('tanh) - Tanh activation module
;;; - ('relu) - ReLU activation module
;;; - ('log-softmax) - LogSoftmax module
;;; - ('softmax) - Softmax module
;;; - ('linear weights bias) - Linear transformation module
;;; - ('identity) - Identity pass-through module
;;; - ('reshape shape) - Reshape module
;;; - ('sequential modules) - Sequential container
;;; - ('concat dim modules) - Concat container

(define (module-forward module input)
  "Forward pass through a module"
  (let ([module-type (car module)])
    (cond
      [(eq? module-type 'sigmoid)
       (vector-map sigmoid input)]
      [(eq? module-type 'tanh)
       (vector-map tanh-activation input)]
      [(eq? module-type 'relu)
       (vector-map relu input)]
      [(eq? module-type 'softmax)
       (softmax input)]
      [(eq? module-type 'log-softmax)
       (log-softmax input)]
      [(eq? module-type 'linear)
       (let ([weights (cadr module)]
             [bias (caddr module)])
         (vector-add (matrix-vector-mult weights input) bias))]
      [(eq? module-type 'identity)
       input]
      [(eq? module-type 'reshape)
       ;; Simplified: just return input (full reshape would require tensors)
       input]
      [(eq? module-type 'sequential)
       (sequential-forward (cadr module) input)]
      [(eq? module-type 'concat)
       (concat-forward (cadr module) (caddr module) input)]
      [else
       (error "Unknown module type" module-type)])))

;;; ============================================================================
;;; Activation Module Implementations
;;; ============================================================================

(define (softmax input)
  "Softmax activation: exp(x_i) / sum(exp(x_j))"
  (let* ([max-val (vector-max input)]
         [shifted (vector-map (lambda (x) (- x max-val)) input)]
         [exps (vector-map exp-safe shifted)]
         [sum-exps (vector-sum exps)])
    (vector-map (lambda (e) (/ e sum-exps)) exps)))

(define (log-softmax input)
  "Log-Softmax activation: log(softmax(x))"
  (let* ([max-val (vector-max input)]
         [shifted (vector-map (lambda (x) (- x max-val)) input)]
         [exps (vector-map exp-safe shifted)]
         [sum-exps (vector-sum exps)]
         [log-sum (log sum-exps)])
    (vector-map (lambda (x) (- x log-sum)) shifted)))

;;; ============================================================================
;;; Container Module Implementations
;;; ============================================================================

(define (make-sequential modules)
  "Create a sequential container"
  (list 'sequential modules))

(define (sequential-forward modules input)
  "Forward pass through sequential container"
  (if (null? modules)
      input
      (let ([output (module-forward (car modules) input)])
        (sequential-forward (cdr modules) output))))

(define (make-concat dim modules)
  "Create a concat container"
  (list 'concat dim modules))

(define (concat-forward dim modules input)
  "Forward pass through concat container (concatenate outputs)"
  (if (null? modules)
      '()
      (let ([output (module-forward (car modules) input)]
            [rest-output (concat-forward dim (cdr modules) input)])
        (append output rest-output))))

;;; ============================================================================
;;; Simple Layer Modules
;;; ============================================================================

(define (make-linear input-size output-size)
  "Create a linear module"
  (let ([weights (map (lambda (_) 
                       (map (lambda (_) (random-weight)) 
                            (range input-size)))
                     (range output-size))]
        [bias (map (lambda (_) (random-weight)) (range output-size))])
    (list 'linear weights bias)))

(define (make-identity)
  "Create an identity module"
  (list 'identity))

(define (make-reshape shape)
  "Create a reshape module"
  (list 'reshape shape))

(define (make-mean dim)
  "Create a mean reduction module"
  (list 'mean dim))

(define (make-max dim)
  "Create a max reduction module"
  (list 'max dim))

;;; ============================================================================
;;; Criterion/Loss Modules
;;; ============================================================================

;;; Criterion types:
;;; - ('mse-criterion) - Mean Squared Error
;;; - ('class-nll-criterion) - Negative Log Likelihood for classification
;;; - ('bce-criterion) - Binary Cross Entropy
;;; - ('abs-criterion) - Absolute Error (L1)

(define (criterion-forward criterion output target)
  "Compute loss for a criterion"
  (let ([criterion-type (car criterion)])
    (cond
      [(eq? criterion-type 'mse-criterion)
       (mse-loss output target)]
      [(eq? criterion-type 'class-nll-criterion)
       (class-nll-loss output target)]
      [(eq? criterion-type 'bce-criterion)
       (bce-loss output target)]
      [(eq? criterion-type 'abs-criterion)
       (abs-loss output target)]
      [else
       (error "Unknown criterion type" criterion-type)])))

(define (class-nll-loss output target)
  "Negative Log Likelihood loss (target is class index)"
  (- (list-ref output target)))

(define (bce-loss output target)
  "Binary Cross Entropy loss"
  (let ([epsilon 1e-7])
    (- (vector-sum
        (vector-map2 (lambda (o t)
                      (+ (* t (log (+ o epsilon)))
                         (* (- 1.0 t) (log (+ (- 1.0 o) epsilon)))))
                    output target)))))

(define (abs-loss output target)
  "Absolute error (L1) loss"
  (* 1.0 (vector-sum (vector-map abs (vector-sub output target)))))

;;; ============================================================================
;;; Module Constructors (User-friendly API)
;;; ============================================================================

(define (sigmoid-module)
  "Create a sigmoid activation module"
  (list 'sigmoid))

(define (tanh-module)
  "Create a tanh activation module"
  (list 'tanh))

(define (relu-module)
  "Create a ReLU activation module"
  (list 'relu))

(define (softmax-module)
  "Create a softmax activation module"
  (list 'softmax))

(define (log-softmax-module)
  "Create a log-softmax activation module"
  (list 'log-softmax))

(define (mse-criterion)
  "Create an MSE criterion"
  (list 'mse-criterion))

(define (class-nll-criterion)
  "Create a class NLL criterion"
  (list 'class-nll-criterion))

(define (bce-criterion)
  "Create a BCE criterion"
  (list 'bce-criterion))

(define (abs-criterion)
  "Create an absolute error criterion"
  (list 'abs-criterion))

;;; ============================================================================
;;; Training Sample Data Structure
;;; ============================================================================

(define (make-sample input target)
  "Create a training sample"
  (list 'sample input target))

(define (sample-input sample)
  "Extract input from sample"
  (cadr sample))

(define (sample-target sample)
  "Extract target from sample"
  (caddr sample))

;;; ============================================================================
;;; Module Entry Point
;;; ============================================================================

(displayln "Neural Network library loaded successfully!")
(displayln "Available functions:")
(displayln "  - (create-network layer-sizes)")
(displayln "  - (forward input network)")
(displayln "  - (train samples network learning-rate epochs)")
(displayln "  - Module system: make-linear, make-sequential, etc.")
