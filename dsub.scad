// sc = scale, set larger if your part doesn't fit. default is the exact dimensions of the connector housing. recomended 1.1 for most mounting holes,
// sz = size, set to the correct size for your dsub. Common values are 17.04 for db9 or high density db15, 25.37 for standard db15, 39.09 for db25. 
//dp= depth, set to a size that can penetrate the panel you are using it with
module dsub(sz, dsub_clearance=0.85, screw_clearance=0.2) {
    module screw_hole() {
        cylinder(r=1.6+screw_clearance, h=10);
    }

    $fn=64;

    cs=(sz/2)-2.6;
    cs2=(sz/2)-3.6;
    ns=(sz/2)+4.04;
    translate([0,-ns,0]) screw_hole();
    translate([0,ns,0]) screw_hole();

    hull() {
        translate([-1.66, -cs, 0]) cylinder(r=2.6+dsub_clearance, h=10);
        translate([-1.66, cs,  0]) cylinder(r=2.6+dsub_clearance, h=10);
        translate([+1.66, -cs2,0]) cylinder(r=2.6+dsub_clearance, h=10);
        translate([+1.66, cs2, 0]) cylinder(r=2.6+dsub_clearance, h=10);
    }
}

module dsub_2(sz, dsub_clearance=0.85, screw_clearance=0.2) {
    module screw_hole() {
        circle(r=1.6+screw_clearance);
    }

    $fn=64;

    cs=(sz/2)-2.6;
    cs2=(sz/2)-3.6;
    ns=(sz/2)+4.04;
    translate([0,-ns]) screw_hole();
    translate([0,ns]) screw_hole();

    hull() {
        translate([-1.66, -cs]) circle(r=2.6+dsub_clearance);
        translate([-1.66, cs]) circle(r=2.6+dsub_clearance);
        translate([+1.66, -cs2]) circle(r=2.6+dsub_clearance);
        translate([+1.66, cs2]) circle(r=2.6+dsub_clearance);
    }
}

module db9() {
    dsub(17.04);
}
module db15(depth) {
    dsub(25.37);
}
