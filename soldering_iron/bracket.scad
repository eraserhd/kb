include <constants.scad>;

$fn = 50;

module baseplate() {
    inset = 1/8;
    thickness = 1/4;

    linear_extrude(height=thickness)
    offset(delta=-inset)
    difference() {
        polygon(points=[
            each upright_positions,
            upright_positions[0]
        ]);
        for (p = upright_positions)
            translate(p) circle(d=upright_cap_diameter);
    }
}

baseplate();
