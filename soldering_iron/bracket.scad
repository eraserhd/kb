include <constants.scad>;

module baseplate() {
    inset = 1/4;
    thickness = 1/4;

    linear_extrude(h=thickness)
    offset(delta=-inset)
    difference() {
        polygon(points=[
            each upright_positions,
            upright_positions[0]
        ]);
        for (p = upright_positions)
            circle(d=upright_diameter + inset);
    } 
}

baseplate();