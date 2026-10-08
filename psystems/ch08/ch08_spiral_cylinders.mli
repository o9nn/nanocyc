/*
 * ch08_spiral_cylinders.mli
 *
 * Geometric companion to ch08_spiral_cylinders.pli (sections 8.2-8.2.2).
 * The Hinductor is three concentric spiral cylinders — a capacitor inside a
 * capacitor inside a capacitor — with pitch, diameter and a twist that
 * clocks through edge and screw dislocations.
 *
 * Traceability: src/cpp/nanobrain_hinductor.h
 */

@import "ch08_spiral_cylinders.pli";

@msystem<morphogenetic>
@geometry<euclidean>;
@manifold concentric_cylinders(dimension=3, compact=false, charts=3);
@capability topology_regulates_polarization;

@tiling {
    @glue g_wall;
    @glue g_twist;
    @glue_relation(g_wall, g_wall);
    @glue_relation(g_twist, g_twist);
    @glue_radius 0.15;

    @tile inner_cylinder(sides=8, radius=1.0) {
        @connector c_wall(vertices=[v1,v2], glue=g_wall, angle=45);
        @connector c_twist(vertices=[v2,v3], glue=g_twist, angle=15);
        @color DeepSkyBlue alpha=220;
    }
    @tile central_cylinder(sides=8, radius=2.0) {
        @connector c_wall(vertices=[v1,v2], glue=g_wall, angle=45);
        @connector c_twist(vertices=[v2,v3], glue=g_twist, angle=45);
        @color MediumPurple alpha=180;
    }
    @tile outer_cylinder(sides=8, radius=3.0) {
        @connector c_wall(vertices=[v1,v2], glue=g_wall, angle=45);
        @connector c_twist(vertices=[v2,v3], glue=g_twist, angle=90);
        @color DarkMagenta alpha=140;
    }

    @seed inner_cylinder at (0, 0, 0);
    @seed central_cylinder at (0, 0, 0);
    @seed outer_cylinder at (0, 0, 0);
}

@floating pump(mobility=2, radius=0.05, concentration=4);
@floating flux(mobility=1, radius=0.05, concentration=1);

def main() {
    @create pump --> inner_cylinder;
    @create pump --> central_cylinder;
    @create pump --> outer_cylinder;
    pump, flux --> flux;
}
