panel_mount_usb_neck_diameter = 15;
panel_mount_usb_neck_length = 9;
panel_mount_usb_shoulder_diameter = 22;
panel_mount_usb_flat_edge = 0.8;


difference() {
  cylinder(d=panel_mount_usb_neck_diameter+6.5, h=7.5, center=true);
  difference() {
    cylinder(d=panel_mount_usb_neck_diameter, h=7.51, center=true);
    translate([panel_mount_usb_neck_diameter - panel_mount_usb_flat_edge,0,0])
      cube([panel_mount_usb_neck_diameter,panel_mount_usb_neck_diameter, 7.51], center=true);
  }
  translate([-panel_mount_usb_neck_diameter-0.6,0,0])
  cube([panel_mount_usb_neck_diameter,panel_mount_usb_neck_diameter, 7.51], center=true);
}
