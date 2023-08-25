inch = 25.4;
oak_thickness = 5/8*inch;
component_gutter = 1/8*inch;

control_board_width = 2.349*inch;
control_board_height = 2.727*inch;
control_board_thickness = 0.068*inch;
segment_distance_from_top = 0.977*inch;
segment_height = 0.433*inch;
segment_gutter = 0.01*inch;
segment_width = (0.869*inch - 2*segment_gutter)/3;
segment_depth = 0.195*inch;

button_position = function(n)
  let (
    x_offset = control_board_width + component_gutter + button_diameter/2,
    y_space = control_board_height - button_diameter,
    y_offset = -button_diameter/2,
    y_spacing = -y_space / 2
  )
  [x_offset, y_offset + (n-1)*y_spacing, 0];

// reference: upper, left corner at 0,0
module control_board() {
  screw_hole_diameter = 0.125*inch;
  top_screw_hole_distance = 0.275*inch;
  bottom_screw_hole_distance = 0.1565*inch;
  side_screw_hole_distance = 0.3925*inch;
  
  module segment_display() {
    cube([segment_width, segment_height, segment_depth],center=true);
  }
  translate([
      +control_board_width/2,
      -control_board_height/2,
      -control_board_thickness/2 - segment_depth
  ]) {
    difference() {
      union() {
        color("green")
          cube([control_board_width,control_board_height,control_board_thickness], center=true);
        color("white")
          translate([0,
                    +control_board_height/2 - segment_height/2 - segment_distance_from_top,
                    control_board_thickness/2+segment_depth/2
          ]) {
            translate([-segment_width-segment_gutter,0,0]) segment_display();
            segment_display();
            translate([+segment_width+segment_gutter,0,0]) segment_display();
          }
      }
      translate([0,+control_board_height/2-top_screw_hole_distance,0])
        cylinder(control_board_thickness*2, d=screw_hole_diameter, center=true, $fn=10);
      translate([+control_board_width/2-side_screw_hole_distance,-control_board_height/2+bottom_screw_hole_distance,0])
        cylinder(control_board_thickness*2, d=screw_hole_diameter, center=true, $fn=10);
      translate([-control_board_width/2+side_screw_hole_distance,-control_board_height/2+bottom_screw_hole_distance,0])
        cylinder(control_board_thickness*2, d=screw_hole_diameter, center=true, $fn=10);
    }
  }
}

button_diameter = 19;
module button() {
  $fn=35;
  translate([0,0,oak_thickness - 3]) {
    cylinder(11.2, d=12.7);
    cylinder(7, d=15.8);
    translate([0,0,3]) cylinder(3, d=button_diameter);
    translate([0,0,-21]) cylinder(21, d=button_diameter);
  }
}


module power_switch() {
  $fn=30;
  shaft_diameter = 0.4565*inch;
  shaft_height = 0.327*inch;
  ring_diameter = 0.588*inch;
  ring_thickness = 0.0855*inch;
  ring_position = 0.21*inch;
  
  translate ([0,0,oak_thickness - ring_position]) {
    difference() {
      cylinder(shaft_height, d=shaft_diameter);
      translate([0,0,-0.05]) cylinder(shaft_height+0.1, d=0.2435*inch);
    }
    translate([0,0,ring_position])
      difference() {
        cylinder(ring_thickness, d=ring_diameter);
        translate([0,0,-0.1]) cylinder(ring_thickness+0.2, d=shaft_diameter+0.1);
      }
  }
}

module components() {
  translate([0,0, -0.2*inch]) control_board();
  translate(button_position(1)) button();
  translate(button_position(2)) button();
  translate(button_position(3)) power_switch();
}

top_width = control_board_width + button_diameter + 3*component_gutter + 2*oak_thickness;
top_height = control_board_height + 2*component_gutter + 2*oak_thickness;
viewport_diameter = (1+3/8)*inch;
viewport_floor_thickness = 1/4*inch;
viewport_through_width = segment_width*3 + 2*segment_gutter;
module top() {
  viewport_x = control_board_width/2;
  viewport_y = -segment_distance_from_top -segment_height/2;

  color("brown")
    difference() {
      translate([
        +top_width/2 - component_gutter - oak_thickness,
        -top_height/2 + component_gutter + oak_thickness,
        +oak_thickness/2
      ])
      cube([top_width,top_height,oak_thickness], center=true);
      translate([viewport_x, viewport_y, oak_thickness/2+viewport_floor_thickness])
        cylinder(oak_thickness, d=viewport_diameter, center=true);
      translate([viewport_x, viewport_y, 0])
        cube([viewport_through_width, segment_height,viewport_floor_thickness*2+0.1], center=true);
    }
}

components();
top();


