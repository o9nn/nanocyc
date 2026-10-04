;;; xcheck.scm --- Cross-validation driver: Scheme kernel vs C++ psim.
;;;
;;; Runs the s-expr kernel on a model and prints the halting configuration as
;;; a canonical s-expr so a shell harness can diff it against psim's JSON
;;; output (converted to the same canonical form by xcheck_psim.py).
;;;
;;; Usage: guile -L . -s xcheck.scm <model-file.scm>
;;;
;;; The model file must define a top-level `model` bound to a (psystem ...)
;;; s-expression.  Prints, in order:
;;;   (seed <n>)                     — for replayability (kernel is det. here)
;;;   one (fired ...) event per line — the "wire" stream
;;;   (halted ...)
;;;   (final <configuration-sexpr>)  — the "checkpoint"

(use-modules (plingua psystem) (srfi srfi-11))

(define (main args)
  (let ((file (cadr args)))
    (load file)                       ; defines `model` in the current module
    (let* ((m (eval 'model (current-module)))
           (seed 0))                  ; deterministic kernel: seed is nominal
      (let-values (((final events halted) (run m 1000 #f)))
        (format #t "(seed ~a) (model ~s)\n" seed file)
        (write-trace events (current-output-port))
        (write halted (current-output-port)) (newline)
        ;; canonical halting multiset per membrane, sorted by id
        (display "(final ")
        (write (map (lambda (mb)
                      (list (membrane-id mb)
                            (membrane-label mb)
                            (membrane-objects mb)))
                    (sort (psystem-membranes final)
                          (lambda (a b) (< (membrane-id a) (membrane-id b)))))
                (current-output-port))
        (display ")\n")))))

(main (command-line))
