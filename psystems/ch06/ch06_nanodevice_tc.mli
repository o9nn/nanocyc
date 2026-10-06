/*
 * ch06_nanodevice_tc.mli
 *
 * Geometric companion to ch06_nanodevice_tc.pli (sections 6.2, 6.2.2).
 * The nano-device is a spatial sample: pump and probe live in separated
 * frequency domains, and the microtubule transmits only in a triplet of
 * triplet bands (kHz protofilament, MHz elastic, GHz water channel).
 *
 * Traceability: src/cpp/nanobrain_ppm.h
 */

@import "ch06_nanodevice_tc.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold device_tube(dimension=3, compact=false, charts=3);
@capability separated_pump_probe;

@tiling {
    @glue g_pump;
    @glue g_band;
    @glue_relation(g_pump, g_band);
    @glue_relation(g_band, g_band);
    @glue_radius 0.1;

    @tile device(sides=6, radius=2.0) {
        @connector c_pump(vertices=[v1,v2], glue=g_pump, angle=90);
        @connector c_probe(vertices=[v3,v4], glue=g_band, angle=90);
        @color SlateGray alpha=200;
    }
    @tile band_khz(sides=3, radius=6.0) {
        @connector c1(vertices=[v1,v2], glue=g_band, angle=120);
        @color Green alpha=140;
    }
    @tile band_mhz(sides=3, radius=3.0) {
        @connector c1(vertices=[v1,v2], glue=g_band, angle=120);
        @color Yellow alpha=180;
    }
    @tile band_ghz(sides=3, radius=1.0) {
        @connector c1(vertices=[v1,v2], glue=g_band, angle=120);
        @color Red alpha=200;
    }

    @seed device at (0, 0, 0);
}

@floating pump(mobility=1, radius=0.05, concentration=1);
@floating probe(mobility=4, radius=0.02, concentration=1);

def main() {
    @create pump --> device;
    @create probe --> band_khz;
    @create probe --> band_mhz;
    @create probe --> band_ghz;
}
