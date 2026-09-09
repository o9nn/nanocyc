%% nn_nd.pl - Rank-parametric nD and fractal-dimensional extension of nn.pl
%%
%% Dimension is a parameter, not a class: the single `convnd` abstraction
%% replaces the TemporalConvolution / SpatialConvolution / VolumetricConvolution
%% triplet.  Everything reduces to three rank-generic primitives:
%%
%%   1. Strided index arithmetic  - map nD coordinates to flat offsets
%%   2. im2col / unfold (nD)      - lower convolution to matrix multiply
%%   3. Reduction over axis sets  - pooling / normalization / mean / max
%%
%% Output shape law (all ranks):
%%   out_i = floor((in_i + 2*p_i - d_i*(k_i - 1) - 1) / s_i) + 1,  i in 1..Rank
%%
%% Fractal dimensionality is supported in both readings:
%%   (a) fractal topology  - FractalNet-style self-similar container recursion
%%       (fractal_module/3, concat_avg with drop-path regularization);
%%   (b) fractal data domains - non-integer Hausdorff dimension, handled by
%%       lowering to a weighted graph (sierpinski_graph/2) and replacing grid
%%       convolution with message passing (graph_conv_module/3).  Multi-scale
%%       pooling follows the fractal's self-similar coarsening maps
%%       (fractal_pool/3): the renormalization structure of the fractal *is*
%%       the pooling hierarchy.
%%
%% The unifying principle: one parametric mechanism, three lowering paths
%% (GEMM for low rank, separable/tensor factorization for high rank,
%% spectral/graph methods for fractal rank).

:- module(nn_nd, [
    % Output shape law (single invariant, all ranks)
    conv_output_shape/6,

    % Rank-parametric convolution
    convnd_module/5,
    convnd_module/8,
    convnd_forward/3,

    % Separable / factorized convolution (high-rank lowering path)
    separable_convnd_module/4,

    % Rank-parametric pooling
    poolnd_module/4,
    poolnd_forward/3,

    % Fractal topology (FractalNet-style container recursion)
    fractal_module/3,
    fractal_max_depth/2,
    concat_avg_forward/3,
    drop_path_forward/4,
    random_drop_path_mask/3,

    % Generic forward dispatch (extends nn:module_forward)
    nd_module_forward/3,

    % Graph / fractal-domain lowering path
    graph_conv_module/3,
    graph_conv_forward/4,
    grid_graph/2,
    sierpinski_graph/3,
    fractal_pool/3,

    % Rank-generic tensor utilities
    nd_shape/3,
    nd_at/4,
    shape_coords/2,
    flat_offset/3,
    fold_nd/3
]).

:- use_module(nn).

%% ============================================================================
%% Rank-Generic Tensor Utilities (nested-list tensors)
%% ============================================================================

%% nd_shape(+Rank, +Tensor, -Shape)
%% Shape of a nested-list tensor of the given rank.
nd_shape(0, _, []) :- !.
nd_shape(Rank, [H|T], [D|Shape]) :-
    Rank > 0,
    length([H|T], D),
    R1 is Rank - 1,
    nd_shape(R1, H, Shape).

%% nd_at(+Rank, +Tensor, +Coords, -Value)
%% Value at 0-based nD coordinates; out-of-bounds reads yield 0 (zero padding).
nd_at(0, V, [], V) :- !.
nd_at(Rank, T, [C|Cs], V) :-
    Rank > 0,
    (   C >= 0, nth0(C, T, Sub)
    ->  R1 is Rank - 1,
        nd_at(R1, Sub, Cs, V)
    ;   V = 0
    ).

%% shape_coords(+Shape, -Coords)
%% Enumerate all 0-based coordinate tuples of a shape, row-major
%% (last dimension varies fastest).
shape_coords([], [[]]).
shape_coords([D|Ds], Coords) :-
    D0 is D - 1,
    numlist(0, D0, Is),
    shape_coords(Ds, Sub),
    findall([I|C], (member(I, Is), member(C, Sub)), Coords).

%% flat_offset(+Shape, +Coords, -Offset)
%% Strided index arithmetic: offset = sum_i coord_i * stride_i (row-major).
%% Already rank-free.
flat_offset(Shape, Coords, Offset) :-
    flat_offset_(Shape, Coords, 0, Offset).

flat_offset_([], [], Acc, Acc).
flat_offset_([_|Ds], [C|Cs], Acc, Offset) :-
    dims_product(Ds, Stride),
    Acc1 is Acc + C * Stride,
    flat_offset_(Ds, Cs, Acc1, Offset).

dims_product([], 1).
dims_product([D|Ds], P) :-
    dims_product(Ds, P0),
    P is D * P0.

%% fold_nd(+Flat, +Shape, -Nested)
%% Fold a row-major flat list back into a nested tensor of the given shape.
fold_nd(Flat, [D], Flat) :-
    length(Flat, D), !.
fold_nd(Flat, [D|Ds], Nested) :-
    Ds \= [],
    dims_product(Ds, ChunkSize),
    chunks_of(Flat, ChunkSize, Chunks),
    length(Chunks, D),
    maplist(fold_nd_(Ds), Chunks, Nested).

fold_nd_(Shape, Flat, Nested) :- fold_nd(Flat, Shape, Nested).

chunks_of([], _, []).
chunks_of(List, Size, [Chunk|Rest]) :-
    length(Chunk, Size),
    append(Chunk, Remainder, List),
    chunks_of(Remainder, Size, Rest).

%% ============================================================================
%% Output Shape Law (single invariant replacing per-rank schemas)
%% ============================================================================

%% conv_output_shape(+InShape, +KernelShape, +Stride, +Pad, +Dilation, -OutShape)
%% out_i = floor((in_i + 2*p_i - d_i*(k_i - 1) - 1) / s_i) + 1, for all ranks.
conv_output_shape([], [], [], [], [], []).
conv_output_shape([I|Is], [K|Ks], [S|Ss], [P|Ps], [D|Ds], [O|Os]) :-
    conv_out_dim(I, K, S, P, D, O),
    conv_output_shape(Is, Ks, Ss, Ps, Ds, Os).

conv_out_dim(In, K, S, P, D, Out) :-
    Out is ((In + 2*P - D*(K - 1) - 1) // S) + 1,
    Out > 0.

%% ============================================================================
%% Rank-Parametric Convolution: convnd
%% ============================================================================
%% Module term: convnd(Rank, Weight, Bias, KernelShape, Stride, Pad, Dilation)
%%   Weight : OutCh rows, each a flat list of length InCh * prod(KernelShape)
%%            (channel-major, kernel coordinates row-major within a channel)
%%   Bias   : list of length OutCh
%% Input/Output: list of channel tensors, each a nested list of rank Rank.

%% convnd_module(+Rank, +InCh, +OutCh, +KernelShape, -Module)
%% One module type; Rank selects behavior.  Defaults: stride 1, pad 0,
%% dilation 1 in every dimension.
convnd_module(Rank, InCh, OutCh, KernelShape, Module) :-
    default_stride(Rank, S),
    default_pad(Rank, P),
    default_dilation(Rank, D),
    convnd_module(Rank, InCh, OutCh, KernelShape, S, P, D, Module).

%% convnd_module(+Rank, +InCh, +OutCh, +KernelShape, +Stride, +Pad, +Dilation, -Module)
convnd_module(Rank, InCh, OutCh, KernelShape,
              Stride, Pad, Dilation,
              convnd(Rank, Weight, Bias, KernelShape, Stride, Pad, Dilation)) :-
    length(KernelShape, Rank),
    length(Stride, Rank),
    length(Pad, Rank),
    length(Dilation, Rank),
    dims_product(KernelShape, KProd),
    RowLen is InCh * KProd,
    init_kernel_tensor(OutCh, RowLen, Weight),
    init_bias(OutCh, Bias).

default_stride(Rank, S)   :- ones(Rank, S).
default_pad(Rank, P)      :- zeros(Rank, P).
default_dilation(Rank, D) :- ones(Rank, D).

ones(N, L)  :- length(L, N), maplist(=(1), L).
zeros(N, L) :- length(L, N), maplist(=(0), L).

init_kernel_tensor(Rows, RowLen, Weight) :-
    length(Weight, Rows),
    maplist(init_random_row(RowLen), Weight).

init_random_row(Len, Row) :-
    length(Row, Len),
    maplist(random_weight_nd, Row).

init_bias(N, Bias) :-
    length(Bias, N),
    maplist(random_weight_nd, Bias).

random_weight_nd(W) :-
    random(R),
    W is (R * 2.0) - 1.0.

%% convnd_forward(+Module, +Input, -Output)
%% Lowered as: unfold (im2col) -> matrix multiply -> fold.
%% The same inner product kernel serves 1D, 2D, 3D, 4D, 5D and beyond.
convnd_forward(convnd(Rank, Weight, Bias, KernelShape, Stride, Pad, Dilation),
               Input, Output) :-
    Input = [Ch0|_],
    nd_shape(Rank, Ch0, InShape),
    conv_output_shape(InShape, KernelShape, Stride, Pad, Dilation, OutShape),
    shape_coords(OutShape, OutCoords),
    shape_coords(KernelShape, KernelCoords),
    unfold_nd(Rank, Input, KernelCoords, OutCoords, Stride, Pad, Dilation,
              Columns),
    conv_gemm_fold(Weight, Bias, Columns, OutShape, Output).

%% unfold_nd(+Rank, +Channels, +KernelCoords, +OutCoords, +S, +P, +D, -Columns)
%% Rank-recursive window extraction: one column per output position, gathering
%% InCh * prod(KernelShape) input values (zero padded outside the domain).
unfold_nd(Rank, Channels, KernelCoords, OutCoords, S, P, D, Columns) :-
    maplist(unfold_column(Rank, Channels, KernelCoords, S, P, D),
            OutCoords, Columns).

unfold_column(Rank, Channels, KernelCoords, S, P, D, OutCoord, Column) :-
    findall(V,
            ( member(Ch, Channels),
              member(KCoord, KernelCoords),
              window_coord(OutCoord, KCoord, S, P, D, InCoord),
              nd_at(Rank, Ch, InCoord, V)
            ),
            Column).

%% window_coord(+OutCoord, +KernelCoord, +Stride, +Pad, +Dilation, -InCoord)
%% in_i = out_i * s_i - p_i + k_i * d_i
window_coord([], [], [], [], [], []).
window_coord([O|Os], [K|Ks], [S|Ss], [P|Ps], [D|Ds], [I|Is]) :-
    I is O * S - P + K * D,
    window_coord(Os, Ks, Ss, Ps, Ds, Is).

%% conv_gemm_fold(+Weight, +Bias, +Columns, +OutShape, -Output)
%% Matrix multiply (weight rows x im2col columns) plus bias, then fold each
%% output channel's flat row-major values back into an nD tensor.
conv_gemm_fold([], [], _, _, []).
conv_gemm_fold([WRow|Ws], [B|Bs], Columns, OutShape, [ChOut|Rest]) :-
    maplist(dot_plus(WRow, B), Columns, Flat),
    fold_nd(Flat, OutShape, ChOut),
    conv_gemm_fold(Ws, Bs, Columns, OutShape, Rest).

dot_plus(W, B, Col, V) :-
    nn:dot_product(W, Col, Dot),
    V is Dot + B.

%% ============================================================================
%% Separable / Factorized Convolution (high-rank lowering path)
%% ============================================================================
%% Dense kernels blow up as k^Rank.  A separable factorization lowers a
%% k x k x ... x k kernel to Rank axis-aligned 1D passes (R(2+1)D-style for
%% Rank 4; the same idea covers 3D and 5D+), giving O(Rank * k) parameters
%% per channel pair instead of O(k^Rank).

%% separable_convnd_module(+Rank, +Channels, +KernelShape, -Module)
%% Builds sequential([convnd_axis_1, ..., convnd_axis_Rank]) where pass i has
%% kernel [1, ..., k_i, ..., 1].  Channel count is preserved between passes.
separable_convnd_module(Rank, Channels, KernelShape, sequential(Modules)) :-
    length(KernelShape, Rank),
    numlist(1, Rank, Axes),
    maplist(axis_conv(Rank, Channels, KernelShape), Axes, Modules).

axis_conv(Rank, Channels, KernelShape, Axis, Module) :-
    ones(Rank, Ones),
    nth1(Axis, KernelShape, K),
    replace_nth1(Axis, Ones, K, AxisKernel),
    convnd_module(Rank, Channels, Channels, AxisKernel, Module).

replace_nth1(1, [_|T], X, [X|T]) :- !.
replace_nth1(N, [H|T], X, [H|T2]) :-
    N > 1, N1 is N - 1,
    replace_nth1(N1, T, X, T2).

%% ============================================================================
%% Rank-Parametric Pooling: poolnd
%% ============================================================================
%% Module term: poolnd(Rank, KernelShape, Stride, Pad, Mode)
%%   Mode in {max, avg}.  Reduction over an arbitrary window of dims.

%% poolnd_module(+Rank, +KernelShape, +Mode, -Module)
%% Default stride = kernel shape (non-overlapping windows), pad 0.
poolnd_module(Rank, KernelShape, Mode,
              poolnd(Rank, KernelShape, KernelShape, Pad, Mode)) :-
    length(KernelShape, Rank),
    memberchk(Mode, [max, avg]),
    zeros(Rank, Pad).

%% poolnd_forward(+Module, +Input, -Output)
poolnd_forward(poolnd(Rank, KernelShape, Stride, Pad, Mode), Input, Output) :-
    ones(Rank, Dilation),
    maplist(pool_channel(Rank, KernelShape, Stride, Pad, Dilation, Mode),
            Input, Output).

pool_channel(Rank, KernelShape, Stride, Pad, Dilation, Mode, Ch, ChOut) :-
    nd_shape(Rank, Ch, InShape),
    conv_output_shape(InShape, KernelShape, Stride, Pad, Dilation, OutShape),
    shape_coords(OutShape, OutCoords),
    shape_coords(KernelShape, KernelCoords),
    maplist(pool_window(Rank, Ch, KernelCoords, Stride, Pad, Dilation, Mode),
            OutCoords, Flat),
    fold_nd(Flat, OutShape, ChOut).

pool_window(Rank, Ch, KernelCoords, S, P, D, Mode, OutCoord, V) :-
    findall(X,
            ( member(KCoord, KernelCoords),
              window_coord(OutCoord, KCoord, S, P, D, InCoord),
              nd_at(Rank, Ch, InCoord, X)
            ),
            Window),
    pool_reduce(Mode, Window, V).

pool_reduce(max, Window, V) :- max_list(Window, V).
pool_reduce(avg, Window, V) :-
    sum_list(Window, Sum),
    length(Window, N),
    V is Sum / N.

%% ============================================================================
%% Fractal Topology (FractalNet-style self-similar container recursion)
%% ============================================================================
%% fractal(Depth, BaseModule): f_k = join(f_{k-1} o f_{k-1}, base)
%% Depth grows as 2^(k-1) while the definition stays O(1).

%% fractal_module(+K, +Base, -Module)
fractal_module(1, Base, Base) :- !.
fractal_module(K, Base, concat_avg([sequential([Sub1, Sub2]), Base])) :-
    K > 1,
    K1 is K - 1,
    fractal_module(K1, Base, Sub1),
    fractal_module(K1, Base, Sub2).

%% fractal_max_depth(+K, -Depth)
%% Longest path through fractal_module(K, _, _) is 2^(K-1) base applications.
fractal_max_depth(K, Depth) :-
    K >= 1,
    Depth is 2 ** (K - 1).

%% concat_avg_forward(+Module, +Input, -Output)
%% Join operation: run every branch on the input and average elementwise.
concat_avg_forward(concat_avg(Branches), Input, Output) :-
    Branches \= [],
    maplist(branch_forward(Input), Branches, Outputs),
    average_tensors(Outputs, Output).

branch_forward(Input, Module, Output) :-
    nd_module_forward(Module, Input, Output).

%% drop_path_forward(+Module, +Mask, +Input, -Output)
%% Drop-path regularization as a stochastic branch mask in concat_avg:
%% only branches whose mask entry is 1 participate in the average.
drop_path_forward(concat_avg(Branches), Mask, Input, Output) :-
    include_masked(Branches, Mask, Active),
    Active \= [],
    maplist(branch_forward(Input), Active, Outputs),
    average_tensors(Outputs, Output).

include_masked([], [], []).
include_masked([B|Bs], [1|Ms], [B|As]) :- include_masked(Bs, Ms, As).
include_masked([_|Bs], [0|Ms], As)     :- include_masked(Bs, Ms, As).

%% random_drop_path_mask(+N, +KeepProb, -Mask)
%% Sample a branch mask keeping each branch with probability KeepProb,
%% guaranteeing at least one active branch.
random_drop_path_mask(N, KeepProb, Mask) :-
    length(Mask0, N),
    maplist(sample_keep(KeepProb), Mask0),
    (   memberchk(1, Mask0)
    ->  Mask = Mask0
    ;   random_between(1, N, Idx),
        set_nth1(Idx, Mask0, 1, Mask)
    ).

sample_keep(KeepProb, Bit) :-
    random(R),
    (R < KeepProb -> Bit = 1 ; Bit = 0).

set_nth1(1, [_|T], X, [X|T]) :- !.
set_nth1(N, [H|T], X, [H|T2]) :-
    N > 1, N1 is N - 1,
    set_nth1(N1, T, X, T2).

%% average_tensors(+Tensors, -Average)
%% Elementwise average of same-shape nested-list tensors.
average_tensors([T|Ts], Average) :-
    foldl(tensor_add, Ts, T, Sum),
    length([T|Ts], N),
    Factor is 1.0 / N,
    tensor_scale(Sum, Factor, Average).

tensor_add(A, B, C) :-
    (   number(A)
    ->  C is A + B
    ;   maplist(tensor_add, A, B, C)
    ).

tensor_scale(T, F, S) :-
    (   number(T)
    ->  S is T * F
    ;   maplist(scale_with(F), T, S)
    ).

scale_with(F, T, S) :- tensor_scale(T, F, S).

%% ============================================================================
%% Generic Forward Dispatch
%% ============================================================================
%% Extends nn:module_forward with the nD / fractal module types; anything
%% else (linear, sigmoid, relu, identity, ...) falls through to nn.pl.

%% nd_module_forward(+Module, +Input, -Output)
nd_module_forward(convnd(R, W, B, K, S, P, D), Input, Output) :- !,
    convnd_forward(convnd(R, W, B, K, S, P, D), Input, Output).
nd_module_forward(poolnd(R, K, S, P, M), Input, Output) :- !,
    poolnd_forward(poolnd(R, K, S, P, M), Input, Output).
nd_module_forward(concat_avg(Branches), Input, Output) :- !,
    concat_avg_forward(concat_avg(Branches), Input, Output).
nd_module_forward(sequential(Modules), Input, Output) :- !,
    nd_sequential_forward(Modules, Input, Output).
nd_module_forward(Module, Input, Output) :-
    nn:module_forward(Module, Input, Output).

nd_sequential_forward([], Output, Output).
nd_sequential_forward([M|Ms], Input, Output) :-
    nd_module_forward(M, Input, Intermediate),
    nd_sequential_forward(Ms, Intermediate, Output).

%% ============================================================================
%% Graph / Fractal-Domain Lowering Path
%% ============================================================================
%% At high rank -- or on non-integer Hausdorff-dimension domains -- the
%% lattice is treated as a (hyper)graph and convolution is replaced by
%% message passing.  Grids, fractals, and irregular domains all become
%% special cases of the same mechanism.
%%
%% Graph term: graph(NumNodes, Edges) with Edges a list of edge(I, J, Wt)
%% (undirected, 0-based node indices).
%% Features: list of NumNodes vectors.

%% graph_conv_module(+InDim, +OutDim, -Module)
%% Message-passing layer: h'_i = Wself * h_i + Wneigh * mean_{j~i}(w_ij h_j) + b
graph_conv_module(InDim, OutDim, graph_conv(Wself, Wneigh, Bias)) :-
    init_kernel_tensor(OutDim, InDim, Wself),
    init_kernel_tensor(OutDim, InDim, Wneigh),
    init_bias(OutDim, Bias).

%% graph_conv_forward(+Module, +Graph, +Features, -OutFeatures)
graph_conv_forward(graph_conv(Wself, Wneigh, Bias), graph(N, Edges),
                   Features, OutFeatures) :-
    N0 is N - 1,
    numlist(0, N0, Nodes),
    maplist(node_forward(Wself, Wneigh, Bias, Edges, Features),
            Nodes, OutFeatures).

node_forward(Wself, Wneigh, Bias, Edges, Features, I, HOut) :-
    nth0(I, Features, Hi),
    neighbor_aggregate(I, Edges, Features, Hi, Agg),
    nn:matrix_vector_mult(Wself, Hi, SelfTerm),
    nn:matrix_vector_mult(Wneigh, Agg, NeighTerm),
    nn:add_vectors(SelfTerm, NeighTerm, Sum),
    nn:add_vectors(Sum, Bias, HOut).

neighbor_aggregate(I, Edges, Features, Hi, Agg) :-
    findall(Wt-Hj,
            ( ( member(edge(I, J, Wt), Edges)
              ; member(edge(J, I, Wt), Edges)
              ),
              nth0(J, Features, Hj)
            ),
            Msgs),
    (   Msgs = []
    ->  tensor_scale(Hi, 0.0, Agg)
    ;   weighted_mean(Msgs, Agg)
    ).

weighted_mean(Msgs, Mean) :-
    Msgs = [W0-H0|Rest],
    tensor_scale(H0, W0, Acc0),
    foldl(accum_weighted, Rest, Acc0, Sum),
    foldl(accum_weight, Msgs, 0, TotalW),
    TotalW =\= 0,
    Factor is 1.0 / TotalW,
    tensor_scale(Sum, Factor, Mean).

accum_weighted(W-H, Acc, Acc1) :-
    tensor_scale(H, W, WH),
    tensor_add(Acc, WH, Acc1).

accum_weight(W-_, Acc, Acc1) :- Acc1 is Acc + W.

%% grid_graph(+Shape, -Graph)
%% An nD grid is just a graph with regular structure: nodes are lattice
%% points (flat row-major index via strided arithmetic), unit-weight edges
%% connect points differing by 1 in exactly one dimension.
grid_graph(Shape, graph(N, Edges)) :-
    dims_product(Shape, N),
    shape_coords(Shape, Coords),
    findall(edge(I, J, 1),
            ( member(C, Coords),
              grid_neighbor(Shape, C, C2),
              flat_offset(Shape, C, I),
              flat_offset(Shape, C2, J),
              I < J
            ),
            Edges).

grid_neighbor(Shape, Coord, Neighbor) :-
    length(Coord, Rank),
    between(1, Rank, Axis),
    nth1(Axis, Coord, C),
    nth1(Axis, Shape, D),
    C1 is C + 1,
    C1 < D,
    replace_nth1(Axis, Coord, C1, Neighbor).

%% sierpinski_graph(+Depth, -Graph, -Vertices)
%% Finite-resolution approximation of a fractal (Hausdorff dimension
%% log(3)/log(2) ~ 1.585) as a weighted graph: the Sierpinski gasket at
%% level Depth.  Vertices are lattice points (X, Y); an upward cell at
%% (X, Y) exists iff X /\ Y =:= 0 (Pascal's triangle mod 2), contributing
%% triangle edges (X,Y)-(X+1,Y)-(X,Y+1).
%% Vertices is the list of vertex coordinates, in node-index order.
sierpinski_graph(Depth, graph(N, Edges), Vertices) :-
    Size is 2 ** Depth,
    Max is Size - 1,
    findall(X-Y,
            ( between(0, Max, X),
              between(0, Max, Y),
              X + Y =< Max,
              X /\ Y =:= 0
            ),
            Cells),
    findall(V, (member(X-Y, Cells), cell_vertex(X, Y, V)), Vs0),
    sort(Vs0, Vertices),
    length(Vertices, N),
    findall(E, (member(X-Y, Cells), cell_edge(Vertices, X, Y, E)), Es0),
    sort(Es0, Edges).

cell_vertex(X, Y, X-Y).
cell_vertex(X, Y, X1-Y) :- X1 is X + 1.
cell_vertex(X, Y, X-Y1) :- Y1 is Y + 1.

cell_edge(Vertices, X, Y, edge(I, J, 1)) :-
    X1 is X + 1, Y1 is Y + 1,
    member(A-B, [(X-Y)-(X1-Y), (X-Y)-(X-Y1), (X1-Y)-(X-Y1)]),
    vertex_index(Vertices, A, IA),
    vertex_index(Vertices, B, IB),
    (IA < IB -> I = IA, J = IB ; I = IB, J = IA).

vertex_index(Vertices, V, I) :- nth0(I, Vertices, V).

%% fractal_pool(+FineVertices, +Features, -Pooled)
%% Multi-scale pooling along the fractal's self-similar coarsening map:
%% each fine vertex (X, Y) renormalizes to (X // 2, Y // 2); features of
%% vertices sharing a coarse vertex are averaged.  Pooled is a list of
%% CoarseVertex-Feature pairs sorted by coarse vertex.  The renormalization
%% structure of the fractal *is* the pooling hierarchy.
fractal_pool(FineVertices, Features, Pooled) :-
    pairs_keys_values(Pairs0, FineVertices, Features),
    findall(CX-CY-F,
            ( member((X-Y)-F, Pairs0),
              CX is X // 2,
              CY is Y // 2
            ),
            Coarse0),
    findall(K, member(K-_, Coarse0), Keys0),
    sort(Keys0, Keys),
    maplist(pool_group(Coarse0), Keys, Pooled).

pool_group(Coarse, Key, Key-Mean) :-
    findall(F, member(Key-F, Coarse), Fs),
    average_tensors(Fs, Mean).
