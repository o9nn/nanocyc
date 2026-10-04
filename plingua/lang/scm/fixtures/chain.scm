;;; chain.scm --- s-expr twin of chain.pli (pure rewriting, no communication)
(define model
  '(psystem
    (membrane 0 (label skin) (parent #f)
      (objects ((a . 1)))
      (rules
        (rule ab (lhs ((a . 1))) (rhs ((b . 1))))
        (rule bc (lhs ((b . 1))) (rhs ((c . 1))))
        (rule cd (lhs ((c . 1))) (rhs ((d . 1)))))
      (membrane 1 (label inner) (parent 0)
        (objects ())
        (rules)))))
