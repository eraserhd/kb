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

module transformer() {
    core_x = 2.12;
    core_y = 2.61;
    core_z = 1.2;
    bottom_protrusion = 0.4;
    bottom_x = 1.3;
    bottom_y = 1.7;
    top_x = 2.14;
    top_y = 1.7;
    top_protrusion = 3/4;
    board_extra = 0.2;
    board_x = 1.11;
    board_y = 2;
    board_z = 0.55;

    translate([0, 0, core_z/2])
        cube([core_x, core_y, core_z], center=true);
    translate([0, 0, -bottom_protrusion/2])
        cube([bottom_x, bottom_y, bottom_protrusion], center=true);
    translate([0, 0, top_protrusion/2 + core_z])
        cube([top_x, top_y, top_protrusion], center=true);
    translate([-board_x/2 + core_x/2 + board_extra, 0, board_z/2 + core_z + top_protrusion])
        cube([board_x, board_y, board_z], center=true);
}

module transformer_mount(height=1/2, show_transformer=false) {
    transformer_hole_spacing_x = 44 / 25.4;
    transformer_hole_spacing_y = 56 / 25.4;
    spacer_diameter = 6 / 25.4;

    for (x = [-transformer_hole_spacing_x/2, +transformer_hole_spacing_x/2])
    for (y = [-transformer_hole_spacing_y/2, +transformer_hole_spacing_y/2])
    translate([x,y,0]) cylinder(d=spacer_diameter, h=height);

    if (show_transformer)
        translate([0,0,height]) color("lightblue") transformer();
}

module nixie_clearance() {
    behind_nixie = 19/25.4;
    color("tomato") {
        translate([
            0,
            +behind_nixie/2 + 5/8, // 5/8 is a guess
            -nixie_height/2 + 5 - nixie_spacing_from_top
        ])
        cube([3*nixie_width + 2*nixie_spacing,behind_nixie, nixie_height],center=true);
    }
}

baseplate();
translate([0,0,5 - 1/4]) %baseplate();

translate([0,1.8,1/4]) rotate([0,0,90]) transformer_mount(show_transformer=true);

nixie_clearance();
