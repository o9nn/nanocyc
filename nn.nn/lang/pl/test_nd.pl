%% Test file for rank-parametric nD and fractal modules in nn_nd.pl
%% Run with: swipl -q -l test_nd.pl -g run_nd_tests -t halt

:- consult('nn_nd.pl').

%% ============================================================================
%% Output Shape Law Tests (single invariant, all ranks)
%% ============================================================================

test_output_shape_law :-
    format('Test: Output shape law (all ranks)...~n'),
    % 1D: (8 + 2*1 - 1*(3-1) - 1) // 2 + 1 = 4
    nn_nd:conv_output_shape([8], [3], [2], [1], [1], [4]),
    % 2D: 5x5 input, 3x3 kernel, stride 1, no pad -> 3x3
    nn_nd:conv_output_shape([5,5], [3,3], [1,1], [0,0], [1,1], [3,3]),
    % 3D: 4x4x4 input, 2x2x2 kernel -> 3x3x3
    nn_nd:conv_output_shape([4,4,4], [2,2,2], [1,1,1], [0,0,0], [1,1,1], [3,3,3]),
    % 4D: rank generalizes with no new code
    nn_nd:conv_output_shape([4,4,4,4], [2,2,2,2], [1,1,1,1], [0,0,0,0],
                            [1,1,1,1], [3,3,3,3]),
    % Dilation: (7 + 0 - 2*(3-1) - 1) // 1 + 1 = 3
    nn_nd:conv_output_shape([7], [3], [1], [0], [2], [3]),
    format('  PASSED: Output shape law holds for ranks 1-4 with dilation~n').

%% ============================================================================
%% Rank-Generic Tensor Utility Tests
%% ============================================================================

test_flat_offset :-
    format('Test: Strided index arithmetic...~n'),
    % offset = sum_i coord_i * stride_i, row-major
    nn_nd:flat_offset([4,5], [2,3], 13),      % 2*5 + 3
    nn_nd:flat_offset([2,3,4], [1,2,3], 23),  % 1*12 + 2*4 + 3
    nn_nd:flat_offset([7], [4], 4),
    format('  PASSED: flat offsets computed for ranks 1-3~n').

test_fold_unfold_roundtrip :-
    format('Test: fold_nd shape reconstruction...~n'),
    numlist(1, 24, Flat),
    nn_nd:fold_nd(Flat, [2,3,4], Nested),
    nn_nd:nd_shape(3, Nested, [2,3,4]),
    nn_nd:nd_at(3, Nested, [1,2,3], 24),
    nn_nd:nd_at(3, Nested, [0,0,0], 1),
    format('  PASSED: fold_nd reconstructs nD tensors~n').

%% ============================================================================
%% Rank-Parametric Convolution Tests
%% ============================================================================

test_convnd_1d :-
    format('Test: convnd rank 1 (temporal)...~n'),
    % Deterministic weights: kernel [1,1,1], bias 0 -> moving sum
    M = convnd(1, [[1,1,1]], [0], [3], [1], [0], [1]),
    nn_nd:convnd_forward(M, [[1,2,3,4,5]], [[6,9,12]]),
    format('  PASSED: 1D convolution equals moving window sum~n').

test_convnd_2d :-
    format('Test: convnd rank 2 (spatial)...~n'),
    % 2x2 sum kernel over a 3x3 image
    M = convnd(2, [[1,1,1,1]], [0], [2,2], [1,1], [0,0], [1,1]),
    In = [[[1,2,3],[4,5,6],[7,8,9]]],
    nn_nd:convnd_forward(M, In, [[[12,16],[24,28]]]),
    format('  PASSED: 2D convolution matches hand-computed windows~n').

test_convnd_3d :-
    format('Test: convnd rank 3 (volumetric)...~n'),
    % 2x2x2 sum kernel over a 2x2x2 volume -> total sum
    M = convnd(3, [[1,1,1,1,1,1,1,1]], [0], [2,2,2], [1,1,1], [0,0,0], [1,1,1]),
    In = [[[[1,2],[3,4]],[[5,6],[7,8]]]],
    nn_nd:convnd_forward(M, In, [[[[36]]]]),
    format('  PASSED: 3D convolution matches volume sum~n').

test_convnd_4d :-
    format('Test: convnd rank 4 (spatiotemporal)...~n'),
    % Rank 4 with no rank-specific code: 2^4 ones kernel on all-ones input
    length(K16, 16), maplist(=(1), K16),
    M = convnd(4, [K16], [0], [2,2,2,2], [1,1,1,1], [0,0,0,0], [1,1,1,1]),
    Plane = [[1,1,1],[1,1,1],[1,1,1]],
    Cube = [Plane, Plane, Plane],
    In = [[Cube, Cube, Cube]],
    nn_nd:convnd_forward(M, In, [Out]),
    nn_nd:nd_shape(4, Out, [2,2,2,2]),
    nn_nd:nd_at(4, Out, [0,0,0,0], 16),
    nn_nd:nd_at(4, Out, [1,1,1,1], 16),
    format('  PASSED: 4D convolution works with the same mechanism~n').

test_convnd_multichannel :-
    format('Test: convnd multi-channel in/out...~n'),
    % 2 input channels, 2 output channels, 1D kernel of size 2
    % Column layout: [ch1(k0),ch1(k1),ch2(k0),ch2(k1)]
    W = [[1,0,0,0],   % out ch 1 = first element of in ch 1 window
         [0,0,0,1]],  % out ch 2 = second element of in ch 2 window
    M = convnd(1, W, [0,0], [2], [1], [0], [1]),
    nn_nd:convnd_forward(M, [[1,2,3],[10,20,30]], [[1,2],[20,30]]),
    format('  PASSED: channel-major unfold ordering verified~n').

test_convnd_padding_stride :-
    format('Test: convnd zero padding and stride...~n'),
    % kernel [1,1], pad 1, stride 2 on [1,2,3]:
    % padded [0,1,2,3,0]; windows at 0,2 -> [0+1, 2+3] = [1,5]
    M = convnd(1, [[1,1]], [0], [2], [2], [1], [1]),
    nn_nd:convnd_forward(M, [[1,2,3]], [[1,5]]),
    format('  PASSED: padding and stride respected~n').

test_convnd_module_constructor :-
    format('Test: convnd_module rank-parametric constructor...~n'),
    nn_nd:convnd_module(3, 2, 4, [3,3,3], M),
    M = convnd(3, W, B, [3,3,3], [1,1,1], [0,0,0], [1,1,1]),
    length(W, 4),            % OutCh rows
    W = [Row|_],
    length(Row, 54),         % InCh * prod(KernelShape) = 2 * 27
    length(B, 4),
    format('  PASSED: one constructor, rank selects behavior~n').

test_separable_convnd :-
    format('Test: separable factorized convolution...~n'),
    % k x k lowered to two 1D passes; output shape matches dense kernel
    nn_nd:separable_convnd_module(2, 1, [3,3], sequential(Ms)),
    length(Ms, 2),
    In = [[[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5]]],
    nn_nd:nd_module_forward(sequential(Ms), In, [Out|_]),
    nn_nd:nd_shape(2, Out, [3,3]),
    format('  PASSED: separable passes compose to dense output shape~n').

%% ============================================================================
%% Rank-Parametric Pooling Tests
%% ============================================================================

test_poolnd_max :-
    format('Test: poolnd max (rank 2)...~n'),
    nn_nd:poolnd_module(2, [2,2], max, P),
    In = [[[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]],
    nn_nd:poolnd_forward(P, In, [[[6,8],[14,16]]]),
    format('  PASSED: 2D max pooling~n').

test_poolnd_avg :-
    format('Test: poolnd avg (rank 2)...~n'),
    nn_nd:poolnd_module(2, [2,2], avg, P),
    In = [[[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]],
    nn_nd:poolnd_forward(P, In, [[[3.5,5.5],[11.5,13.5]]]),
    format('  PASSED: 2D average pooling~n').

test_poolnd_3d :-
    format('Test: poolnd rank 3...~n'),
    nn_nd:poolnd_module(3, [2,2,2], max, P),
    In = [[[[1,2],[3,4]],[[5,6],[7,8]]]],
    nn_nd:poolnd_forward(P, In, [[[[8]]]]),
    format('  PASSED: 3D pooling via the same reduction primitive~n').

%% ============================================================================
%% Fractal Topology Tests
%% ============================================================================

test_fractal_module :-
    format('Test: fractal_module self-similar recursion...~n'),
    % f_1 = base
    nn_nd:fractal_module(1, identity, identity),
    % f_2 = join(f_1 o f_1, base)
    nn_nd:fractal_module(2, identity,
                         concat_avg([sequential([identity, identity]),
                                     identity])),
    % Depth grows as 2^(K-1) while the definition stays O(1)
    nn_nd:fractal_max_depth(1, D1), D1 =:= 1,
    nn_nd:fractal_max_depth(4, D4), D4 =:= 8,
    format('  PASSED: fractal recursion and 2^(K-1) depth growth~n').

test_fractal_forward :-
    format('Test: fractal_module forward pass...~n'),
    % With identity base, every branch is identity: output = input
    nn_nd:fractal_module(3, identity, F),
    nn_nd:nd_module_forward(F, [1.0, 2.0, 3.0], [1.0, 2.0, 3.0]),
    format('  PASSED: fractal(identity) is identity~n').

test_concat_avg :-
    format('Test: concat_avg join...~n'),
    nn_nd:concat_avg_forward(concat_avg([identity, identity]),
                             [2.0, 4.0], [2.0, 4.0]),
    format('  PASSED: elementwise branch average~n').

test_drop_path :-
    format('Test: drop-path stochastic branch mask...~n'),
    % Masked concat_avg: only active branches averaged
    nn_nd:drop_path_forward(concat_avg([identity, identity]),
                            [1, 0], [3.0, 4.0], [3.0, 4.0]),
    % Random mask always keeps at least one branch
    nn_nd:random_drop_path_mask(5, 0.0, Mask),
    length(Mask, 5),
    memberchk(1, Mask),
    format('  PASSED: drop-path masking with non-empty guarantee~n').

%% ============================================================================
%% Graph / Fractal-Domain Tests
%% ============================================================================

test_grid_graph :-
    format('Test: nD grid as a graph...~n'),
    % A 2x2 grid has 4 nodes and 4 lattice edges
    nn_nd:grid_graph([2,2], graph(4, Edges2)),
    length(Edges2, 4),
    % A 2x2x2 grid has 8 nodes and 12 edges: rank-free construction
    nn_nd:grid_graph([2,2,2], graph(8, Edges3)),
    length(Edges3, 12),
    format('  PASSED: grids of any rank lower to graphs~n').

test_sierpinski_graph :-
    format('Test: Sierpinski gasket graph (fractal domain)...~n'),
    % Level-1 gasket: 6 vertices, 9 edges (3 upward cells)
    nn_nd:sierpinski_graph(1, graph(6, E1), V1),
    length(E1, 9), length(V1, 6),
    % Level-2 gasket: 15 vertices, 27 edges (9 upward cells)
    nn_nd:sierpinski_graph(2, graph(15, E2), V2),
    length(E2, 27), length(V2, 15),
    format('  PASSED: finite-resolution fractal approximated as graph~n').

test_graph_conv :-
    format('Test: graph convolution (message passing)...~n'),
    % Identity self weight, zero neighbor weight, zero bias -> identity map
    GC = graph_conv([[1,0],[0,1]], [[0,0],[0,0]], [0,0]),
    G = graph(3, [edge(0,1,1), edge(1,2,1)]),
    Feats = [[1.0,2.0],[3.0,4.0],[5.0,6.0]],
    nn_nd:graph_conv_forward(GC, G, Feats, Feats),
    % Zero self weight, identity neighbor weight -> neighborhood mean
    GC2 = graph_conv([[0,0],[0,0]], [[1,0],[0,1]], [0,0]),
    nn_nd:graph_conv_forward(GC2, G, Feats, [H0|_]),
    H0 = [3.0, 4.0],   % node 0's only neighbor is node 1
    format('  PASSED: message passing on graph domains~n').

test_fractal_pool :-
    format('Test: fractal renormalization pooling...~n'),
    % Vertices (X,Y) coarsen to (X//2, Y//2); features averaged per group
    Vs = [0-0, 1-0, 0-1, 2-0, 1-1, 0-2],
    Fs = [[1.0], [2.0], [3.0], [4.0], [5.0], [6.0]],
    nn_nd:fractal_pool(Vs, Fs, Pooled),
    % (0,0),(1,0),(0,1),(1,1) -> (0,0): mean 2.75; (2,0)->(1,0); (0,2)->(0,1)
    memberchk(0-0-[M00], Pooled), abs(M00 - 2.75) < 1.0e-9,
    memberchk(1-0-[4.0], Pooled),
    memberchk(0-1-[6.0], Pooled),
    format('  PASSED: pooling hierarchy inherits fractal geometry~n').

%% ============================================================================
%% Integration Tests
%% ============================================================================

test_nd_pipeline :-
    format('Test: convnd -> poolnd -> fractal pipeline...~n'),
    Conv = convnd(2, [[1,1,1,1]], [0], [2,2], [1,1], [0,0], [1,1]),
    nn_nd:poolnd_module(2, [2,2], max, Pool),
    nn_nd:fractal_module(2, identity, Fractal),
    Net = sequential([Conv, Pool]),
    In = [[[1,2,3],[4,5,6],[7,8,9]]],
    nn_nd:nd_module_forward(Net, In, [[[Max]]]),
    Max =:= 28,
    % Fractal container composes with any downstream module structure
    nn_nd:nd_module_forward(Fractal, [1.0], [1.0]),
    format('  PASSED: rank-parametric modules compose~n').

test_nn_fallthrough :-
    format('Test: nd_module_forward falls through to nn.pl...~n'),
    nn:relu_module(ReLU),
    nn_nd:nd_module_forward(ReLU, [-1, 0, 2], [0, 0, 2]),
    format('  PASSED: existing nn.pl modules dispatch unchanged~n').

%% ============================================================================
%% Test Runner
%% ============================================================================

run_nd_tests :-
    format('~n=== Running nD / Fractal Module Tests ===~n~n'),

    % Shape law and tensor utilities
    catch(test_output_shape_law, E1, (format('  ShapeLaw FAILED: ~w~n', [E1]), fail)),
    catch(test_flat_offset, E2, (format('  FlatOffset FAILED: ~w~n', [E2]), fail)),
    catch(test_fold_unfold_roundtrip, E3, (format('  Fold FAILED: ~w~n', [E3]), fail)),

    % Rank-parametric convolution
    catch(test_convnd_1d, E4, (format('  Conv1D FAILED: ~w~n', [E4]), fail)),
    catch(test_convnd_2d, E5, (format('  Conv2D FAILED: ~w~n', [E5]), fail)),
    catch(test_convnd_3d, E6, (format('  Conv3D FAILED: ~w~n', [E6]), fail)),
    catch(test_convnd_4d, E7, (format('  Conv4D FAILED: ~w~n', [E7]), fail)),
    catch(test_convnd_multichannel, E8, (format('  ConvCh FAILED: ~w~n', [E8]), fail)),
    catch(test_convnd_padding_stride, E9, (format('  ConvPad FAILED: ~w~n', [E9]), fail)),
    catch(test_convnd_module_constructor, E10, (format('  ConvCtor FAILED: ~w~n', [E10]), fail)),
    catch(test_separable_convnd, E11, (format('  Separable FAILED: ~w~n', [E11]), fail)),

    % Rank-parametric pooling
    catch(test_poolnd_max, E12, (format('  PoolMax FAILED: ~w~n', [E12]), fail)),
    catch(test_poolnd_avg, E13, (format('  PoolAvg FAILED: ~w~n', [E13]), fail)),
    catch(test_poolnd_3d, E14, (format('  Pool3D FAILED: ~w~n', [E14]), fail)),

    % Fractal topology
    catch(test_fractal_module, E15, (format('  Fractal FAILED: ~w~n', [E15]), fail)),
    catch(test_fractal_forward, E16, (format('  FractalFwd FAILED: ~w~n', [E16]), fail)),
    catch(test_concat_avg, E17, (format('  ConcatAvg FAILED: ~w~n', [E17]), fail)),
    catch(test_drop_path, E18, (format('  DropPath FAILED: ~w~n', [E18]), fail)),

    % Graph / fractal domains
    catch(test_grid_graph, E19, (format('  GridGraph FAILED: ~w~n', [E19]), fail)),
    catch(test_sierpinski_graph, E20, (format('  Sierpinski FAILED: ~w~n', [E20]), fail)),
    catch(test_graph_conv, E21, (format('  GraphConv FAILED: ~w~n', [E21]), fail)),
    catch(test_fractal_pool, E22, (format('  FractalPool FAILED: ~w~n', [E22]), fail)),

    % Integration
    catch(test_nd_pipeline, E23, (format('  Pipeline FAILED: ~w~n', [E23]), fail)),
    catch(test_nn_fallthrough, E24, (format('  Fallthrough FAILED: ~w~n', [E24]), fail)),

    format('~n=== All nD / Fractal Module Tests Passed ===~n~n').
