include <constants.scad>;

$fn = 30;

top_control_positions = let (
    top_form_edge_delta = (wood_base_corner_diameter - top_form_corner_diameter)/2,
    top_form_y_min = top_form_edge_delta,
    top_form_width = width - 2*top_form_edge_delta,
    outside_control_x = -top_form_width/2 + 1 + 1/4
) [
  [                  0, top_form_y_min + 2 + 3/8],
  [ -outside_control_x, top_form_y_min + 1 + 1/4],
  [                  0, top_form_y_min + 1 + 1/4],
  [ +outside_control_x, top_form_y_min + 1 + 1/4],
];

module wood_base() {
    color(wood_color) {
          linear_extrude(wood_base_thickness) {
              offset(r=wood_base_corner_diameter/2) {
                  polygon(upright_positions);
              }
              //offset(r=wood_base_corner_diameter/2) {
              //    projection()
              //      transformer();
              //}
          }
    }
}

module upright_cap() {
    module solid_bits() {
        rotate_extrude(angle = 360) {
            intersection() {
                union() {
                    translate([5/16,9/64 - 1/64])
                      circle(d=4/32);
                    translate([6/16,3/64])
                      circle(d=4/32);
                    polygon([
                      [0,    0],
                      [6/16, 0],
                      [5/16, upright_cap_height],
                      [0,    upright_cap_height]
                    ]);
                }
                square([5,upright_cap_height]);
            }
        }
    }
    module bore() {
        translate([0,0,1/16])
          cylinder(upright_cap_height+0.001, d=upright_diameter);
    }
    module screw_hole() {
        translate([0,0,-0.001])
          cylinder(upright_cap_height+0.005, d=1/4);
    }
    difference() {
        solid_bits();
        bore();
        screw_hole();
    }
}

module upright(height = 2) {
    color(wood_color)
      translate([0, 0, upright_cap_height])
        cylinder(height - 2*upright_cap_height, d=upright_diameter);
    upright_cap();
    translate([0, 0, height])
      rotate([180,0,0])
        upright_cap();
}

module uprights() {
    echo("UR HEIGHT:", height - wood_base_thickness - top_height);
    for (pos = upright_positions)
      translate(pos)
        upright(height - wood_base_thickness - top_height);
}

module top_form_corner_top() {
    rotate_extrude(angle=360) {
        intersection() {
            translate([top_form_corner_diameter/2 - top_form_top_radius,
                       top_form_thickness - top_form_top_radius])
              circle(r=top_form_top_radius);
            square([5,5]);
        }
    }
}

module top_form() {
    module corner_bottom() {
        rotate_extrude(angle=360) {
            square([top_form_corner_diameter/2 - top_form_fancy_inset, top_form_thickness - top_form_top_radius]);
            square([top_form_corner_diameter/2 - top_form_top_radius, top_form_thickness]);
        }
    }
    color(wood_color) {
        hull() for (pos = upright_positions) translate(pos) top_form_corner_top();
        hull() for (pos = upright_positions) translate(pos) corner_bottom(); 
    }
}

module control_plate() {
    hull()
    scale([0.9, 0.9, 1])
        for (pos = upright_positions)
            translate(pos) translate([0, 0.22, 0])
                circle(d=1/64);
}

module top_form_template() {
    scale([25.4,25.4,1])
    difference() {
        projection()
                top_form();
        for (pos = upright_positions)
            translate(pos)
                circle(d=1/64);
        for (pos = top_control_positions)
            translate(pos)
               circle(d=1/64);
        //control_plate();
    }
}

module case() {
    wood_base();
    translate([0,0,wood_base_thickness])
      uprights();
    translate([0,0,height - top_form_thickness])
      top_form();
}


module transformer() {
   translate(transformer_position)
     cube(transformer_dimensions);
}


module bottom_template() {
    projection()
        scale([25.4,25.4,25.4]) {
            difference() {
                top_form();
                for (pos = upright_positions)
                    translate(pos)
                        cylinder(2, 1/64);
            }
        }
}

module hammerforming_support() {
    scale([25.4,25.4,25.4]) {
        difference() {
            hull()
                for (pos = upright_positions)
                    translate(pos)
                        circle(d=upright_diameter - 2*top_form_top_radius);
            for (pos = top_control_positions)
                translate(pos)
                    circle(d=1/64);
        }
    }
}

module hammerforming_sheet_template() {
    // sheet is 150x150mm
    diameter = 150/25.4 - ( upright_positions[1].x - upright_positions[0].x );
    
    scale([25.4,25.4,25.4]) {
        difference() {
            hull()
                for (pos = upright_positions)
                    translate(pos)
                        circle(d=diameter);
            for (pos = top_control_positions)
                translate(pos)
                    circle(d=1/64);
        }
    }
}

module nixie() {
    translate([0, +nixie_depth/2, +nixie_height/2])
    intersection() {
        cube([nixie_width, nixie_depth, nixie_height], center=true);
    }
}

module display() {
    nixie_bottom = height - nixie_height - top_height - nixie_spacing_from_top;
    echo("NIXIE BOTTOM:", nixie_bottom);
    translate([0, 0, nixie_bottom]) {
        nixie();
        translate([-nixie_width - nixie_spacing, 0, 0]) nixie();
        translate([+nixie_width + nixie_spacing, 0, 0]) nixie();
    }
}

//case();
//transformer();
//display();
//bottom_template();
top_form_template();
//control_plate();
