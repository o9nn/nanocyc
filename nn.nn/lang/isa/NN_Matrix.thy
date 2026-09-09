(*  Theory:  NN_Matrix
    Derived from: docs/integrations.zpp Section 1 (MatrixMultiply,
    Transpose contracts) and the sibling matrix operations.
*)

theory NN_Matrix
  imports NN_Vector
begin

section \<open>Matrix-vector multiplication\<close>

text \<open>
  MatrixMultiply contract (integrations.zpp Section 1): the matrix is a
  list of row vectors; each output component is the dot product of a row
  with the input vector.
\<close>
definition matrix_vector_mult :: "mat \<Rightarrow> vec \<Rightarrow> vec" where
  "matrix_vector_mult m v = map (\<lambda>row. dot_product row v) m"

lemma length_matrix_vector_mult [simp]:
  "length (matrix_vector_mult m v) = length m"
  by (simp add: matrix_vector_mult_def)

section \<open>Transpose\<close>

text \<open>
  Transpose contract: \<open>result(i, j) = m(j, i)\<close>.  Defined by recursion on
  the row count of the transposed matrix, mirroring the sibling
  \<open>(apply map list matrix)\<close> for rectangular matrices.
\<close>
function transpose_matrix :: "mat \<Rightarrow> mat" where
  "transpose_matrix [] = []"
| "transpose_matrix ([] # _) = []"
| "transpose_matrix ((x # xs) # rest) =
     (x # map hd rest) # transpose_matrix (xs # map tl rest)"
  by pat_completeness auto

text \<open>
  Each step peels one entry off the first row, so \<open>length (hd m)\<close> is a
  decreasing measure.  (The default \<open>size\<close> measure does not work here
  because relating \<open>map tl rest\<close> to \<open>rest\<close> needs an induction.)
\<close>
termination transpose_matrix
  by (relation "measure (\<lambda>m. length (hd m))") auto

lemma transpose_matrix_nil [simp]: "transpose_matrix [] = []"
  by simp

text \<open>Dimension contract: transposing an \<open>n \<times> k\<close> matrix yields \<open>k\<close> rows.\<close>
lemma length_transpose_matrix:
  assumes "wf_mat m k" and "m \<noteq> []"
  shows "length (transpose_matrix m) = k"
  using assms
proof (induct m arbitrary: k rule: transpose_matrix.induct)
  case 1 then show ?case by simp
next
  case (2 rest) then show ?case by (simp add: wf_mat_def)
next
  case (3 x xs rest)
  from 3(2) have kx: "k = Suc (length xs)" by (simp add: wf_mat_def)
  have wf': "wf_mat (xs # map tl rest) (length xs)"
    using 3(2) by (auto simp: wf_mat_def kx)
  have "length (transpose_matrix (xs # map tl rest)) = length xs"
    using 3(1)[OF wf'] by simp
  with kx show ?case by simp
qed

text \<open>Each row of the transpose has as many entries as the original had rows.\<close>
lemma transpose_matrix_row_lengths:
  assumes "wf_mat m k"
  shows "\<forall>row \<in> set (transpose_matrix m). length row = length m"
  using assms
proof (induct m arbitrary: k rule: transpose_matrix.induct)
  case 1 then show ?case by simp
next
  case 2 then show ?case by simp
next
  case (3 x xs rest)
  from 3(2) have kx: "k = Suc (length xs)" by (simp add: wf_mat_def)
  have wf': "wf_mat (xs # map tl rest) (length xs)"
    using 3(2) by (auto simp: wf_mat_def kx)
  have hdlen: "length (x # map hd rest) = Suc (length rest)" by simp
  from 3(1)[OF wf'] show ?case
    by (auto simp: hdlen)
qed

end
