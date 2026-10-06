/*
 * ch06_tubulin_ppm.mli
 *
 * Geometric companion to ch06_tubulin_ppm.pli (sections 6.1-6.1.4).
 * Alpha-helix rings, the 13-protofilament microtubule, and the hollow water
 * channel are spatial assemblies. The .pli file keeps the prime-count clocks.
 *
 * Traceability: src/cpp/nanobrain_ppm.h
 */

@import "ch06_tubulin_ppm.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold tubulin_lattice(dimension=2, compact=true, charts=13);
@polytope mt13(cells=13, edges=13, faces=13, vertices=13, dimension=2, symmetry=C13);
@capability prime_slice;

@tiling {
    @glue g_helix;
    @glue g_ring;
    @glue g_proto;
    @glue g_water;
    @glue_relation(g_helix, g_helix);
    @glue_relation(g_ring, g_ring);
    @glue_relation(g_proto, g_proto);
    @glue_relation(g_water, g_water);
    @glue_radius 0.26;

    @tile alpha_helix(sides=6, radius=0.5) {
        @connector c1(vertices=[v1,v2], glue=g_helix, angle=100);
        @connector c2(vertices=[v2,v3], glue=g_ring, angle=60);
        @color Tomato alpha=180;
    }
    /* Observed loop counts 2-3-3-2 close as a ring of helices. */
    @tile helix_ring(sides=8, radius=1.2) {
        @connector c1(vertices=[v1,v2], glue=g_ring, angle=45);
        @connector c2(vertices=[v3,v4], glue=g_proto, angle=90);
        @color OrangeRed alpha=200;
    }
    @tile protofilament(sides=2, radius=8.0) {
        @connector c_head(vertices=[v1,v2], glue=g_proto, angle=13);
        @connector c_tail(vertices=[v2,v1], glue=g_proto, angle=13);
        @color SeaGreen alpha=160;
    }
    /* Hollow 18 nm core: ordered water channel. */
    @tile water_channel(sides=12, radius=9.0) {
        @connector c1(vertices=[v1,v2], glue=g_water, angle=30);
        @color DeepSkyBlue alpha=90;
    }

    @seed helix_ring at (0, 0, 0);
    @seed water_channel at (0, 0, 0);
}

@floating monomer(mobility=3, radius=0.04, concentration=13);
@floating dimer(mobility=2, radius=0.08, concentration=7);

def main() {
    @create monomer, monomer --> alpha_helix;
    @create dimer --> helix_ring;
    @create dimer --> protofilament;
}
