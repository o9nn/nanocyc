/*
 * ch02_singularity_assembly.mli
 *
 * Geometric companion to ch02_singularity_assembly.pli (sections 2.1.1-2.1.2).
 * The .pli file keeps the discrete multiset spec. This file supplies the
 * spatial self-assembly the header could only describe in prose: a singularity
 * seed nucleates edges, edges lock into lines, lines close into loops.
 *
 * Traceability: src/cpp/nanobrain_fractal_tape.h, src/cpp/nanobrain_fractal.h
 */

@import "ch02_singularity_assembly.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold singularity(dimension=2, compact=false, charts=1);
@capability phase_undefined_seed;

@tiling {
    @glue g_seed;
    @glue g_edge;
    @glue g_loop;
    @glue_relation(g_seed, g_edge);
    @glue_relation(g_edge, g_edge);
    @glue_relation(g_edge, g_loop);
    @glue_radius 0.05;

    /* The seed is not consumed. Phase is undefined here; it only organises. */
    @tile sing_seed(sides=1, radius=0.1) {
        @connector c_polar(vertices=[v1,v1], glue=g_seed, angle=0);
        @color White alpha=255;
    }

    @tile edge_piece(sides=2, radius=1.0) {
        @connector c_in(vertices=[v1,v2], glue=g_seed, angle=180);
        @connector c_out(vertices=[v2,v1], glue=g_edge, angle=180);
        @color SteelBlue alpha=180;
    }

    @tile locked_line(sides=4, radius=2.0) {
        @connector c1(vertices=[v1,v2], glue=g_edge, angle=180);
        @connector c2(vertices=[v3,v4], glue=g_loop, angle=90);
        @color CadetBlue alpha=160;
    }

    @tile closed_loop(sides=6, radius=3.0) {
        @connector c1(vertices=[v1,v2], glue=g_loop, angle=120);
        @connector c2(vertices=[v2,v3], glue=g_loop, angle=120);
        @connector c3(vertices=[v3,v4], glue=g_loop, angle=120);
        @color DarkOrange alpha=200;
    }

    @seed sing_seed at (0, 0, 0);
}

@floating edge(mobility=2, radius=0.05, concentration=8);
@floating line(mobility=1, radius=0.1, concentration=0);
@floating loop(mobility=0.5, radius=0.2, concentration=0);

def main() {
    @create edge, edge --> locked_line;
    @create line, line --> closed_loop;
    edge, edge --> line;
}
