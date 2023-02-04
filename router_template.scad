use <bracket.scad>;

gutter = 5;

difference() {
    translate([0, 0, (6.5+2)/2])
        cube([50.8 + 2*gutter,128.5+2*gutter, 6.5+2], center=true);
    translate([0, 0, 6.5/2-0.01])
        linear_extrude(height=6.52, center=true)
            offset(r=1/16*25.4)
                faceplate_holes();
    translate([0, 0, 6.5 +2/2])
        cube([50.8, 128.5, 2.01], center=true);
}
