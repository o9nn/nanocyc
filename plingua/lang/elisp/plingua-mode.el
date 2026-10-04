;;; plingua-mode.el --- three-pane P-Lingua trace display for Emacs -*- lexical-binding: t; -*-
;;
;; Renders the psim / L-Lingua s-expr trace as three synchronized panes:
;;
;;   --glyph      the membrane tree as box-drawing art, annotated with objects
;;   --wire       the (fired ...) event stream, one line per rule application
;;   --checkpoint the full configuration as a readable s-expr per step
;;
;; This is the display half of the L-Lingua layer: it consumes the SAME
;; s-expr stream that bin/psim --trace=sexpr and the Scheme/Racket kernels
;; emit, proving the format's portability across engines and hosts.
;;
;; Usage:
;;   M-x plingua-run RET /path/to/model.pli RET     compile + simulate + display
;;   M-x plingua-display-trace RET /path/trace RET  render a saved trace file
;;
;; In the trace buffer:
;;   n / p   step forward / back one step
;;   g       rebuild the panes from the trace
;;   q       quit

;;; Code:

(require 'cl-lib)

(defgroup plingua nil "P-Lingua trace display." :group 'languages)

(defcustom plingua-psim-command "psim"
  "Command used to run the simulator."
  :type 'string)

(defcustom plingua-plingua-command "plingua"
  "Command used to compile a .pli to JSON."
  :type 'string)

(defcustom plingua-use-unicode t
  "Non-nil to use Unicode box-drawing in the --glyph pane."
  :type 'boolean)

;;; ---------------------------------------------------------------------------
;;; Parsing the s-expr trace
;;; ---------------------------------------------------------------------------
;;
;; The trace is a line-oriented s-expr stream:
;;   (seed N) (steps N) (model "FILE")
;;   (fired (step K) (membrane ID) (rule R) (consumed MS) (produced MS))
;;   (checkpoint (step K) (membrane ID (label L) (parent P) (objects MS)) ...)
;;   (halted (steps K) (reason R))
;;
;; We parse it with Emacs' own reader.

(defun plingua--parse-trace (text)
  "Parse trace TEXT into a plist (:meta :events :checkpoints :halted)."
  (let ((events '()) (checkpoints '()) (meta nil) (halted nil))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (condition-case nil
          (while t
            (let ((form (read (current-buffer))))
              (pcase (car-safe form)
                ('seed (setq meta form))
                ('fired (push form events))
                ('checkpoint (push form checkpoints))
                ('halted (setq halted form)))))
        (end-of-file nil)))
    (list :meta meta
          :events (nreverse events)
          :checkpoints (nreverse checkpoints)
          :halted halted)))

;;; ---------------------------------------------------------------------------
;;; Glyph pane: membrane tree as box art
;;; ---------------------------------------------------------------------------

(defun plingua--ms-objects-string (ms)
  "Render multiset MS ((sym . n) ...) as \"b b b\"."
  (mapconcat (lambda (p) (make-string (cdr p) ? )) ms ""))

(defun plingua--objects-inline (ms)
  "Render multiset MS as space-separated repeated symbols."
    (let (parts)
      (dolist (p ms)
        (dotimes (_ (cdr p)) (push (symbol-name (car p)) parts)))
      (mapconcat #'identity (nreverse parts) " ")))

(defun plingua--glyph-lines (checkpoint)
  "Render the membrane tree of CHECKPOINT as box-drawing lines."
  (let* ((mems (cddr checkpoint))          ; drop 'checkpoint (step k)
         (by-id (make-hash-table)))
    (dolist (m mems)
      (puthash (cadr m) m by-id))
    (let ((lines '())
          (tl (if plingua-use-unicode "╭" "+"))
          (tr (if plingua-use-unicode "╮" "+"))
          (bl (if plingua-use-unicode "╰" "+"))
          (br (if plingua-use-unicode "╯" "+"))
          (hz (if plingua-use-unicode "─" "-"))
          (vt (if plingua-use-unicode "│" "|")))
      (cl-labels
          ((render (m depth)
             (let* ((id (cadr m))
                    (label (cadr (assoc 'label (cddr m))))
                    (objects (cadr (assoc 'objects (cddr m))))
                    (children
                     (cl-loop for c in mems
                              when (equal (cadr (assoc 'parent (cddr c))) id)
                              collect c))
                    (indent (make-string (* 2 depth) ? ))
                    (name (format "[%s]%s" id label))
                    (rule (make-string (+ 2 (length name))
                                       (aref hz 0))))
               (push (concat indent tl rule tr) lines)
               (push (concat indent vt " " name " " vt "  "
                             (plingua--objects-inline objects))
                     lines)
               (dolist (c children) (render c (1+ depth)))
               (push (concat indent bl rule br) lines))))
        (dolist (m mems)
          (when (equal (cadr (assoc 'parent (cddr m))) -1)
            (render m 0))))
      (nreverse lines))))

;;; ---------------------------------------------------------------------------
;;; Wire pane: the (fired ...) events for one step
;;; ---------------------------------------------------------------------------

(defun plingua--wire-lines (events step)
  "Return the (fired ...) lines of EVENTS belonging to STEP."
  (cl-loop for e in events
           when (equal (cadr (assoc 'step (cdr e))) step)
           collect (format "%s" e)))

;;; ---------------------------------------------------------------------------
;;; Checkpoint pane
;;; ---------------------------------------------------------------------------

(defun plingua--checkpoint-lines (checkpoint)
  "Pretty-print CHECKPOINT across short lines."
  (let ((lines (list (format "(checkpoint (step %s)"
                             (cadr (assoc 'step (cdr checkpoint)))))))
    (dolist (m (cddr checkpoint))
      (push (format "  (membrane %s (label %s) (objects %s))"
                    (cadr m)
                    (cadr (assoc 'label (cddr m)))
                    (cadr (assoc 'objects (cddr m))))
            lines))
    (setq lines (nreverse lines))
    (setf (car (last lines))
          (concat (car (last lines)) ")"))
    lines))

;;; ---------------------------------------------------------------------------
;;; Three-pane layout
;;; ---------------------------------------------------------------------------

(defun plingua--pad (s w)
  (let ((dw (length s)))
    (if (< dw w) (concat s (make-string (- w dw) ? )) s)))

(defun plingua--render-step (trace-data step)
  "Return the three-pane text for STEP from TRACE-DATA."
  (let* ((events (plist-get trace-data :events))
         (checkpoints (plist-get trace-data :checkpoints))
         (glyph '())
         (check '())
         (wire (plingua--wire-lines events step)))
    (let ((cp (cl-find-if (lambda (c)
                            (equal (cadr (assoc 'step (cdr c))) step))
                          checkpoints)))
      (when cp
        (setq glyph (plingua--glyph-lines cp))
        (setq check (plingua--checkpoint-lines cp))))
    (let* ((GW 34) (WW 50)
           (hdr (concat (plingua--pad "--glyph" GW)
                        (plingua--pad "--wire" WW) "--checkpoint"))
           (rows (max (length glyph) (max (length wire) (length check))))
           (out (list hdr)))
      (dotimes (i rows)
        (push (concat (plingua--pad (or (nth i glyph) "") GW)
                      (plingua--pad (or (nth i wire) "") WW)
                      (or (nth i check) ""))
              out))
      (mapconcat #'identity (nreverse out) "\n"))))

;;; ---------------------------------------------------------------------------
;;; Interactive trace buffer
;;; ---------------------------------------------------------------------------

(defvar-local plingua--trace-data nil)
(defvar-local plingua--step 0)

(defun plingua--refresh ()
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (format ";; plingua trace — step %d  (n/p: step, q: quit)\n\n"
                    plingua--step))
    (insert (plingua--render-step plingua--trace-data plingua--step))
    (insert "\n")))

(defun plingua-next-step ()
  (interactive)
  (setq plingua--step (1+ plingua--step))
  (plingua--refresh))

(defun plingua-prev-step ()
  (interactive)
  (when (> plingua--step 0)
    (setq plingua--step (1- plingua--step))
    (plingua--refresh)))

;;;###autoload
(define-derived-mode plingua-trace-mode special-mode "PLingua-Trace"
  "Major mode for viewing P-Lingua three-pane traces."
  (define-key plingua-trace-mode-map (kbd "n") #'plingua-next-step)
  (define-key plingua-trace-mode-map (kbd "p") #'plingua-prev-step)
  (define-key plingua-trace-mode-map (kbd "q") #'quit-window))

;;;###autoload
(defun plingua-display-trace (file)
  "Render the saved s-expr trace FILE as a three-pane display."
  (interactive "fTrace file: ")
  (let ((buf (get-buffer-create "*plingua-trace*")))
    (with-current-buffer buf
      (plingua-trace-mode)
      (setq plingua--trace-data
            (plingua--parse-trace (with-temp-buffer
                                    (insert-file-contents file)
                                    (buffer-string))))
      (setq plingua--step 0)
      (plingua--refresh))
    (pop-to-buffer buf)))

(provide 'plingua-mode)
;;; plingua-mode.el ends here
