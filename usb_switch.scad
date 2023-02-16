
hp = 5.08;
faceplate_width = 10 * hp;
faceplate_height = 128.5;
rail_clearance = 12;

rotary_switch_body_diameter = 44.5;
rotary_switch_shaft_diameter = 8;

usba_body_height = 18;
module usba() {
  usba_hole_width = 16.55;
  usba_hole_height = 14.55;
  screw_hole_diameter = 3.25;
  module screw_hole() {
    circle(d=screw_hole_diameter, $fn=25);
  }
  square([usba_hole_width, usba_hole_height], center=true);
  translate([-24/2, +9/2]) screw_hole();
  translate([+24/2, -9/2]) screw_hole();
}

module faceplate() {
  usba_offset = -faceplate_height/2 + usba_body_height/2 + rail_clearance + 5;
  difference() {
    square([faceplate_width, faceplate_height], center=true);
    translate([0, usba_offset]) usba();
    translate([0, usba_offset + usba_body_height/2 + rotary_switch_body_diameter/2])
      circle(d=rotary_switch_shaft_diameter);
  }
}

faceplate();
