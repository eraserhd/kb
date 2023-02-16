
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

usbmini_body_width = 20;
usbmini_body_height = 10;
module usbmini() {
  hole_width = 9.75;
  hole_height = 6.75;
  square([hole_width, hole_height], center=true);
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
  }
}

faceplate();
