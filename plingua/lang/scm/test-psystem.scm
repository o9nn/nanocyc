;;; test-psystem.scm --- Golden tests for the s-expr membrane kernel.
;;;
;;; Each test mirrors a psim-runnable fixture (plingua/examples or a hand-built
;;; standard P-Lingua model) so the Scheme kernel and the C++ simulator can be
;;; cross-checked on identical semantics.  Run with:
;;;
;;;   guile -L . -s test-psystem.scm
;;;
;;; Exits non-zero if any test fails.

(define-module (test-psystem)
  #:use-module (plingua psystem)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11))

(define failures 0)

(define (check label got expected)
  (if (equal? got expected)
      (format #t "ok   ~a\n" label)
      (begin
        (set! failures (+ failures 1))
        (format #t "FAIL ~a\n     got:      ~s\n     expected: ~s\n"
                label got expected))))

;;; --- multiset helpers ------------------------------------------------------
(let ((ms (list->ms '((a . 2) (b . 1)))))
  (check "ms-count a" (ms-count ms 'a) 2)
  (check "ms-count missing" (ms-count ms 'zzz) 0)
  (check "ms<=? fits" (ms<=? '((a . 1)) ms) #t)
  (check "ms<=? too big" (ms<=? '((a . 3)) ms) #f)
  (check "ms-sub" (ms-sub ms '((a . 1)) 1) '((a . 1) (b . 1)))
  (check "ms-scale" (ms-scale ms 3) '((a . 6) (b . 3)))
  (check "ms normalization merges" (list->ms '((a . 1) (a . 2))) '((a . 3))))

;;; --- model matching psim fixture mini5 -------------------------------------
;;;
;;;   skin has a*3; rule send: a --> b here + (b)in inner; inner: b --> c*2.
;;;   psim: step1 skin a*3 -> b*3, inner gets b*3; step2 inner b*3 -> c*6.

(define mini5
  '(psystem
    (membrane 0 (label skin) (parent #f)
      (objects ((a . 3)))
      (rules
        (rule send (lhs ((a . 1)))
              (rhs ((b . 1) ((b . 1) (in 1))))))
      (membrane 1 (label inner) (parent 0)
        (objects ())
        (rules
          (rule consume (lhs ((b . 1))) (rhs ((c . 2)))))))))

(let-values (((final events halted) (run mini5 10 #f)))
  (let ((skin (find-membrane final 0))
        (inner (find-membrane final 1)))
    (check "mini5 skin halting objects"
           (membrane-objects skin) '((b . 3)))
    (check "mini5 inner halting objects"
           (membrane-objects inner) '((c . 6))))
  (check "mini5 halted reason"
         (cadr (assoc 'reason (cdr halted))) 'no-applicable-rules)
  (check "mini5 halted steps" (cadr (assoc 'steps (cdr halted))) 2)
  ;; two fired events: step0 send ×3, step1 consume ×3
  (check "mini5 event count" (length events) 2)
  (check "mini5 first event membrane"
         (cadr (assoc 'membrane (cdar events))) 0)
  (check "mini5 second event membrane"
         (cadr (assoc 'membrane (cdr (cadr events)))) 1))

;;; --- send-out: child produces to parent ------------------------------------

(define out-model
  '(psystem
    (membrane 0 (label skin) (parent #f)
      (objects ())
      (rules)
      (membrane 1 (label inner) (parent 0)
        (objects ((x . 1)))
        (rules
          (rule push (lhs ((x . 1))) (rhs (((y . 1) out)))))))))

(let-values (((final events halted) (run out-model 10 #f)))
  (check "send-out reaches parent"
         (membrane-objects (find-membrane final 0)) '((y . 1)))
  (check "send-out empties child"
         (membrane-objects (find-membrane final 1)) '()))

;;; --- priority-free halting with no rules -----------------------------------

(define dead
  '(psystem
    (membrane 0 (label skin) (parent #f)
      (objects ((a . 5)))
      (rules))))

(let-values (((final events halted) (run dead 10 #f)))
  (check "no-rule model halts at step 0"
         (cadr (assoc 'steps (cdr halted))) 0)
  (check "no-rule model no events" (length events) 0))

;;; --- event stream round-trips through write/read ---------------------------

(let-values (((final events halted) (run mini5 10 #f)))
  (let ((txt (with-output-to-string
               (lambda () (write-trace events (current-output-port))))))
    (check "trace writes s-exprs"
           (if (string-contains txt "(fired") #t #f) #t)
    (check "trace is non-empty" (> (string-length txt) 0) #t)))

;;; --- summary ----------------------------------------------------------------

(newline)
(if (zero? failures)
    (format #t "ALL ~a TESTS PASSED\n"  "psystem")
    (begin (format #t "~a FAILURES\n" failures)
           (exit 1)))
