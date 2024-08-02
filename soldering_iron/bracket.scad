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

module transformer_mount() {
    transformer_hole_spacing_x = 44 / 25.4;
    transformer_hole_spacing_y = 56 / 25.4;
    spacer_diameter = 6 / 25.4;
    spacer_height = 3/4;
    
    for (x = [-transformer_hole_spacing_x/2, +transformer_hole_spacing_x/2])
    for (y = [-transformer_hole_spacing_y/2, +transformer_hole_spacing_y/2])
    translate([x,y,0]) cylinder(d=spacer_diameter, h=spacer_height);
}

baseplate();
translate([0,2,1/4]) rotate([0,0,90]) transformer_mount();
