use <bracket.scad>;

gutter = 5;

screw_hole_diameter = 3;
screw_hole_distance_from_top = 1.5 + screw_hole_diameter/2;
screw_hole_distance_from_side = 4.6 + 5/2;
plate_height = 129;
plate_width = 50.2;

slot_center_distance = 122.5;

difference() {
    translate([0, 0, (6.5+2)/2])
        cube([plate_width + 2*gutter,plate_height+2*gutter, 6.5+2], center=true);
    translate([0, 0, 6.5/2-0.01])
        linear_extrude(height=6.52, center=true)
            offset(r=1/16*25.4)
                routed_holes();
    
    for (x = [-1, 1]) {
        for (y = [-1, 1]) {
            translate([
              x*(plate_width/2 - screw_hole_distance_from_side),
              y*slot_center_distance/2,
              0
            ])
              cylinder(d=screw_hole_diameter, h=25, center=true, $fn=20);
        }
    }
 
    translate([0, 0, 6.5/2-0.01])
        linear_extrude(height=6.52, center=true)
            faceplate_holes();
    translate([0, 0, 6.5 +2/2])
        cube([plate_width, plate_height, 2.01], center=true);
}
