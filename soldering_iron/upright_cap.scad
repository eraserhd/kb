
to_metric = function(amt) amt*25.4;

$fn = 35;

module cutter() {
   radius = to_metric(0.05);
   blank_width = to_metric(1/4);
   difference() {
     square([2*blank_width, blank_width]);
     circle(r=radius);
   }
}

module thing() {
    difference() {
      union() {
        cylinder(d = to_metric(0.852), h = to_metric(0.1));
        cylinder(d = to_metric(0.736), h = to_metric(0.2));
      }

      translate([0, 0, to_metric(0.1)])
        cylinder(d = to_metric(0.632), h = to_metric(0.31));
        
      translate([0, 0, -0.1])
        cylinder(d = to_metric(0.25), h = to_metric(0.5));
        
      rotate_extrude() translate([to_metric(0.736/2), to_metric(0.05)]) cutter();
      rotate_extrude() translate([to_metric(0.632/2), to_metric(0.15)]) cutter();
    }
}


thing();

//cutter();
