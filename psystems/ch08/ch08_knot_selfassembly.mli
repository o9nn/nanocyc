/*
 * ch08_knot_selfassembly.mli
 *
 * Geometric companion to ch08_knot_selfassembly.pli (section 8.7).
 * A small perturbation mobilises vortex atoms one by one along the dark-knot
 * skeleton, climbing from a basic H device toward a crystal of magnetic light.
 *
 * Traceability: src/cpp/nanobrain_hinductor.h
 */

@import "ch08_knot_selfassembly.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold knot_skeleton(dimension=3, compact=false, charts=4);
@capability linear_assembly;

@tiling {
    @glue g_skel;
    @glue g_atom;
    @glue_relation(g_skel, g_atom);
    @glue_relation(g_atom, g_atom);
    @glue_radius 0.2;

    @tile dark_skeleton(sides=2, radius=6.0) {
        @connector c1(vertices=[v1,v2], glue=g_skel, angle=0);
        @color Black alpha=240;
    }
    @tile vortex_atom(sides=3, radius=0.6) {
        @connector c1(vertices=[v1,v2], glue=g_atom, angle=120);
        @connector c2(vertices=[v2,v3], glue=g_skel, angle=30);
        @color Cyan alpha=200;
    }
    @tile h_device(sides=4, radius=1.5) {
        @connector c1(vertices=[v1,v2], glue=g_atom, angle=90);
        @color Teal alpha=180;
    }
    @tile magnetic_crystal(sides=6, radius=3.0) {
        @connector c1(vertices=[v1,v2], glue=g_atom, angle=60);
        @color Violet alpha=210;
    }

    @seed dark_skeleton at (0, 0, 0);
}

@floating atom(mobility=3, radius=0.05, concentration=4);
@floating perturb(mobility=5, radius=0.02, concentration=1);

def main() {
    @create atom --> vortex_atom;
    @create atom, atom --> h_device;
    @create atom, atom, atom, atom --> magnetic_crystal;
    perturb, atom --> atom;
}
