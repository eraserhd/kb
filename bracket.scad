use <dsub.scad>;

hp = 5.08;
faceplate_width = 10 * hp;
faceplate_height = 128.5;
rail_clearance = 8.5;
edge_clearance = 5;
dsub_distance = 17;

panel_mount_usb_neck_diameter = 15;
panel_mount_usb_neck_length = 9;
panel_mount_usb_shoulder_diameter = 22;
panel_mount_usb_flat_edge = 0.8;

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

  translate([9.5+2.6, -44.5-2.6]) circle(d=5.2);
  translate([0, -8]) usb_hole();
}

difference() {
  square([faceplate_width - 2*edge_clearance, faceplate_height - 2*rail_clearance], center=true);
  faceplate_holes();
}
