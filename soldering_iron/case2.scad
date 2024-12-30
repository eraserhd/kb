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

function corrected_radius(r, n=0) = r / cos(180/(n == 0 ? $fn : n));

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

module top_form_router_template() {
    linear_extrude(1/4 * 25.4)
    scale([25.4,25.4,25.4])
    difference() {
        projection()
                top_form();
        for (pos = upright_positions)
            translate(pos)
                circle(r=corrected_radius(13/32/2 + (0.8/25.4/2)));
        //for (pos = top_control_positions)
        //    translate(pos)
        //       circle(d=5/64);
        control_plate();
    }
}

module control_plate_template() {
    linear_extrude(25.4/4)
    scale([25.4,25.4,25.4])
    difference() {
        control_plate();
        for (pos = top_control_positions)
            translate(pos)
               circle(d=5/64);
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

control_plate_corners = [
    for (pos = upright_positions)
        [pos.x * 0.85, (pos.y + 0.3) * 0.85]
];

function vec_length(v) = sqrt(v[0] * v[0] + v[1] * v[1]);
function normalize(v) = v / vec_length(v);

function inset_point(left, p, right, dist) =
    let(
       v1 = normalize(left - p),
       v2 = normalize(right - p),
       bisector = normalize(v1 + v2),
       angle = acos(v1 * v2),
       inset_dist = dist / sin(angle/2)
    )
    p + bisector * inset_dist;

function inset_points(points, dist) =
    [ 
    for (i = [0:len(points)-1])
    inset_point(
       points[(i+len(points)-1)%len(points)],
       points[i],
       points[(i+1)%len(points)],
       dist
       )
    ];

cp_m3_holes = [
  each inset_points(control_plate_corners, 1/8),
  [-11/25.4, 2.5],
  [+11/25.4, 2.5]
];

module control_plate(marks = false) {
    thickness = 1/8;
    m3_clearance_diameter = 3/25.4;
    button_hole_diameter = 0.647;
    switch_hole_diameter = 0.482;
    port_hole_diameter = 0.6;
    
    module mark(d) {
    	if (marks)
    	   cylinder(h=thickness+0.1, d=1/64);
    	else
    	   cylinder(h=thickness+0.1, d=d);
    }

    difference() {
        linear_extrude(thickness)
        polygon(points=control_plate_corners);

        for (p = cp_m3_holes)
        translate(p)
        translate([0,0,-0.05])
        mark(d=m3_clearance_diameter);

        translate([-1,1.375,-0.05]) mark(d=button_hole_diameter);
        translate([0,1.375,-0.05]) mark(d=button_hole_diameter);
        translate([+1,1.375,-0.05]) mark(d=switch_hole_diameter);
        
        //translate([0 - 11/25.4,2.5,-0.05]) mark(d=m3_clearance_diameter);
        translate([0,2.5,-0.05]) mark(d=port_hole_diameter);
        //translate([0 + 11/25.4,2.5,-0.05]) mark(d=m3_clearance_diameter);
    }
}

module soft_jaws() {
   difference() {
   cube([3, 3 - 2.2 - 0.2, 1/4],center = true);
   
   translate([0,-3.25,0])
   linear_extrude(1/4 + 0.1)
   polygon(points=control_plate_corners);
   
   }
}

//case();
//transformer();
//display();
//bottom_template();
//top_form_router_template();
//control_plate_template();

scale([25.4,25.4,25.4])
scale([86.36/86.25, 86.36/86.25,1])
projection()
control_plate(marks=true);

//scale([25.4,25.4,25.4])
//soft_jaws();

min_x = min([for (p = control_plate_corners) p.x]);
min_y = min([for (p = control_plate_corners) p.y]);
adj_m3_holes = [for (p = cp_m3_holes) [p.x-min_x, p.y-min_y]];

// 
echo("DRILL M3:", adj_m3_holes);
echo("DRILL 0.482:", [[1-min_x,1.375-min_y]]);
echo("DRILL 0.6:", [[0-min_x,2.5-min_y]]); 
echo("DRILL 0.647:", [[-1-min_x,1.375-min_y], [0-min_x,1.375-min_y]]);

