#lang racket
;;; pli-run.rkt --- parse a standard P-Lingua .pli file and simulate it with
;;; the Racket L-Lingua kernel, printing the canonical (final ...) line so it
;;; can be diffed against psim (C++) and the Guile kernel (Scheme).
;;;
;;; Usage: racket pli-run.rkt <file.pli>

(require "pli-reader.rkt" "psystem.rkt")

(define (canonical-final psys)
  (define rows
    (sort (psystem-membranes psys) (λ (a b) (< (membrane-id a) (membrane-id b)))))
  (define (ms->str ms)
    (string-join (map (λ (p) (format "(~a . ~a)" (car p) (cdr p))) ms) " "))
  (define body
    (string-join
     (map (λ (m) (format "(~a ~a (~a))" (membrane-id m) (membrane-label m)
                         (ms->str (membrane-objects m)))) rows)
     " "))
  (format "(final (~a))" body))

(module+ main
  (define args (current-command-line-arguments))
  (when (zero? (vector-length args))
    (error 'pli-run "usage: racket pli-run.rkt <file.pli>"))
  (define model (parse-pli-file (vector-ref args 0)))
  (define-values (final events halted) (run model 1000 #f))
  (write-trace events (current-output-port))
  (writeln halted)
  (displayln (canonical-final final)))
