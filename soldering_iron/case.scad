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

button_diameter = 19;
button_hole_diameter = 15.8;
iron_bracket_width = 1.25*inch;

top_angle = 10;
top_angle_adjust = oak_thickness * tan(top_angle);
top_width = 
  oak_thickness +
  component_gutter +
  control_board_width +
  component_gutter +
  button_diameter +
  component_gutter +
  button_diameter +
  component_gutter +
  iron_bracket_width +
  component_gutter +
  oak_thickness;
top_height =
  top_angle_adjust +
  oak_thickness +
  component_gutter +
  control_board_height +
  component_gutter +
  oak_thickness +
  top_angle_adjust;

component_x = function(grid_pos)
  let (
    x_offset = oak_thickness +
      component_gutter +
      control_board_width +
      component_gutter +
      button_diameter/2,
    x_spacing = button_diameter + component_gutter
  )
  x_offset + grid_pos * x_spacing;
component_y = function(grid_pos)
  let (
    y_offset = -(top_angle_adjust + oak_thickness + component_gutter +  button_diameter/2),
    y_space = control_board_height - button_diameter,
    y_spacing = -y_space / 2
  )
  y_offset + grid_pos * y_spacing; 

up_button_position    = [component_x(  0), component_y(1), 0];
enter_button_position = [component_x(  1), component_y(1), 0];
power_switch_position = [component_x(0.5), component_y(2), 0];
iron_plug_position    = [component_x(0.5), component_y(0), 0];

iron_position = [
  top_width - oak_thickness - component_gutter - iron_bracket_width/2,
  component_y(1),
  0
];

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

module button() {
  $fn=35;
  translate([0,0,oak_thickness - 3]) {
    cylinder(11.2, d=12.7);
    cylinder(7, d=button_hole_diameter);
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

plug_shaft_diameter = 0.695*inch;
plug_shaft_height = 0.447*inch;
plug_flange_thickness = 2;
plug_key_thickness = 3;
plug_latch_thickness = 5;
module iron_plug() {
  translate([0,0,oak_thickness-plug_shaft_height/2]) cylinder(plug_shaft_height, d=plug_shaft_diameter, center=true);
  translate([0,0,oak_thickness+plug_flange_thickness/2]) cylinder(plug_flange_thickness, d=21.75, center=true);
}

iron_hole_diameter=0.783*inch;
module iron() {
  translate([0,0,oak_thickness]) {
    translate([0,0,3.97*inch/2]) cylinder(3.97*inch, d=0.518*inch, center=true);
    translate([0,0,1.8*inch/2]) cylinder(1.8*inch, d=0.786*inch, center=true);
    translate([0,0,0.4*inch/2]) cylinder(0.4*inch, d=0.9*inch, center=true);

    translate([0,0,-0.39*inch/2]) cylinder(0.39*inch, d=0.782*inch, center=true);
    translate([0,0,-0.97*inch/2]) cylinder(0.97*inch, d=0.512*inch, center=true);
    translate([0,0,-2.66*inch/2]) cylinder(2.66*inch, d=0.304*inch, center=true);
    translate([0,0,-2.66*inch - 0.58*inch/2]) cylinder(0.58*inch, d2=0.2*inch, d1=0.01*inch, center=true);
  }
}

module components() {
  translate([
    oak_thickness + component_gutter,
    -oak_thickness - component_gutter - top_angle_adjust,
    -0.2*inch
  ]) control_board();
  translate(up_button_position) button();
  translate(enter_button_position) button();
  translate(power_switch_position) power_switch();
  translate(iron_plug_position) iron_plug();
  translate(iron_position) iron();
}

viewport_diameter = (1+3/8)*inch;
viewport_floor_thickness = 1/4*inch;
viewport_through_width = segment_width*3 + 2*segment_gutter;

echo("top dimensions: ", top_width/inch, "x", top_height/inch);

module top() {
  module hole(position, diameter) {
    translate(position)
    translate([0,0,+oak_thickness/2])
    cylinder(oak_thickness+0.2, d=diameter, center=true);
  }

  viewport_x = oak_thickness + component_gutter + control_board_width/2;
  viewport_y = -top_angle_adjust -oak_thickness - component_gutter -segment_distance_from_top -segment_height/2;

  color("brown")
    difference() {
      translate([
        +top_width/2,
        -top_height/2,
        +oak_thickness/2
      ])
      cube([top_width,top_height,oak_thickness], center=true);
      
      translate([viewport_x, viewport_y, oak_thickness/2+viewport_floor_thickness])
        cylinder(oak_thickness, d=viewport_diameter, center=true);
      translate([viewport_x, viewport_y, 0])
        cube([viewport_through_width, segment_height,viewport_floor_thickness*2+0.1], center=true);
        
      hole(up_button_position, button_hole_diameter);
      hole(enter_button_position, button_hole_diameter);
      hole(power_switch_position, 0.46*inch);
      hole(iron_plug_position, plug_shaft_diameter);
      hole(iron_position, iron_hole_diameter);
    }
}

//components();
projection()
top();

