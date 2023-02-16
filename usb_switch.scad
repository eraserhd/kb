
hp = 5.08;
faceplate_width = 10 * hp;
faceplate_height = 129;
rail_clearance = 12;

screw_hole_diameter = 3;
screw_hole_distance_from_top = 1.5 + screw_hole_diameter/2;
screw_hole_distance_from_side = 4.6 + 5/2;
slot_center_distance = 122.5;

rotary_switch_body_diameter = 44.5;
rotary_switch_shaft_diameter = 8;

module rounded_rectangle(width, height, diameter) {
  hull() {
    for (x = [-1, 1]) {
      for (y = [-1, 1]) {
        translate([x*(width/2 - diameter/2), y*(height/2 - diameter/2)]) circle(d=diameter);
      }
    }
  }
}

usba_body_height = 18;
usba_max_corner_diameter = 1.38;
module usba() {
  usba_hole_width = 16.55;
  usba_hole_height = 14.55;
  screw_hole_diameter = 3.25;
  module screw_hole() {
    circle(d=screw_hole_diameter, $fn=25);
  }
  rounded_rectangle(usba_hole_width, usba_hole_height, 1, $fn=20);
  translate([-24/2, +9/2]) screw_hole();
  translate([+24/2, -9/2]) screw_hole();
}

usbmini_body_width = 20;
usbmini_body_height = 10;
usbmini_max_corner_diameter = 1.25;
module usbmini() {
  hole_width = 9.75;
  hole_height = 6.75;
  rounded_rectangle(hole_width, hole_height, 1);
  translate([-15/2,0]) circle(d=2.8,$fn=25);
  translate([+15/2,0]) circle(d=2.8,$fn=25);
}

module faceplate() {
  usba_offset = -faceplate_height/2 + usba_body_height/2 + rail_clearance + 5;
  difference() {
    square([faceplate_width, faceplate_height], center=true);
    translate([0, usba_offset]) usba();
    translate([0, usba_offset + usba_body_height/2 + rotary_switch_body_diameter/2])
      circle(d=rotary_switch_shaft_diameter, $fn=25);
    //translate([0, usba_offset + usba_body_height/2 + rotary_switch_body_diameter/2])
    //  circle(d=rotary_switch_body_diameter, $fn=25);

    inner_distance = usbmini_body_height + 2;
    top_distance = rotary_switch_body_diameter/2 + usbmini_body_width/2 + 5;
    bottom_distance = top_distance - 10;
    
    translate([-inner_distance/2,top_distance]) rotate([0,0,90]) usbmini();
    translate([+inner_distance/2,top_distance]) rotate([0,0,90]) usbmini();
    translate([-inner_distance/2-inner_distance,bottom_distance]) rotate([0,0,90]) usbmini();
    translate([+inner_distance/2+inner_distance,bottom_distance]) rotate([0,0,90]) usbmini();
    
    for (x = [-1, 1]) {
        for (y = [-1, 1]) {
            translate([
              x*(faceplate_width/2 - screw_hole_distance_from_side),
              y*slot_center_distance/2,
              0
            ])
              circle(d=screw_hole_diameter, $fn=20);
        }
    }
  }
}

faceplate();
