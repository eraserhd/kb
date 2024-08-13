$fn = 35;

board_width = 80;
board_height = 70;
board_thickness = 1.65;
board_lift_height = 12;

boost_standoff_distance = 40;
boost_height = 37.22;
boost_width = 45.31;
boost_standoff_y_from_top = 14;
boost_board_hole_width = 53.25;
boost_board_hole_height = 40;

cutoff_for_brass_rings = 6;

module boost(pos) {
    module standoff() {
        cylinder(h=6, d=6.75);
    }
    module standoff_hole() {
        translate([0,0,-0.5])cylinder(h=7, d=3);
    }
    module at_standoffs() {
        translate(pos)
        translate([-boost_standoff_distance/2, boost_height/2 - boost_standoff_y_from_top, 0])
            children();
        translate(pos)
        translate([+boost_standoff_distance/2, boost_height/2 - boost_standoff_y_from_top, 0])
            children();
    }
    difference() {
        union() {
            children();
            at_standoffs() standoff();
        }
        at_standoffs() standoff_hole();
    }
}

module arm(width) {
    arm_thickness = 3;
    arm_extra_height = 3;

    rotate([0,-90,180])
    linear_extrude(width, center=true)
    polygon(points=[
        [ 0                                              , -arm_thickness/2   ],
        [ board_lift_height + arm_extra_height           , -arm_thickness/2   ],
        [ board_lift_height + arm_extra_height           , +arm_thickness/2   ],
        [ board_lift_height + board_thickness            , 0                  ],
        [ board_lift_height                              , 0                  ],
        [ board_lift_height                              , +arm_thickness/2/2 ],
        [ board_lift_height - (arm_thickness/2/2)*sin(45), +arm_thickness/2   ],
        [ 0                                              , +arm_thickness/2   ],
        [ 0                                              , 0                  ],
    ]);
}

module bracket2() {
    difference() {
        union() {
            boost([
                -board_width/2 + boost_board_hole_width/2,
                -board_height/2 + boost_board_hole_height/2,
                0
            ])
            translate([0,0,2/2]) cube([board_width, board_height, 2], center=true);
            translate([0,+board_height/2,0]) arm(width=board_width);
            
            translate([
                board_width/2 - 26/2 - cutoff_for_brass_rings/2,
                -board_height/2,
                0
            ])
            rotate([0,0,180])
            arm(width=26-cutoff_for_brass_rings);
        }
        
        translate([
            +cutoff_for_brass_rings/2-board_width/2-0.1,
            +cutoff_for_brass_rings/2-board_height/2-0.1,
            0
        ])
        cube(cutoff_for_brass_rings,center=true);
        translate([
            -cutoff_for_brass_rings/2+board_width/2+0.1,
            +cutoff_for_brass_rings/2-board_height/2-0.1,
            0
        ])
        cube(cutoff_for_brass_rings,center=true);
    }
}

bracket2();
