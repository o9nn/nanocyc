/*
 * ch02_fractal_tape.mli
 *
 * Geometric companion to ch02_fractal_tape.pli (section 2.1.1).
 * The fractal tape is one cell at the top level; entering it opens a grid,
 * then a grid within that grid. Surgery of a flat 2D image wraps the result
 * as the innermost nested sphere.
 *
 * Traceability: src/cpp/nanobrain_fractal_tape.h, src/cpp/nanobrain_fractal.h
 */

@import "ch02_fractal_tape.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold nested_sphere(dimension=2, compact=true, charts=3);

@tiling {
    @glue g_scale;
    @glue_relation(g_scale, g_scale);
    @glue_radius 0.1;

    @tile scale_1(sides=4, radius=4.0) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color LightBlue alpha=80;
    }
    @tile scale_2(sides=4, radius=2.0) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color DodgerBlue alpha=140;
    }
    @tile scale_3(sides=4, radius=1.0) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color Navy alpha=200;
    }
    /* Innermost sphere: the surgery result of the flat image. */
    @tile sphere(sides=8, radius=0.5) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=45);
        @color Gold alpha=220;
    }

    @seed scale_1 at (0, 0, 0);
    @seed sphere at (0, 0, 0);
}

/* F-Lingua profile: three nested scales (4 -> 2 -> 1), seeded at scale_1. */
@fractal {
    depth 3;
    scale 0.5;
    tile scale_1;
}

@floating cell(mobility=1, radius=0.02, concentration=4);
@floating patch(mobility=1, radius=0.02, concentration=1);

def main() {
    @create cell --> scale_1;
    @create cell --> scale_2;
    @create cell --> scale_3;
    @create patch --> sphere;
}
