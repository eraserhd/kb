inch = 25.4;
oak_thickness = 5/8*inch;
component_gutter = 1/8*inch;

control_board_width = 2.349*inch;
control_board_height = 2.727*inch;
control_board_thickness = 0.068*inch;

module control_board() {
  segment_height = 0.433*inch;
  segment_gutter = 0.01*inch;
  segment_width = (0.869*inch - 2*segment_gutter)/3;
  segment_depth = 0.195*inch;
  segment_distance_from_top = 0.977*inch;
  screw_hole_diameter = 0.125*inch;
  top_screw_hole_distance = 0.275*inch;
  bottom_screw_hole_distance = control_board_height - 0.1565*inch;
  side_screw_hole_distance = 0.3925*inch;
  
  module segment_display() {
    cube([segment_width, segment_height, segment_depth],center=true);
  }
  difference() {
    union() {
      color("green")
        cube([control_board_width,control_board_height,control_board_thickness], center=true);
      color("white")
        translate([0,-control_board_height/2 + segment_height/2 + segment_distance_from_top,0]) {
          translate([-segment_width-segment_gutter,0,control_board_thickness/2]) segment_display();
          translate([0,0,control_board_thickness/2]) segment_display();
          translate([+segment_width+segment_gutter,0,control_board_thickness/2]) segment_display();
        }
    }
    translate([0,-control_board_height/2+top_screw_hole_distance,0])
      cylinder(control_board_thickness*2, d=screw_hole_diameter, center=true, $fn=10);
    translate([+control_board_width/2-side_screw_hole_distance,-control_board_height/2+bottom_screw_hole_distance,0])
      cylinder(control_board_thickness*2, d=screw_hole_diameter, center=true, $fn=10);
    translate([-control_board_width/2+side_screw_hole_distance,-control_board_height/2+bottom_screw_hole_distance,0])
      cylinder(control_board_thickness*2, d=screw_hole_diameter, center=true, $fn=10);
  }
}

module button() {
  $fn=35;
  cylinder(11.2, d=12.7);
  cylinder(7, d=15.8);
  translate([0,0,3]) cylinder(3, d=19);
  translate([0,0,-21]) cylinder(21, d=19);
}

control_board();
button();

