;;; psystem.scm --- Pure s-expression membrane computing kernel (L-Lingua core)
;;;
;;; A P system *is* a nested s-expression: the membrane structure is a tree,
;;; a multiset is an association list ((symbol . count) ...), a configuration
;;; is one s-expression, and a computation is a sequence of configurations.
;;; The program text is the membrane.
;;;
;;; This is the host-agnostic reference kernel.  It depends only on R7RS-small
;;; under Guile; every dialect (Guile, Racket, Elisp, CL, élan) implements the
;;; SAME three functions over the SAME data format:
;;;
;;;   match-rules  — find rule instances whose LHS ⊆ membrane multiset
;;;   apply-step   — one maximally-parallel evolution step (consume LHS,
;;;                  produce RHS, route (in k) / out / here)
;;;   run          — iterate to halting, yielding the s-expr event stream
;;;
;;; Canonical model format (a quoted s-expression — both data and program):
;;;
;;;   (psystem
;;;     (membrane 1 (label skin)
;;;       (objects (a . 2))                       ; multiset: a×2
;;;       (rules
;;;         (rule send (lhs (a . 1)) (rhs (((b . 1) (in 2))))))
;;;       (membrane 2 (label inner) (parent 1)
;;;         (objects)
;;;         (rules
;;;           (rule consume (lhs (b . 1)) (rhs ((c . 1))))))))
;;;
;;; RHS products are a list of products.  A product is one of:
;;;   (sym . count)                 → stays here
;;;   ((sym . count) out)           → send to parent membrane
;;;   ((sym . count) (in <id>))     → send into the child membrane <id>
;;;
;;; Determinism: with random? = #f the kernel applies every applicable rule as
;;; many times as possible (maximal parallelism), the default semantics of the
;;; bundled C++ simulator (psim).  A host RNG is consulted only when random? is
;;; requested, keeping golden traces reproducible.

(define-module (plingua psystem)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:export (;; multisets
            ms-empty ms-count ms-add ms-sub ms-scale ms<=? ms-null?
            ms->list list->ms
            ;; model accessors
            psystem-membranes psystem-root find-membrane
            membrane-id membrane-label membrane-parent
            membrane-objects membrane-rules membrane-children
            rule-name rule-lhs rule-rhs
            ;; kernel
            match-rules applicable? apply-step halting? run
            ;; s-expr I/O
            configuration->sexpr sexpr->psystem write-trace))

;;; ---------------------------------------------------------------------------
;;; Multisets: association lists ((symbol . count) ...) with count > 0, kept
;;; sorted by symbol name so two equal multisets are `equal?`.
;;; ---------------------------------------------------------------------------

(define (ms-empty) '())
(define (list->ms pairs) (normalize-ms pairs))
(define (ms->list ms) ms)
(define (ms-count ms sym) (or (assoc-ref ms sym) 0))
(define (ms-null? ms) (null? ms))
(define (ms-add ms sym n) (normalize-ms (cons (cons sym n) ms)))
(define (ms-scale ms k) (map (lambda (p) (cons (car p) (* (cdr p) k))) ms))

(define (normalize-ms pairs)
  (let ((h (make-hash-table)))
    (for-each (lambda (p)
                (hash-set! h (car p) (+ (cdr p) (or (hash-ref h (car p)) 0))))
              pairs)
    (sort (filter (lambda (p) (> (cdr p) 0)) (hash-map->list cons h))
          (lambda (a b) (string<? (symbol->string (car a))
                                  (symbol->string (car b)))))))

;; does `sub` fit inside `ms`, pointwise?
(define (ms<=? sub ms)
  (every (lambda (p) (>= (ms-count ms (car p)) (cdr p))) sub))

;; subtract `sub` scaled by k from `ms`; assumes it fits
(define (ms-sub ms sub k)
  (normalize-ms
   (append ms (map (lambda (p) (cons (car p) (- (* (cdr p) k)))) sub))))

;;; ---------------------------------------------------------------------------
;;; Model representation.  A psystem is a single nested s-expression; the
;;; configuration IS the tree, so it round-trips through write/read losslessly.
;;;
;;; membrane := (membrane <id> (label <sym>) (parent <id|#f>)
;;;                        (objects <ms>) (rules <rule> ...) <child> ...)
;;; rule     := (rule <name> (lhs <ms>) (rhs <product> ...))
;;; ---------------------------------------------------------------------------

(define (membrane? x) (and (pair? x) (eq? (car x) 'membrane)))
(define (membrane-id m) (cadr m))
(define (membrane-label m) (cadr (assoc 'label (cddr m))))
(define (membrane-parent m)
  (let ((p (assoc 'parent (cddr m)))) (and p (cadr p))))
(define (membrane-objects m)
  (let ((o (assoc 'objects (cddr m)))) (if o (cadr o) '())))
(define (membrane-rules m)
  (let ((r (assoc 'rules (cddr m)))) (if r (cdr r) '())))
(define (membrane-children m) (filter membrane? (cddr m)))

(define (rule-name r) (cadr r))
(define (rule-lhs r) (cadr (assoc 'lhs (cddr r))))
(define (rule-rhs r) (let ((x (assoc 'rhs (cddr r)))) (if x (cadr x) '())))

(define (psystem-root psys) (find membrane? (cdr psys)))

(define (psystem-membranes psys)
  (let walk ((m (psystem-root psys)))
    (cons m (append-map walk (membrane-children m)))))

(define (find-membrane psys id)
  (find (lambda (m) (= (membrane-id m) id)) (psystem-membranes psys)))

;;; ---------------------------------------------------------------------------
;;; match-rules: for one membrane, the list of (rule . max-applications).
;;; ---------------------------------------------------------------------------

(define (rule-max-applications objects lhs)
  (if (null? lhs)
      0
      (apply min (map (lambda (p)
                        (quotient (ms-count objects (car p)) (cdr p)))
                      lhs))))

(define (match-rules membrane)
  (let ((objects (membrane-objects membrane)))
    (filter-map
     (lambda (r)
       (let ((n (rule-max-applications objects (rule-lhs r))))
         (and (> n 0) (cons r n))))
     (membrane-rules membrane))))

(define (applicable? membrane)
  (not (null? (match-rules membrane))))

;;; ---------------------------------------------------------------------------
;;; RHS products.  A product is (sym . count) | ((sym . count) out)
;;; | ((sym . count) (in id)).
;;; ---------------------------------------------------------------------------

(define (product-pair prod)
  (if (and (pair? prod) (pair? (car prod))) (car prod) prod))

(define (product-target prod)
  (if (and (pair? prod) (pair? (car prod)) (pair? (cdr prod)))
      (cadr prod)
      'here))

(define (scale-pair pair n) (cons (car pair) (* (cdr pair) n)))

;; fold a scaled product into the inbox alist keyed by target
(define (inbox-add ib target pair)
  (let ((cur (assoc-ref ib target)))
    (cons (cons target (normalize-ms (cons pair (or cur '()))))
          (alist-delete target ib))))

;; replace a membrane's objects and children, preserving id/label/parent/rules
(define (rebuild-membrane m objs kids)
  `(membrane ,(membrane-id m)
             (label ,(membrane-label m))
             (parent ,(membrane-parent m))
             (objects ,objs)
             (rules ,@(membrane-rules m))
             ,@kids))

(define (with-objects m objs)
  (rebuild-membrane m objs (membrane-children m)))

;;; ---------------------------------------------------------------------------
;;; apply-step: one maximally-parallel evolution step over the whole tree.
;;; Returns (values new-psystem events).  Each event is an s-expr:
;;;   (fired (step k) (membrane id) (rule name)
;;;          (consumed ((sym . n) ...)) (produced (((sym . n) target) ...)))
;;; ---------------------------------------------------------------------------

;; Evolve one membrane's own rules.
;; Returns (values remaining-objects inbox events).
(define (evolve-membrane m step random?)
  (let loop ((apps (match-rules m))
             (objs (membrane-objects m))
             (inbox '())
             (events '()))
    (if (null? apps)
        (values objs inbox (reverse events))
        (let* ((rule (caar apps))
               (maxn (cdar apps))
               (n (if random? (random (+ maxn 1)) maxn)))
          (if (<= n 0)
              (loop (cdr apps) objs inbox events)
              (let ((inbox*
                     (fold (lambda (prod ib)
                             (inbox-add ib (product-target prod)
                                        (scale-pair (product-pair prod) n)))
                           inbox (rule-rhs rule))))
                (loop (cdr apps)
                      (ms-sub objs (rule-lhs rule) n)
                      inbox*
                      (cons (list 'fired
                                  (list 'step step)
                                  (list 'membrane (membrane-id m))
                                  (list 'rule (rule-name rule))
                                  (list 'consumed (ms-scale (rule-lhs rule) n))
                                  (list 'produced
                                        (map (lambda (prod)
                                               (list (scale-pair
                                                      (product-pair prod) n)
                                                     (product-target prod)))
                                             (rule-rhs rule))))
                            events))))))))

;; Recursively step a node.  A membrane evolves its OWN rules from the objects
;; it held at the START of the step.  Communication products are delivered to
;; the *resulting* configuration (available next step), never consumed within
;; the step that produced them — this matches psim exactly:
;;   - "here"      products stay in this membrane's result
;;   - "(in id)"   products land in that child's result
;;   - "out"       products land in this membrane's parent's result
;;   - child "out" products land in THIS membrane's result
;; Returns (values new-membrane outgoing-multiset events).
(define (step-node m step random?)
  (let-values (((own inbox evs) (evolve-membrane m step random?)))
    ;; `here`: this membrane's post-step objects BEFORE communication arrives
    ;; from children; `outgoing` goes up to the parent.
    (let ((here (normalize-ms
                 (append own (or (assoc-ref inbox 'here) '()))))
          (outgoing (or (assoc-ref inbox 'out) '())))
      (let loop ((kids (membrane-children m))
                 (acc '())
                 (here here)            ; accumulates children's "out" products
                 (kevs '()))
        (if (null? kids)
            (values (rebuild-membrane m here (reverse acc)) outgoing
                    (append evs kevs))
            (let* ((c (car kids))
                   ;; products addressed "(in c)" arrive in c's RESULT
                   (child-in (or (assoc-ref inbox (list 'in (membrane-id c)))
                                 '())))
              (let-values (((nc child-out cevs) (step-node c step random?)))
                (loop (cdr kids)
                      (cons (with-objects nc
                              (normalize-ms
                               (append (membrane-objects nc) child-in)))
                            acc)
                      (normalize-ms (append here child-out))
                      (append kevs cevs)))))))))

(define (apply-step psys step random?)
  (let-values (((new-root skin-out events)
                (step-node (psystem-root psys) step random?)))
    ;; Objects sent "out" of the skin go to the environment.  They are dropped
    ;; from the configuration but could be surfaced in the trace if needed.
    (values `(psystem ,new-root) events)))

;;; ---------------------------------------------------------------------------
;;; halting? and run
;;; ---------------------------------------------------------------------------

(define (halting? psys)
  (not (any applicable? (psystem-membranes psys))))

;; run to halting or max-steps; returns (values final events halted-event)
(define (run psys max-steps random?)
  (let loop ((ps psys) (k 0) (evs '()))
    (if (or (>= k max-steps) (halting? ps))
        (values ps (reverse evs)
                (list 'halted (list 'steps k)
                      (list 'reason (if (halting? ps)
                                        'no-applicable-rules
                                        'max-steps))))
        (let-values (((ps* events) (apply-step ps k random?)))
          (loop ps* (+ k 1) (append (reverse events) evs))))))

;;; ---------------------------------------------------------------------------
;;; s-expr I/O.  The configuration IS the psystem tree — already an s-expr.
;;; ---------------------------------------------------------------------------

(define (configuration->sexpr psys) psys)
(define (sexpr->psystem sx) sx)

(define (write-trace events port)
  (for-each (lambda (e) (write e port) (newline port)) events))
