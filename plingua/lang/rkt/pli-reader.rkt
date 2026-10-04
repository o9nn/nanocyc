#lang racket
;;; pli-reader.rkt --- Read the standard P-Lingua transition subset into the
;;; canonical s-expression kernel format (see plingua/lang/scm/psystem.scm).
;;;
;;; This is the reader half of "#lang plingua": it turns a .pli source file
;;; (the psim-runnable transition grammar) into the SAME nested s-expression
;;; the Scheme kernel consumes, so one semantic core serves both text surfaces.
;;;
;;; Supported subset (the standard transition model):
;;;   @model<transition>            (ignored beyond a sanity check)
;;;   @include "file"               (ignored; the harness passes -I already)
;;;   def main() { ... }            (the single module body)
;;;   @mu = <nested bracket tree>;  (membrane structure; labels via 'name)
;;;   @ms(<label>) = obj*count, obj;  (initial multisets)
;;;   [lhs --> rhs]'label;          (evolution / send-in / send-out rules)
;;;
;;; Rule surface forms accepted:
;;;   [a --> b, c]'skin;                      rewrite in place
;;;   [a [ ]'inner --> b [b]'inner]'skin;     send b into child `inner`
;;;   [a --> b [c]'inner]'skin;               (a stays as b; c sent in)
;;;
;;; Output: a quoted (psystem (membrane <id> ...) ...) s-expression where each
;;; membrane gets a numeric id (skin = 0) so the kernel's (in <id>) routing
;;; works.  Communication targets are expressed as kernel products:
;;;   (sym . n) | ((sym . n) out) | ((sym . n) (in <id>)).

(provide parse-pli-file pli->sexpr)

;;; ===========================================================================
;;; Tokenizer
;;; ===========================================================================

(define (tokenize str)
  ;; strip /* */ and // comments, then split into meaningful tokens
  (define no-block (regexp-replace* #rx"(?s:/\\*.*?\\*/)" str " "))
  (define no-line (regexp-replace* #rx"//[^\n]*" no-block " "))
  (regexp-match* #px"-->|<=|>=|==|@[A-Za-z_]+\\w*|<\\w+>|\\d+|[A-Za-z_]\\w*|[\\[\\](){}'=,;.:*]"
                 no-line))

;;; ===========================================================================
;;; Parser (recursive descent over the token list)
;;; ===========================================================================

(struct parser (tokens pos) #:mutable #:transparent)

(define (peek p)
  (if (< (parser-pos p) (length (parser-tokens p)))
      (list-ref (parser-tokens p) (parser-pos p))
      #f))

(define (next! p)
  (begin0 (peek p) (set-parser-pos! p (add1 (parser-pos p)))))

(define (expect p tok)
  (let ((got (next! p)))
    (unless (equal? got tok)
      (error 'pli-reader "expected ~a, got ~a" tok got))
    got))

;;; --- membrane structure tree --------------------------------------------
;;; @mu = [ <child>... ]'label ;   where <child> is [ ... ]'label (recursive)
;;; Returns a nested list: (label child1 child2 ...)

(define (parse-mu p)
  ;; at a '['
  (expect p "[")
  (let loop ((children '()))
    (if (equal? (peek p) "[")
        (loop (cons (parse-mu p) children))
        (begin
          (expect p "]")
          (expect p "'")
          (let ((label (string->symbol (next! p))))
            (cons label (reverse children)))))))

;;; --- multisets -------------------------------------------------------------
;;; @ms(skin) = a*3, b ;   ->  ((a . 3) (b . 1))

(define (parse-multiset p)
  ;; parse until ';' ; items: SYMBOL [* NUMBER]
  (let loop ((acc '()))
    (define tok (peek p))
    (cond
      ((or (equal? tok ";") (equal? tok #f))
       (next! p)                       ; consume ';'
       (reverse acc))
      ((equal? tok ",")
       (next! p) (loop acc))
      (else
       (define sym (string->symbol (next! p)))
       (define n
         (if (equal? (peek p) "*")
             (begin (next! p) (string->number (next! p)))
             1))
       (loop (cons (cons sym n) acc))))))

;;; --- rules -----------------------------------------------------------------
;;; [ ... ]'label ;   We parse the inner content as a flat token list and then
;;; interpret it: split on '-->', LHS before, RHS after.  Inner membranes are
;;; [ ... ]'name on either side.

;; Read tokens of one rule body (between the outer '[' and the matching
;; "] ' label ;"), collecting nested brackets.
(define (read-rule-tokens p)
  ;; assumes opening '[' already consumed
  (let loop ((depth 1) (acc '()))
    (define tok (next! p))
    (cond
      ((equal? tok #f) (error 'pli-reader "unterminated rule"))
      ((equal? tok "[") (loop (add1 depth) (cons tok acc)))
      ((equal? tok "]")
       (if (= depth 1)
           (reverse acc)              ; don't include the closing ']'
           (loop (sub1 depth) (cons tok acc))))
      (else (loop depth (cons tok acc))))))

;; Interpret the flat rule tokens into lhs-products and rhs-products.
;; Returns (values home-lhs-ms rhs-products) where rhs-products use the
;; kernel's (in <label>) form (labels resolved to ids later).
(define (interpret-rule toks)
  (define split (index-of toks "-->"))
  (define lhs-toks (if split (take toks split) toks))
  (define rhs-toks (if split (drop toks (add1 split)) '()))
  (values (parse-side lhs-toks) (parse-side rhs-toks)))

;; Parse one side: a sequence of plain objects (sym [* n]) separated by commas,
;; plus nested membrane brackets [ <inside> ]'name.  Returns a list:
;;   (objs <multiset-alist>) (sends ((name . multiset) ...))
(define (parse-side toks)
  (let loop ((ts toks) (objs '()) (sends '()))
    (cond
      ((null? ts) (list (cons 'objs (reverse objs))
                        (cons 'sends (reverse sends))))
      ((equal? (car ts) "[")
       ;; find matching close, capture inner + label
       (let inner-loop ((rest (cdr ts)) (depth 1) (inner '()))
         (cond
           ((null? rest) (error 'pli-reader "unterminated inner membrane"))
           ((equal? (car rest) "[") (inner-loop (cdr rest) (add1 depth) (cons "[" inner)))
           ((equal? (car rest) "]")
            (if (= depth 1)
                ;; expect ' name
                (let* ((rest1 (cdr rest)))
                  (if (and (pair? rest1) (equal? (car rest1) "'"))
                      (let ((name (string->symbol (cadr rest1))))
                        (define parsed-inner (parse-side (reverse inner)))
                        (loop (cddr rest1) objs
                              (cons (cons name (cdr (assoc 'objs parsed-inner)))
                                    sends)))
                      (error 'pli-reader "expected ' label after ]")))
                (inner-loop (cdr rest) (sub1 depth) (cons "]" inner))))
           (else (inner-loop (cdr rest) depth (cons (car rest) inner))))))
      ((equal? (car ts) ",") (loop (cdr ts) objs sends))
      (else
       (define sym (string->symbol (car ts)))
       (cond
         ((and (pair? (cdr ts)) (equal? (cadr ts) "*"))
          (loop (cdddr ts) (cons (cons sym (string->number (caddr ts))) objs) sends))
         (else
          (loop (cdr ts) (cons (cons sym 1) objs) sends)))))))

;;; ===========================================================================
;;; Whole-file parse → canonical s-expr
;;; ===========================================================================

(define (parse-pli-file path)
  (pli->sexpr (file->string path)))

(define (pli->sexpr src)
  (define p (parser (tokenize src) 0))
  (define mu (box #f))
  (define multisets (make-hash))       ; label -> alist
  (define rules '())                   ; list of (label lhs-ms rhs-objs rhs-sends)

  ;; walk top-level tokens
  (let loop ()
    (define tok (peek p))
    (when tok
      (cond
        ((equal? tok "@mu")
         (next! p) (expect p "=")
         (set-box! mu (parse-mu p))
         (expect p ";"))
        ((equal? tok "@ms")
         (next! p) (expect p "(")
         (define label (string->symbol (next! p)))
         (expect p ")") (expect p "=")
         (hash-set! multisets label (parse-multiset p)))
        ((equal? tok "[")
         (next! p)
         (define toks (read-rule-tokens p))
         (expect p "'")
         (define label (string->symbol (next! p)))
         (expect p ";")
         (define-values (lhs rhs) (interpret-rule toks))
         (set! rules (cons (list label lhs rhs) rules)))
        (else (next! p)))              ; skip @model/@include/def/main/braces
      (loop)))

  ;; assign numeric ids breadth-first, skin (root) = 0
  (define tree (unbox mu))
  (unless tree (error 'pli-reader "missing @mu"))
  (define label->id (make-hash))
  (let assign ((node tree) (id 0))
    (hash-set! label->id (car node) id)
    (let loop ((kids (cdr node)) (next (add1 id)))
      (if (null? kids) next
          (loop (cdr kids) (assign (car kids) next)))))
  ;; The simple sequential assign above is depth-first; recompute breadth-first
  ;; so children of a parent are contiguous and deterministic.
  (define bfs-order
    (let bfs ((queue (list tree)) (acc '()))
      (if (null? queue) (reverse acc)
          (let ((node (car queue)))
            (bfs (append (cdr queue) (cdr node)) (cons (car node) acc))))))
  (set! label->id (make-hash))
  (for ((lbl bfs-order) (i (in-naturals)))
    (hash-set! label->id lbl i))

  ;; build membrane records
  (define (build node parent-id)
    (define label (car node))
    (define id (hash-ref label->id label))
    (define my-rules
      (filter-map
       (lambda (r)
         (and (eq? (car r) label)
              (let* ((lhs-side (cadr r))
                     (rhs-side (caddr r))
                     (lhs-ms (cdr (assoc 'objs lhs-side)))
                     (rhs-objs (cdr (assoc 'objs rhs-side)))
                     (rhs-sends (cdr (assoc 'sends rhs-side)))
                     (rhs-products
                      (append rhs-objs
                              ;; each send expands to a list of products
                              (append-map (lambda (s)
                                            (map-products-in s label->id))
                                          rhs-sends))))
                `(rule r (lhs ,lhs-ms) (rhs ,rhs-products)))))
       (reverse rules)))
    `(membrane ,id (label ,label) (parent ,parent-id)
               (objects ,(hash-ref multisets label '()))
               (rules ,@my-rules)
               ,@(map (lambda (c) (build c id)) (cdr node))))

  `(psystem ,(build tree #f)))

;; expand a (label . multiset) send into kernel products ((sym . n) (in id))
(define (map-products-in send label->id)
  (define id (hash-ref label->id (car send)))
  (map (lambda (pair) `((,(car pair) . ,(cdr pair)) (in ,id))) (cdr send)))

;;; --- demo / REPL entry -----------------------------------------------------

(module+ main
  (require racket/pretty)
  (define path (vector-ref (current-command-line-arguments) 0))
  (pretty-print (parse-pli-file path)))
