use <dsub.scad>;

hp = 5.08;
faceplate_width = 10 * hp;
faceplate_height = 128.5;
rail_clearance = 12;
edge_clearance = 5;
dsub_distance = 17;

panel_mount_usb_neck_diameter = 15;
panel_mount_usb_neck_length = 9;
panel_mount_usb_shoulder_diameter = 22;
panel_mount_usb_flat_edge = 0.8;

bracket_depth = 1.75 * 25.4;
tab_width = 6;
rivet_hole_diameter = 3.5;
standoff_hole_diameter = 2.5;

module usb_hole() {
  difference() {
    circle(d=panel_mount_usb_neck_diameter);
    translate([panel_mount_usb_neck_diameter - panel_mount_usb_flat_edge, 0])
      square(panel_mount_usb_neck_diameter, center=true);
  }
}

module faceplate_holes() {
  translate([-dsub_distance/2, 29]) dsub_2(25.37);
  translate([+dsub_distance/2, 29]) dsub_2(25.37);

  translate([9.5+2.6, -44.5-2.6]) circle(d=5.2,$fn=25);
  translate([0, -8]) usb_hole();
}

module standoff_hole() {
  circle(d=standoff_hole_diameter, $fn=15);
}

module rivet_hole() {
  circle(d=rivet_hole_diameter, $fn=15);
}

module pico_standoffs() {
  pico_standoff_x_distance = 11.4;
  pico_standoff_y_distance = 51 - 2*2;
  for (x = [-1, 1]) {
    for (y = [-1, 1]) {
      translate([x*pico_standoff_x_distance/2, y*pico_standoff_y_distance/2])
        standoff_hole();
    }
  }
}

module bracket() {
  bracket_width = faceplate_width - 2*edge_clearance;
  bracket_height = faceplate_height - 2*rail_clearance;
  difference() {
    union() {
      square([bracket_width, bracket_height], center=true);
      translate([bracket_width/2 + bracket_depth/2, 0])
        square([bracket_depth, bracket_height], center=true);
      polygon(points = [
        [-bracket_width/2, bracket_height/2],
        [+bracket_width/2, bracket_height/2 + bracket_depth],
        [+bracket_width/2+tab_width, bracket_height/2 + bracket_depth],
        [+bracket_width/2+tab_width, bracket_height/2 + tab_width],
        [+bracket_width/2, bracket_height/2]
      ]);
      polygon(points = [
        [-bracket_width/2, -bracket_height/2],
        [+bracket_width/2, -bracket_height/2 - bracket_depth],
        [+bracket_width/2+tab_width, -bracket_height/2 - bracket_depth],
        [+bracket_width/2+tab_width, -bracket_height/2 - tab_width],
        [+bracket_width/2, -bracket_height/2]
      ]);
    }
    faceplate_holes();
    
    // Top structural rivets
    translate([bracket_width/2 + tab_width/2, bracket_height/2 + 10])
      rivet_hole();
    translate([bracket_width/2 + tab_width/2, bracket_height/2 + bracket_depth - 10])
      rivet_hole();
    translate([bracket_width/2 + 10, bracket_height/2 - tab_width/2])
      rivet_hole();
    translate([bracket_width/2 + bracket_depth - 10, bracket_height/2 - tab_width/2])
      rivet_hole();

    // Bottom structural rivets
    translate([bracket_width/2 + tab_width/2, -(bracket_height/2 + 10)])
      rivet_hole();
    translate([bracket_width/2 + tab_width/2, -(bracket_height/2 + bracket_depth - 10)])
      rivet_hole();
    translate([bracket_width/2 + 10, -(bracket_height/2 - tab_width/2)])
      rivet_hole();
    translate([bracket_width/2 + bracket_depth - 10, -(bracket_height/2 - tab_width/2)])
      rivet_hole();

    // IDC connector standoffs
    idc_connector_board_height = 22.23;
    idc_connector_board_y_offset = 43;
    idc_connector_board_standoff_distance = 16;
    translate([bracket_width/2 + idc_connector_board_height, idc_connector_board_y_offset])
      standoff_hole();
    translate([
        bracket_width/2 + idc_connector_board_height + idc_connector_board_standoff_distance,
        idc_connector_board_y_offset
      ])
      standoff_hole();

    // Raspberry Pico standoffs
    translate([bracket_width/2 + 11.4/2 + idc_connector_board_height + 2, -12])
      pico_standoffs();

  }
}

bracket();
