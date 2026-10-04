#lang racket
;;; psystem.rkt --- Racket port of the L-Lingua s-expression kernel.
;;;
;;; Mirrors plingua/lang/scm/plingua/psystem.scm exactly: same data format,
;;; same three functions (match-rules / apply-step / run), same canonical
;;; (fired ...)/(final ...) s-expr streams.  See that file for the format
;;; reference.  Provided here so Racket (and the #lang plingua reader in
;;; pli-reader.rkt) can parse AND simulate a .pli file in one toolchain.

(provide ;; multisets
         ms-count ms-scale ms<=? ms-sub normalize-ms
         ;; accessors
         membrane-id membrane-label membrane-parent
         membrane-objects membrane-rules membrane-children
         rule-name rule-lhs rule-rhs psystem-membranes psystem-root find-membrane
         ;; kernel
         match-rules applicable? apply-step halting? run
         ;; io
         write-trace)

;;; --- multisets --------------------------------------------------------------

(define (normalize-ms pairs)
  (define h (make-hash))
  (for ([p pairs]) (hash-set! h (car p) (+ (cdr p) (hash-ref h (car p) 0))))
  (sort (filter (λ (p) (> (cdr p) 0)) (hash-map h cons))
        (λ (a b) (string<? (symbol->string (car a)) (symbol->string (car b))))))

(define (ms-count ms sym) (or (assoc-ref ms sym) 0))
(define (ms-scale ms k) (map (λ (p) (cons (car p) (* (cdr p) k))) ms))
(define (ms<=? sub ms)
  (andmap (λ (p) (>= (ms-count ms (car p)) (cdr p))) sub))
(define (ms-sub ms sub k)
  (normalize-ms (append ms (map (λ (p) (cons (car p) (- (* (cdr p) k)))) sub))))

;; small assoc-ref for alists of pairs
(define (assoc-ref alist key)
  (let ((cell (assoc key alist))) (and cell (cdr cell))))

;;; --- model accessors ---------------------------------------------------------

(define (membrane? x) (and (pair? x) (eq? (car x) 'membrane)))
(define (membrane-id m) (cadr m))
(define (membrane-label m) (cadr (assoc 'label (cddr m))))
(define (membrane-parent m) (let ((p (assoc 'parent (cddr m)))) (and p (cadr p))))
(define (membrane-objects m) (let ((o (assoc 'objects (cddr m)))) (if o (cadr o) '())))
(define (membrane-rules m) (let ((r (assoc 'rules (cddr m)))) (if r (cdr r) '())))
(define (membrane-children m) (filter membrane? (cddr m)))

(define (rule-name r) (cadr r))
(define (rule-lhs r) (cadr (assoc 'lhs (cddr r))))
(define (rule-rhs r) (let ((x (assoc 'rhs (cddr r)))) (if x (cadr x) '())))

(define (psystem-root psys) (findf membrane? (cdr psys)))
(define (psystem-membranes psys)
  (let walk ((m (psystem-root psys)))
    (cons m (append-map walk (membrane-children m)))))
(define (find-membrane psys id)
  (findf (λ (m) (= (membrane-id m) id)) (psystem-membranes psys)))

(define (rebuild-membrane m objs kids)
  `(membrane ,(membrane-id m) (label ,(membrane-label m))
             (parent ,(membrane-parent m)) (objects ,objs)
             (rules ,@(membrane-rules m)) ,@kids))
(define (with-objects m objs) (rebuild-membrane m objs (membrane-children m)))

;;; --- match -------------------------------------------------------------------

(define (rule-max-applications objects lhs)
  (if (null? lhs) 0
      (apply min (map (λ (p) (quotient (ms-count objects (car p)) (cdr p))) lhs))))

(define (match-rules membrane)
  (let ((objects (membrane-objects membrane)))
    (filter-map (λ (r) (let ((n (rule-max-applications objects (rule-lhs r))))
                         (and (> n 0) (cons r n))))
                (membrane-rules membrane))))

(define (applicable? membrane) (not (null? (match-rules membrane))))

;;; --- products -----------------------------------------------------------------

(define (product-pair prod) (if (and (pair? prod) (pair? (car prod))) (car prod) prod))
(define (product-target prod)
  (if (and (pair? prod) (pair? (car prod)) (pair? (cdr prod))) (cadr prod) 'here))
(define (scale-pair pair n) (cons (car pair) (* (cdr pair) n)))

(define (inbox-add ib target pair)
  (let ((cur (assoc-ref ib target)))
    (cons (cons target (normalize-ms (cons pair (or cur '()))))
          (alist-remove target ib))))
(define (alist-remove key alist) (filter (λ (p) (not (equal? (car p) key))) alist))

;;; --- step ----------------------------------------------------------------------

;; evolve one membrane's rules; returns (values remaining inbox events)
(define (evolve-membrane m step random?)
  (let loop ((apps (match-rules m)) (objs (membrane-objects m))
             (inbox '()) (events '()))
    (if (null? apps)
        (values objs inbox (reverse events))
        (let* ((rule (caar apps)) (maxn (cdar apps))
               (n (if random? (random (add1 maxn)) maxn)))
          (if (<= n 0)
              (loop (cdr apps) objs inbox events)
              (let ((inbox* (foldl (λ (prod ib)
                                     (inbox-add ib (product-target prod)
                                                (scale-pair (product-pair prod) n)))
                                   inbox (rule-rhs rule))))
                (loop (cdr apps)
                      (ms-sub objs (rule-lhs rule) n)
                      inbox*
                      (cons `(fired (step ,step) (membrane ,(membrane-id m))
                                    (rule ,(rule-name rule))
                                    (consumed ,(ms-scale (rule-lhs rule) n))
                                    (produced ,(map (λ (prod)
                                                      (list (scale-pair (product-pair prod) n)
                                                            (product-target prod)))
                                                    (rule-rhs rule))))
                            events))))))))

;; returns (values new-membrane outgoing events)
(define (step-node m step random?)
  (define-values (own inbox evs) (evolve-membrane m step random?))
  (define here0 (normalize-ms (append own (or (assoc-ref inbox 'here) '()))))
  (define outgoing (or (assoc-ref inbox 'out) '()))
  (let loop ((kids (membrane-children m)) (acc '()) (here here0) (kevs '()))
    (if (null? kids)
        (values (rebuild-membrane m here (reverse acc)) outgoing (append evs kevs))
        (let* ((c (car kids))
               (child-in (or (assoc-ref inbox (list 'in (membrane-id c))) '())))
          (define-values (nc child-out cevs) (step-node c step random?))
          (loop (cdr kids)
                (cons (with-objects nc (normalize-ms (append (membrane-objects nc) child-in))) acc)
                (normalize-ms (append here child-out))
                (append kevs cevs))))))

(define (apply-step psys step random?)
  (define-values (new-root skin-out events) (step-node (psystem-root psys) step random?))
  (values `(psystem ,new-root) events))

(define (halting? psys) (not (ormap applicable? (psystem-membranes psys))))

(define (run psys max-steps random?)
  (let loop ((ps psys) (k 0) (evs '()))
    (if (or (>= k max-steps) (halting? ps))
        (values ps (reverse evs)
                (list 'halted (list 'steps k)
                      (list 'reason (if (halting? ps) 'no-applicable-rules 'max-steps))))
        (let-values (((ps* events) (apply-step ps k random?)))
          (loop ps* (add1 k) (append (reverse events) evs))))))

;;; --- io ------------------------------------------------------------------------

(define (write-trace events port)
  (for ([e events]) (write e port) (newline port)))
