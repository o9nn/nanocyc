/*
 * ch08_knot_morphogenesis.mli
 *
 * Geometric companion to ch08_knot_morphogenesis.pli (sections 8.6-8.6.3).
 * Inner and outer mirrors, 180 degrees out of phase, squeeze a stationary
 * dark line into spin knots, a supercoil, and finally a vortex atom.
 *
 * Traceability: src/cpp/nanobrain_hinductor.h
 */

@import "ch08_knot_morphogenesis.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold knot_mirrors(dimension=3, compact=false, charts=2);
@capability phase_editor;

@tiling {
    @glue g_mirror;
    @glue g_dark;
    @glue g_vortex;
    @glue_relation(g_mirror, g_dark);
    @glue_relation(g_dark, g_dark);
    @glue_relation(g_dark, g_vortex);
    @glue_radius 0.1;

    @tile inner_mirror(sides=6, radius=1.0) {
        @connector c1(vertices=[v1,v2], glue=g_mirror, angle=60);
        @color Silver alpha=160;
    }
    @tile outer_mirror(sides=6, radius=2.0) {
        @connector c1(vertices=[v1,v2], glue=g_mirror, angle=180);
        @color Gray alpha=140;
    }
    @tile dark_line(sides=2, radius=3.0) {
        @connector c1(vertices=[v1,v2], glue=g_dark, angle=0);
        @color Black alpha=255;
    }
    @tile supercoil(sides=8, radius=1.5) {
        @connector c1(vertices=[v1,v2], glue=g_dark, angle=40);
        @connector c2(vertices=[v3,v4], glue=g_vortex, angle=40);
        @color Indigo alpha=200;
    }
    @tile vortex_atom(sides=3, radius=0.8) {
        @connector c1(vertices=[v1,v2], glue=g_vortex, angle=120);
        @connector c2(vertices=[v2,v3], glue=g_vortex, angle=120);
        @connector c3(vertices=[v3,v1], glue=g_vortex, angle=120);
        @color Gold alpha=230;
    }

    @seed dark_line at (0, 0, 0);
}

@floating pump(mobility=2, radius=0.04, concentration=2);
@floating ring(mobility=1, radius=0.08, concentration=3);

def main() {
    @create pump --> inner_mirror;
    @create pump --> outer_mirror;
    @create ring, ring, ring --> vortex_atom;
    pump, pump --> supercoil;
}
