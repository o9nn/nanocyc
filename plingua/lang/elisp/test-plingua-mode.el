;;; test-plingua-mode.el --- ERT tests for plingua-mode -*- lexical-binding: t; -*-
;;
;; Run:  emacs -Q --batch -L . -l test-plingua-mode.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'plingua-mode)

(defconst plingua-test--trace
  "(seed 0) (steps 100) (model \"t.pli\")
(fired (step 0) (membrane 0) (rule send) (consumed ((a . 3))) (produced ((b . 3) ((b . 3) (in 1)))))
(checkpoint (step 1) (membrane 0 (label skin) (parent -1) (objects ((b . 3)))) (membrane 1 (label inner) (parent 0) (objects ((b . 3)))))
(fired (step 1) (membrane 1) (rule consume) (consumed ((b . 3))) (produced ((c . 6) here)))
(checkpoint (step 2) (membrane 0 (label skin) (parent -1) (objects ((b . 3)))) (membrane 1 (label inner) (parent 0) (objects ((c . 6)))))
(halted (steps 2) (reason no-applicable-rules))
")

(ert-deftest plingua-parse-trace ()
  (let ((d (plingua--parse-trace plingua-test--trace)))
    (should (= 2 (length (plist-get d :events))))
    (should (= 2 (length (plist-get d :checkpoints))))
    (should (eq 'halted (car (plist-get d :halted))))
    (should (eq 'seed (car (plist-get d :meta))))))

(ert-deftest plingua-glyph-tree ()
  (let* ((d (plingua--parse-trace plingua-test--trace))
         (cp (cadr (plist-get d :checkpoints)))   ; step 2 checkpoint
         (glyph (plingua--glyph-lines cp)))
    ;; skin box, inner box, and the objects row
    (should (cl-some (lambda (l) (string-match-p "\\[0\\]skin" l)) glyph))
    (should (cl-some (lambda (l) (string-match-p "\\[1\\]inner" l)) glyph))
    (should (cl-some (lambda (l) (string-match-p "c c c" l)) glyph))))

(ert-deftest plingua-wire-filtering ()
  (let* ((d (plingua--parse-trace plingua-test--trace)))
    (should (= 1 (length (plingua--wire-lines (plist-get d :events) 0))))
    (should (= 1 (length (plingua--wire-lines (plist-get d :events) 1))))
    (should (= 0 (length (plingua--wire-lines (plist-get d :events) 9))))))

(ert-deftest plingua-render-three-panes ()
  (let* ((d (plingua--parse-trace plingua-test--trace))
         (text (plingua--render-step d 1)))
    (should (string-match-p "--glyph" text))
    (should (string-match-p "--wire" text))
    (should (string-match-p "--checkpoint" text))
    (should (string-match-p "checkpoint (step 1)" text))))

(ert-deftest plingua-ascii-fallback ()
  (let ((plingua-use-unicode nil))
    (let* ((d (plingua--parse-trace plingua-test--trace))
           (cp (cadr (plist-get d :checkpoints)))
           (glyph (plingua--glyph-lines cp)))
      (should (cl-some (lambda (l) (string-match-p "\\+-" l)) glyph)))))

;;; test-plingua-mode.el ends here
