
width = 5;
left_depth = 4.25;
right_depth = 3.5;
height = 6;
top_height = 1/2;

wood_base_thickness = 3/4;

upright_diameter = 5/8;
wood_base_corner_diameter = 1;
wood_color = "brown";

upright_cap_height = 3/16;

top_form_thickness = 1/2;
top_form_corner_diameter = 3/4;
top_form_top_diameter = 1/4;
top_form_fancy_inset = 1/64;

transformer_dimensions = [2.61, 2.34, 2.68];
transformer_position = [
    -(transformer_dimensions.x/2),
    wood_base_corner_diameter,
    wood_base_thickness + 0.25
];

$fn = 30;

upright_positions = function(inset = 0)
  let (
    edge_distance = wood_base_corner_diameter/2 + inset
  ) [
    [-width/2 + edge_distance, edge_distance],
    [ width/2 - edge_distance, edge_distance],
    [ width/2 - edge_distance, right_depth-edge_distance],
    [ 0,                       left_depth-edge_distance],
    [-width/2 + edge_distance, right_depth-edge_distance]
  ];



echo("POSITIONS:", upright_positions());

module wood_base() {
    color(wood_color) {
          linear_extrude(wood_base_thickness) {
              offset(r=wood_base_corner_diameter/2) {
                  polygon(upright_positions());
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
    for (pos = upright_positions())
      translate(pos)
        upright(height - wood_base_thickness - top_height);
}

module top_form_corner_top() {
    rotate_extrude(angle=360) {
        intersection() {
            translate([top_form_corner_diameter/2 - top_form_top_diameter/2,
                       top_form_thickness - top_form_top_diameter/2])
              circle(d=top_form_top_diameter);
            square([5,5]);
        }
    }
}

module top_form() {
    module corner_bottom() {
        rotate_extrude(angle=360) {
            square([top_form_corner_diameter/2 - top_form_fancy_inset, top_form_thickness - top_form_top_diameter/2]);
            square([top_form_corner_diameter/2 - top_form_top_diameter/2, top_form_thickness]);
        }
    }
    color(wood_color) {
        hull() for (pos = upright_positions()) translate(pos) top_form_corner_top();
        hull() for (pos = upright_positions()) translate(pos) corner_bottom(); 
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
                for (pos = upright_positions())
                    translate(pos)
                        cylinder(2, 1/64);
            }
        }
}

case();
transformer();
//bottom_template();
