;;; send_in.scm --- s-expr twin of send_in.pli (see fixtures/README.md)
(define model
  '(psystem
    (membrane 0 (label skin) (parent #f)
      (objects ((a . 3)))
      (rules (rule send (lhs ((a . 1)))
                   (rhs ((b . 1) ((b . 1) (in 1))))))
      (membrane 1 (label inner) (parent 0)
        (objects ())
        (rules (rule consume (lhs ((b . 1))) (rhs ((c . 2)))))))))
