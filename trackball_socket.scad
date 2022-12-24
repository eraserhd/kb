module add_trackball_socket(
    position,
    trackball_diameter = 34,
    trackball_clearance = 1,
    wall_thickness = 3,
    wall_height = 5,
    bearing_diameter = 6,
    bearing_width = 2.5,
    bearing_shaft_diameter = 3,
    bearing_shaft_length = 6,
    heat_set_insert_diameter = 2.25
) {
    bearing_clearing_width = bearing_width + 1;
    bearing_housing_width = bearing_clearing_width + 2;
    bearing_housing_diameter = bearing_diameter + 4;
    shaft_clearing_length = bearing_shaft_length + 0.5;
    shaft_housing_width = bearing_shaft_length + 2;
    shaft_housing_diameter = bearing_shaft_diameter + 4;
    
    // Per PWM3389 specs and seller:
    // https://www.tindie.com/products/jkicklighter/pmw3389-motion-sensor/#specs
    sensor_distance = 2.1;
    sensor_screw_distance = 24;
    sensor_screw_hole_diameter = 2.44; // fits 2-56 screw
    sensor_width = 21;
    sensor_length = 28;
    sensor_height = 9;

    // Measured with micrometers:
    sensor_lens_width = 19;
    sensor_lens_length = 21.5;
    sensor_lens_corner_radius = 6.5;
    sensor_lens_height_over_board = 3.5;

    bearing_z_offset = -6.5;

    socket_outside_diameter = 2*wall_thickness + 2*trackball_clearance + trackball_diameter;
    socket_inside_diameter = 2*trackball_clearance + trackball_diameter;

    module housing_part(diameter, width) {
        cylinder(d=diameter, h=width, center=true, $fn=25);
        translate([0, diameter/2, 0])
            cube([diameter, diameter, width], center=true);
        rotate([0, 0, 45])
            translate([0, diameter/2, 0])
                cube([diameter, diameter, width], center=true);
    }

    module bearing_housing() {
        rotate([0, 90, 0])
            housing_part(diameter=bearing_housing_diameter, width=shaft_housing_width);
    }

    module bearing_cutout() {
        rotate([0, 90, 0]) {
            cylinder(d=bearing_shaft_diameter, h=shaft_clearing_length, center=true, $fn=25);
            rotate([0, 0, 45])
                translate([0, socket_inside_diameter/8, 0])
                   cube([bearing_shaft_diameter, socket_inside_diameter/4, bearing_shaft_length], center=true);
            housing_part(diameter=8.5, width=bearing_clearing_width);
        }
    }

    module trackball_cutout() {
        sphere(d=socket_inside_diameter);
        translate([0, 0, wall_height/2])
            cylinder(d=socket_inside_diameter, h=wall_height+0.01, center=true);
    }

    module trackball_housing() {
        difference() {
            sphere(d=socket_outside_diameter);
            translate([0,0,50]) cube([100,100,100],center=true);
        }
        translate([0, 0, wall_height/2])
            cylinder(d=socket_outside_diameter, h=wall_height, center=true);
    }

    module place_bearings() {
        bearing_distance_from_ball_center = bearing_diameter/2 + trackball_diameter/2;
        bearing_y_offset = -sqrt(pow(bearing_distance_from_ball_center, 2)+pow(bearing_z_offset, 2));
        bearing_offset = [0, bearing_y_offset, bearing_z_offset];

        translate(bearing_offset) children();
        rotate([0, 0, 120]) translate(bearing_offset) children();
        rotate([0, 0, 240]) translate(bearing_offset) children();
    }

    module sensor_bracket() {
        thickness = sensor_lens_height_over_board + 4;
        dist = -trackball_diameter/2 - sensor_distance + thickness/2;
        translate([0, 0, dist])
            cube([sensor_width, sensor_length, thickness], center=true);
    }

    module sensor_bracket_cutout() {
        cutout_width = sensor_lens_width + 1;
        cutout_length = sensor_lens_length + 0.5;
        corner_radius = sensor_lens_corner_radius - 1;
        cutout_height = trackball_diameter/2 + sensor_distance + sensor_lens_height_over_board + 1;

        module corner() {
            translate([0, 0, -cutout_height/2])
                cylinder(r=corner_radius, h=cutout_height, center=true);
        }

        module corners() {
            x_delta = cutout_width/2 - corner_radius;
            y_delta = cutout_length/2 - corner_radius;
            for (x_dir = [-1,1], y_dir = [-1,1])
                translate([x_dir * x_delta, y_dir * y_delta, 0]) corner();
        }

        module sides() {
            translate([0, 0, -cutout_height/2]) {
                cube([cutout_width, cutout_length - 2*corner_radius, cutout_height], center=true);
                cube([cutout_width - 2*corner_radius, cutout_length, cutout_height], center=true);
            }
        }

        corners();
        sides();
    }

    module heat_set_insert_housing() {
        height = sensor_lens_height_over_board + 2;
        dist = -trackball_diameter/2 - sensor_distance + height/2;
        translate([0, 0, dist]) {
            cylinder(d=7, h=height, center=true);
            cylinder(d=sensor_screw_hole_diameter - 0.25, h=height+1.64, center=true, $fn=8);
        }
    }

    difference() {
        union() {
            children();
            translate(position) {
                trackball_housing();
                place_bearings() bearing_housing();
                sensor_bracket();
                translate([0, sensor_screw_distance/2, 0]) heat_set_insert_housing();
                translate([0, -sensor_screw_distance/2, 0]) heat_set_insert_housing();
            }
        }
        translate(position) {
            trackball_cutout();
            place_bearings() bearing_cutout();
            sensor_bracket_cutout();
        }
    }
}

add_trackball_socket([0,0,0])
    union() {
        translate([0,0,-1.5])
            cube([55,55,3],center=true);
        translate([-3/2 - 55/2,0,-30/2])
            cube([3,55,30],center=true);
        translate([+3/2 + 55/2,0,-30/2])
            cube([3,55,30],center=true);
        translate([0,-3/2 - 55/2,-30/2])
            cube([55+6,3,30],center=true);
    }
