;;; two_children.scm --- s-expr twin of two_children.pli
(define model
  '(psystem
    (membrane 0 (label skin) (parent #f)
      (objects ((a . 2)))
      (rules (rule broadcast (lhs ((a . 1)))
                   (rhs ((b . 1) ((p . 1) (in 1)) ((q . 1) (in 2))))))
      (membrane 1 (label left) (parent 0)
        (objects ())
        (rules (rule pl (lhs ((p . 1))) (rhs ((r . 1))))))
      (membrane 2 (label right) (parent 0)
        (objects ())
        (rules (rule pr (lhs ((q . 1))) (rhs ((s . 1)))))))))
