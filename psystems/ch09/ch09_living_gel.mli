/*
 * ch09_living_gel.mli
 *
 * Geometric companion to ch09_living_gel.pli (section 9.4).
 * The gel listens first, then grows across nested scales: angstrom, nano,
 * micro, milli, centimeter. Each scale is a tile shell the growth wave fills
 * before the next larger shell is created.
 *
 * Traceability: src/cpp/nanobrain_brain_jelly.h
 */

@import "ch09_living_gel.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold scale_cascade(dimension=3, compact=false, charts=5);
@capability listen_then_grow;

@tiling {
    @glue g_scale;
    @glue g_ear;
    @glue_relation(g_ear, g_scale);
    @glue_relation(g_scale, g_scale);
    @glue_radius 0.05;

    @tile ear(sides=4, radius=0.2) {
        @connector c1(vertices=[v1,v2], glue=g_ear, angle=90);
        @color Pink alpha=180;
    }
    @tile atomic(sides=4, radius=0.1) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color White alpha=255;
    }
    @tile nano(sides=4, radius=0.4) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color LightGreen alpha=160;
    }
    @tile micro(sides=4, radius=1.0) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color LimeGreen alpha=160;
    }
    @tile milli(sides=4, radius=2.5) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color ForestGreen alpha=160;
    }
    @tile centi(sides=4, radius=6.0) {
        @connector c1(vertices=[v1,v2], glue=g_scale, angle=90);
        @color DarkGreen alpha=180;
    }

    @seed ear at (0, 0, 0);
    @seed atomic at (0, 0, 0);
}

@floating signal(mobility=6, radius=0.01, concentration=1);
@floating monomer(mobility=2, radius=0.02, concentration=8);

def main() {
    @create signal --> ear;
    @create monomer --> atomic;
    @create monomer, monomer --> nano;
    @create monomer, monomer, monomer --> micro;
    @create monomer --> milli;
    @create monomer --> centi;
    signal, monomer --> monomer;
}
