
width = 4;
left_depth = 3.5;
right_depth = 2.8;
height = 3.75;
top_height = 1/2;

wood_base_thickness = 1/2;
top_form_thickness = 1/2;

upright_diameter = 5/8;
wood_base_corner_diameter = 1;
wood_color = "brown";

upright_cap_height = 3/16;

$fn = 30;

upright_positions = function(inset = 0)
  let (
    edge_distance = wood_base_corner_diameter/2 + inset
  ) [
    [edge_distance, edge_distance],
    [width-2*edge_distance, edge_distance],
    [width-2*edge_distance, right_depth-2*edge_distance],
    [edge_distance, left_depth-2*edge_distance]
  ];


module wood_base() {
    roundover_radius = wood_base_thickness/8;
    color(wood_color) {
      minkowski() {
          linear_extrude(wood_base_thickness - roundover_radius) {
              offset(r=wood_base_corner_diameter/2) {
                  polygon(upright_positions(roundover_radius/2));
              }
          }
          sphere(d=roundover_radius*2);
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

module top_form() {
    corner_diameter = 3/4; 
    module corner() {
        translate([0,0,corner_diameter/2])
          sphere(d=corner_diameter);
        cylinder(corner_diameter/2, d=corner_diameter);
    }
    color(wood_color) {
        hull() {
            for (pos = upright_positions())
                translate(pos) corner();
        }
    }
}

module case() {
    wood_base();
    translate([0,0,wood_base_thickness])
      uprights();
    translate([0,0,height - top_form_thickness])
      top_form();
}

case();
//upright_cap();
