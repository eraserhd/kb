$fn=50;
height = 11.5;


module holes(extra_diameter=0) {
    cylinder(d=15.2+extra_diameter, h=height);
    for (x = [-11.1, +11.1])
    translate([x,0,0])
    cylinder(d=3.5+extra_diameter, h=height);
}

module spacer() {
    difference() {
      hull() holes(4);
      holes(0);
    }
}

spacer();
