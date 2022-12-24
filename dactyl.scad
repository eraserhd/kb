// Number of non-thumb rows
Rows = 3;
// Number of non-thumb columns
Columns = 6;
// Remove this many keys from the inside of the bottom row
reduced_inner_cols = 0;
// Remove this many kkeys from the outside of the bottom row
reduced_outer_cols = 0;

alpha = 0.26179916666666664;
beta = 0.08726638888888888;
// Column which is considered the middle for curvature purposes
centercol = 3;
// Row, counting from the bottom, considered the middle for curvature purposes
centerrow_offset = 1;
// Additonal left-to-right angle of keys
tenting_angle = 0.42;
// if Rows > 5, this should warn that we want standard
column_style = "ORTHOGRAPHIC"; // [ORTHOGRAPHIC]
keyboard_z_offset = 20;
extra_width = 2.5;
extra_height = 1.0;
web_thickness = 5.1;
post_size = 0.1;
post_adj = 0;

sa_profile_key_height = 12.7;
sa_length = 18.5;

column_offsets = [
    [ 0, 0, 0 ],
    [ 0, 0, 0 ],
    [ 0, 2.82, -4.5 ],
    [ 0, 0, 0 ],
    [ 0, -6, 5 ],
    [ 0, -6, 5 ],
    [ 0, -6, 5 ]
];

wall_z_offset = 15;
wall_x_offset = 5;
wall_y_offset = 6;

wall_thickness = 4.5;
wall_base_y_thickness = 4.5;
wall_base_x_thickness = 4.5;
wall_base_back_thickness = 4.5;

/* [Keywells] */

// How keyswitches are mounted.
plate_style = "NOTCH"; // [HOLE, NUB, HS_NUB, UNDERCUT, HS_UNDERCUT, NOTCH, HS_NOTCH]

plate_thickness = 5.1;
plate_rim = 2.0;
plate_holes = true;
plate_holes_xy_offset = [ 0.0, 0.0 ];
plate_holes_width = 14.3;
plate_holes_height = 14.3;
plate_holes_diameter = 1.6;
plate_holes_depth = 20.0;

hole_keyswitch_height = 14.0;
hole_keyswitch_width = 14.0;
nub_keyswitch_height = 14.4;
nub_keyswitch_width = 14.4;
undercut_keyswitch_height = 14.0;
undercut_keyswitch_width = 14.0;
notch_width = 6.0;

clip_thickness = 1.1;
clip_undercut = 1.0;

/* [Thumb Cluster] */

thumb_style = "TRACKBALL_CJ"; // [TRACKBALL_CJ]
thumb_plate_tr_rotation = 0.0;
thumb_plate_tl_rotation = 0.0;
thumb_plate_mr_rotation = 0.0;
thumb_plate_ml_rotation = 0.0;
thumb_plate_br_rotation = 0.0;
thumb_plate_bl_rotation = 0.0;
tbcj_inner_diameter = 42;
tbcj_thickness = 2;
tbcj_outer_diameter = 53;

/* [Bottom Plate Screws] */

// Position of screw inserts, relative to the case walls.
screw_offset_type = "INTERIOR"; // [INTERIOR, EXTERIOR, ORIGINAL]

screw_insert_height = 3.8;
screw_insert_outer_radius = 4.25;

/* [Display] */

oled_mount_type = "CLIP"; // [UNDERCUT, SLIDING, CLIP]
oled_center_row = 1.25;
oled_translation_offset = [0, 0, 4];
oled_rotation_offset = [0, 0, 0];

/* [Controller Mounting] */

controller_mount_type = "EXTERNAL"; // [EXTERNAL]
external_holder_height = 12.5;
external_holder_width = 28.75;
external_holder_xoffset = -5.0;
external_holder_yoffset = -4.5;

// =========================================================================================================

use <trackball_socket.scad>;

function deg2rad(d) = d*PI/180;
function rad2deg(r) = r*180/PI;

function translate_matrix(pos) =
  [[1, 0, 0, pos.x],
   [0, 1, 0, pos.y],
   [0, 0, 1, pos.z],
   [0, 0, 0, 1    ]];
function rotate_x_matrix(rad) =
  let(deg = rad2deg(-rad))
  [[1,         0,        0, 0],
   [0,  cos(deg), sin(deg), 0],
   [0, -sin(deg), cos(deg), 0],
   [0,         0,        0, 1]];
function rotate_y_matrix(rad) =
  let(deg = rad2deg(-rad))
  [[cos(deg), 0, -sin(deg), 0],
   [       0, 1,         0, 0],
   [sin(deg), 0,  cos(deg), 0],
   [       0, 0,         0, 1]];
function rotate_z_matrix(rad) =
  let(deg = rad2deg(rad))
  [[cos(deg), -sin(deg), 0, 0],
   [sin(deg), cos(deg),  0, 0],
   [       0, 0,         1, 0],
   [       0, 0,         0, 1]];
function rotate_matrix(ang) =
   rotate_z_matrix(ang.z) *
   rotate_y_matrix(ang.y) *
   rotate_x_matrix(ang.x);
function matrix_transform(matrix, pos) =
  let (result = matrix * [pos.x, pos.y, pos.z, 1])
  [result.x, result.y, result.z];

// Hopefully, we can get rid of this after we get rid of a lot of the hulls.
module triangle_hulls() {
  for (i = [0 : $children-3]) {
    hull() {
      children(i);
      children(i+1);
      children(i+2);
    }
  }
}

plate_styles = [
  ["HOLE",        hole_keyswitch_height,     hole_keyswitch_width],
  ["NUB",         nub_keyswitch_height,      nub_keyswitch_width],
  ["HS_NUB",      nub_keyswitch_height,      nub_keyswitch_width],
  ["UNDERCUT",    undercut_keyswitch_height, undercut_keyswitch_width],
  ["HS_UNDERCUT", undercut_keyswitch_height, undercut_keyswitch_width],
  ["NOTCH",       undercut_keyswitch_height, undercut_keyswitch_width],
  ["HS_NOTCH",    undercut_keyswitch_height, undercut_keyswitch_width]
];

function lookup(table, key, column=false) =
  let (
    matching_rows = [for (i = [0 : len(table)]) if (table[i][0] == key) table[i]],
    a1 = assert(len(matching_rows) > 0, str("Invalid key ", key, " for table.")),
    a2 = assert(len(matching_rows) < 2, "Table has multiple matching keys.")
  )
  (column == false) ? matching_rows[0] : matching_rows[0][column];

keyswitch_height = lookup(plate_styles, plate_style, 1);
keyswitch_width = lookup(plate_styles, plate_style, 2);

mount_width = keyswitch_width + 2 * plate_rim;
mount_height = keyswitch_height + 2 * plate_rim;
mount_thickness = plate_thickness;

oled_configurations = [
  ["CLIP",
   function(name)
     let (
       left_wall_x_offset = 24.0,

       fix_point = function(p) [p.x, p.y, p.z],
       base_pt1 = fix_point(key_placement_matrix(0, oled_center_row-1) * [-mount_width/2, mount_height/2, 0, 1]),
       base_pt2 = fix_point(key_placement_matrix(0, oled_center_row+1) * [-mount_width/2, mount_height/2, 0, 1]),
       base_pt0 = fix_point(key_placement_matrix(0, oled_center_row)   * [-mount_width/2, mount_height/2, 0, 1]),

       mount_location_part = (base_pt1 + base_pt2)/2 + [-left_wall_x_offset/2, 0, 0] + oled_translation_offset,
       mount_location_xyz = [mount_location_part.x, mount_location_part.y, (mount_location_part.z + base_pt0[2])/2],

       angle_x = atan2(base_pt1[2] - base_pt2[2], base_pt1[1] - base_pt2[1]),
       angle_z = atan2(base_pt1[0] - base_pt2[0], base_pt1[1] - base_pt2[1]),
       mount_rotation_xyz = [angle_x, 0, -angle_z] + oled_rotation_offset
     )
     name == "mount_width" ? 12.5 :
     name == "mount_height" ? 39.0 :
     name == "mount_rim" ? 2.0 :
     name == "mount_depth" ? 7.0 :
     name == "mount_cut_depth" ? 20.0 :
     name == "mount_location_xyz" ? mount_location_xyz : //[ -78.0, 20.0, 42.0 ]
     name == "mount_rotation_xyz" ? mount_rotation_xyz : //[ 12.0, 0.0, -6.0 ] :
     name == "left_wall_x_offset" ? left_wall_x_offset :
     name == "left_wall_z_offset" ? 0.0 :
     name == "left_wall_lower_y_offset" ? 12.0 :
     name == "left_wall_lower_z_offset" ? 5.0 :
     name == "thickness" ? 4.2 :
     name == "mount_bezel_thickness" ? 3.5 :
     name == "mount_bezel_chamfer" ? 2.0 :
     name == "mount_connector_hole" ? 6.0 :
     name == "screen_start_from_conn_end" ? 6.5 :
     name == "screen_length" ? 24.5 :
     name == "screen_width" ? 10.5 :
     name == "clip_thickness" ? 1.5 :
     name == "clip_width" ? 6.0 :
     name == "clip_overhang" ? 1.0 :
     name == "clip_extension" ? 5.0 :
     name == "clip_width_clearance" ? 0.5 :
     name == "clip_undercut" ? 0.5 :
     name == "clip_undercut_thickness" ? 2.5 :
     name == "clip_y_gap" ? 0.2 :
     name == "clip_z_gap" ? 0.2 :
     assert(false, str("Unknown name ", name))]
];

oled = lookup(oled_configurations, oled_mount_type, 1);

centerrow = Rows - centerrow_offset;
lastrow = Rows - 1;
cornerrow = (reduced_outer_cols>0 || reduced_inner_cols>0) ? lastrow - 1 : lastrow;
lastcol = Columns - 1;

cap_top_height = plate_thickness + sa_profile_key_height;
row_radius = ((mount_height + extra_height) / 2) / (sin(rad2deg(alpha / 2))) + cap_top_height;

column_radius = ((mount_width + extra_width) / 2) / sin(rad2deg(beta / 2)) + cap_top_height;
column_x_delta = -1 - column_radius * sin(rad2deg(beta));
column_base_angle = beta * (centercol - 2);

function key_placement_matrix(column, row, column_style=column_style) =
    let (
      column_styles = [
        ["ORTHOGRAPHIC",
         function(column, row)
           let(
               column_angle = beta * (centercol - column),
               column_z_delta = column_radius * (1 - cos(rad2deg(column_angle)))
           )
           translate_matrix([0, 0, keyboard_z_offset]) *
           rotate_y_matrix(tenting_angle) *
           translate_matrix(column_offsets[column]) *
           translate_matrix([-(column - centercol) * column_x_delta, 0, column_z_delta]) *
           rotate_y_matrix(column_angle) *
           translate_matrix([0, 0, row_radius]) *
           rotate_x_matrix(alpha * (centerrow - row)) *
           translate_matrix([0, 0, -row_radius])
         ]
      ],
      placement_fn = lookup(column_styles, column_style, 1)
    )
    placement_fn(column, row);

function inner_wall_placement_matrix(row, direction) =
    let (
      pos = matrix_transform(key_placement_matrix(0, row), [-mount_width * 0.5, direction * mount_height * 0.5, 0]),
      oled_adjust = [-oled("left_wall_x_offset"), 0, -oled("left_wall_z_offset")],
      low_corner_offset = [0, oled("left_wall_lower_y_offset"), -oled("left_wall_lower_z_offset")],
      low_corner_adjust = row == cornerrow && direction <= 0 ? low_corner_offset : [0, 0, 0]
    )
    translate_matrix([ pos.x, pos.y, pos.z ] + oled_adjust + low_corner_adjust);

module key_place(column, row) {
    multmatrix(key_placement_matrix(column, row, column_style)) children();
}

// == key holes / top face ==

module single_plate() {
  if (plate_style == "NUB" || plate_style == "HS_NUB") {
    assert(false, "Missing code for nub plate_style.");
  }
  difference() {
    translate([0, 0, mount_thickness/2])
      cube([mount_width, mount_height, mount_thickness], center=true);
    translate([0, 0, mount_thickness-0.01])
      cube([keyswitch_width, keyswitch_height, mount_thickness*2 + 0.02], center=true);
    if (plate_style == "NOTCH" || plate_style == "HS_NOTCH") {
      translate([0, 0, -clip_thickness + mount_thickness/2]) {
        cube([notch_width, keyswitch_height + 2*clip_undercut, mount_thickness], center=true);
        cube([keyswitch_width + 2*clip_undercut, notch_width, mount_thickness], center=true);
      }
    } else {
      assert(false, "not implemented");
    }
    if (plate_holes) {
      for (delta = [[1,1], [-1,1], [-1,-1], [1,-1]]) {
        translate([
          plate_holes_xy_offset[0] + delta[0]*(plate_holes_width/2),
          plate_holes_xy_offset[1] + delta[1]*(plate_holes_height/2),
          plate_holes_depth/2-0.01
        ])
          cylinder(d=plate_holes_diameter, h=plate_holes_depth+0.01, center=true);
      }
    }
  }
}

module key_holes() {
  for (column = [0 : Columns-1], row = [0 : Rows-1]) {
    if ((reduced_inner_cols <= column && column < (Columns - reduced_outer_cols)) || row != lastrow) {
      key_place(column, row) single_plate();
    }
  }
}

module connectors() {
  // front-to-back gaps between plates
  for (column = [0 : Columns-2]) {
    iterrows = (reduced_inner_cols <= column && column < (Columns - reduced_outer_cols-1)) ? lastrow+1 : lastrow;
    for (row = [0 : iterrows-1]) {
      triangle_hulls() {
        key_place(column + 1, row) web_post_tl();
        key_place(column, row) web_post_tr();
        key_place(column + 1, row) web_post_bl();
        key_place(column, row) web_post_br();
      }
    }
  }

  // left-to-right gaps between plates
  for (column = [0 : Columns-1]) {
    iterrows = (reduced_inner_cols <= column && column < (Columns - reduced_outer_cols)) ? lastrow : cornerrow;
    for (row = [0 : iterrows - 1]) {
      triangle_hulls() {
        key_place(column, row) web_post_bl();
        key_place(column, row) web_post_br();
        key_place(column, row + 1) web_post_tl();
        key_place(column, row + 1) web_post_tr();
      }
    }
  }

  // square gaps joining corners of four adjacent plates
  for (column = [0 : Columns-2]) {
    iterrows = (reduced_inner_cols <= column && column < (Columns - reduced_outer_cols-1)) ? lastrow : cornerrow;
    for (row = [0 : iterrows - 1]) {
      triangle_hulls() {
        key_place(column, row) web_post_br();
        key_place(column, row + 1) web_post_tr();
        key_place(column + 1, row) web_post_bl();
        key_place(column + 1, row + 1) web_post_tl();
      }
    }
    if (column == reduced_inner_cols-1) {
      triangle_hulls() {
        key_place(column + 1, iterrows) web_post_bl();
        key_place(column, iterrows) web_post_br();
        key_place(column + 1, iterrows + 1) web_post_tl();
        key_place(column + 1, iterrows + 1) web_post_bl();
      }
    }
    if (column == (Columns - reduced_outer_cols - 1)) {
      triangle_hulls() {
        key_place(column, iterrows) web_post_br();
        key_place(column + 1, iterrows) web_post_bl();
        key_place(column, iterrows + 1) web_post_tr();
        key_place(column, iterrows + 1) web_post_br();
      }
    }
  }
}

module add_key_holes() {
  children();
  key_holes();
  connectors();
}

// == case walls ==

module web_post() {
    translate([0, 0, plate_thickness - (web_thickness / 2)])
        cube([post_size, post_size, web_thickness], center=true);
}

module web_post_tr() {
    translate([(mount_width / 2) - post_adj, (mount_height / 2) - post_adj, 0])
        web_post();
}

module web_post_tl() {
    translate([-(mount_width / 2) - post_adj, (mount_height / 2) - post_adj, 0])
        web_post();
}

module web_post_bl() {
    translate([-(mount_width / 2) - post_adj, -(mount_height / 2) - post_adj, 0])
        web_post();
}

module web_post_br() {
    translate([(mount_width / 2) - post_adj, -(mount_height / 2) - post_adj, 0])
        web_post();
}

module bottom_hull(height = 0.001) {
    hull() {
      translate([0, 0, height/2 - 10])
        linear_extrude(height=height, twist=0, convexity=0, center=true)
        projection(cut = false)
        children();
      children();
    }
}

function wall_locate1(dx, dy) = [dx * wall_thickness, dy * wall_thickness, -1];
function wall_locate2(dx, dy) = [dx * wall_x_offset, dy * wall_y_offset, -wall_z_offset];
function wall_locate3(dx, dy, back) = back ?
  [
    dx * (wall_x_offset + wall_base_x_thickness),
    dy * (wall_y_offset + wall_base_back_thickness),
    -wall_z_offset
  ] : [
    dx * (wall_x_offset + wall_base_x_thickness),
    dy * (wall_y_offset + wall_base_y_thickness),
    -wall_z_offset
  ];

module wall_brace(place1, dx1, dy1, place2, dx2, dy2, back=false) {
  hull() {
    multmatrix(place1) children(0);
    multmatrix(place1) translate(wall_locate1(dx1, dy1)) children(0);
    multmatrix(place1) translate(wall_locate2(dx1, dy1)) children(0);
    multmatrix(place1) translate(wall_locate3(dx1, dy1, back)) children(0);
    multmatrix(place2) children(1);
    multmatrix(place2) translate(wall_locate1(dx2, dy2)) children(1);
    multmatrix(place2) translate(wall_locate2(dx2, dy2)) children(1);
    multmatrix(place2) translate(wall_locate3(dx2, dy2, back)) children(1);
  }
  bottom_hull() {
    multmatrix(place1) translate(wall_locate2(dx1, dy1)) children(0);
    multmatrix(place1) translate(wall_locate3(dx1, dy1, back)) children(0);
    multmatrix(place2) translate(wall_locate2(dx2, dy2)) children(1);
    multmatrix(place2) translate(wall_locate3(dx2, dy2, back)) children(1);
  }
}

module key_wall_brace(x1, y1, dx1, dy1, x2, y2, dx2, dy2, back=false) {
  place1 = key_placement_matrix(x1, y1);
  place2 = key_placement_matrix(x2, y2);
  wall_brace(place1, dx1, dy1, place2, dx2, dy2, back=back) {
    children(0);
    children(1);
  }
}

module back_wall() {
  x = 0;
  key_wall_brace(x, 0, 0, 1, x, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
  for (x = [1 : Columns - 1]) {
    key_wall_brace(x, 0, 0, 1, x, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
    key_wall_brace(x, 0, 0, 1, x - 1, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
  }
  key_wall_brace(lastcol, 0, 0, 1, lastcol, 0, 1, 0, back=true) { web_post_tr(); web_post_tr(); }
  key_wall_brace(lastcol, 0, 0, 1, lastcol, 0, 1, 0) { web_post_tr(); web_post_tr(); }
}

module outer_wall() { // was right_wall
  y = 0;
  corner = reduced_outer_cols > 0 ? cornerrow : lastrow;
  key_wall_brace(lastcol, y, 1, 0, lastcol, y, 1, 0) { web_post_tr(); web_post_br(); }
  for (y = [1 : corner]) {
    key_wall_brace(lastcol, y - 1, 1, 0, lastcol, y, 1, 0) { web_post_br(); web_post_tr(); }
    key_wall_brace(lastcol, y, 1, 0, lastcol, y, 1, 0) { web_post_tr(); web_post_br(); }
  }
  key_wall_brace(lastcol, corner, 0, -1, lastcol, corner, 1, 0) { web_post_br(); web_post_br(); }
}

module inner_wall() { // was left_wall
  wall_brace(
    key_placement_matrix(0, 0), 0, 1,
    inner_wall_placement_matrix(0, 1), 0, 1
  ) {
    web_post_tl();
    web_post();
  }
  wall_brace(
    inner_wall_placement_matrix(0, 1), 0, 1,
    inner_wall_placement_matrix(0, 1), -1, 0
  ) {
    web_post();
    web_post();
  }
  corner = reduced_inner_cols > 0 ? cornerrow : lastrow;
  for (y = [0 : corner]) {
    wall_brace(
      inner_wall_placement_matrix(y, 1), -1, 0,
      inner_wall_placement_matrix(y, -1), -1, 0
    ) {
      web_post();
      web_post();
    }
    hull() {
      key_place(0, y) web_post_tl();
      key_place(0, y) web_post_bl();
      multmatrix(inner_wall_placement_matrix(y, 1)) web_post();
      multmatrix(inner_wall_placement_matrix(y, -1)) web_post();
    }
  }
  for (y = [1 : corner]) {
    wall_brace(
      inner_wall_placement_matrix(y - 1, -1), -1, 0,
      inner_wall_placement_matrix(y, 1), -1, 0
    ) {
      web_post();
      web_post();
    }
    hull() {
      key_place(0, y) web_post_tl();
      key_place(0, y-1) web_post_bl();
      multmatrix(inner_wall_placement_matrix(y, 1)) web_post();
      multmatrix(inner_wall_placement_matrix(y-1, -1)) web_post();
    }
  }
}

module front_wall() {
  corner = cornerrow;
  offset_col = reduced_outer_cols > 0 ? Columns - reduced_outer_cols : 99;

  for (x = [3 : Columns - 1]) {
    if (x < (offset_col - 1)) {
      if (x > 3) {
        key_wall_brace(x-1, lastrow, 0, -1, x, lastrow, 0, -1) { web_post_br(); web_post_bl(); }
      }
      key_wall_brace(x, lastrow, 0, -1, x, lastrow, 0, -1) { web_post_bl(); web_post_br(); }
    } else if (x < offset_col) {
      if (x > 3) {
        key_wall_brace(x-1, lastrow, 0, -1, x, lastrow, 0, -1) { web_post_br(); web_post_bl(); }
      }
      key_wall_brace(x, lastrow, 0, -1, x, lastrow, 0.5, -1) { web_post_bl(); web_post_br(); }
    } else if (x == offset_col) {
      wall_bace(x - 1, lastrow, 0.5, -1, x, cornerrow, .5, -1) { web_post_br(); web_post_bl(); }
      key_wall_brace(x, cornerrow, .5, -1, x, cornerrow, 0, -1) { web_post_bl(); web_post_br(); }
    } else if (x == (offset_col + 1)) {
      key_wall_brace(x, cornerrow, 0, -1, x - 1, cornerrow, 0, -1) { web_post_bl(); web_post_br(); }
      key_wall_brace(x, cornerrow, 0, -1, x, cornerrow, 0, -1) { web_post_bl();  web_post_br(); }
    } else {
      key_wall_brace(x, cornerrow, 0, -1, x - 1, corner, 0, -1) { web_post_bl(); web_post_br(); }
      key_wall_brace(x, cornerrow, 0, -1, x, corner, 0, -1) { web_post_bl(); web_post_br(); }
    }
  }
}

module case_walls() {
  back_wall();
  inner_wall();
  outer_wall();
  front_wall();
}

// == thumb cluster ==

module add_thumb_cluster() {
  corner = reduced_inner_cols > 0 ? cornerrow : lastrow;
  origin = let (pos = key_placement_matrix(1, corner) * [mount_width/2, -mount_height/2, 0, 1]) [pos.x, pos.y, pos.z];
  ball_origin = [-15, -60, -12] + origin;

  // Matrices for the four thumb keys, inside to outside
  thumb_keys = [
    translate_matrix([-56.3, -43.3, -23.5] + origin) * rotate_matrix([deg2rad(-4), deg2rad(-35), deg2rad(52)]),
    translate_matrix([-51, -25, -12] + origin) * rotate_matrix([deg2rad(6), deg2rad(-34), deg2rad(40)]),
    translate_matrix([-32.5, -14.5, -2.5] + origin) * rotate_matrix([deg2rad(7.5), deg2rad(-18), deg2rad(10)]),
    translate_matrix([-12, -16, 3] + origin) * rotate_matrix([deg2rad(10), deg2rad(-15), deg2rad(10)])
  ];
  module place_thumbkey(i) {
    multmatrix(thumb_keys[i]) children();
  }

  module tbcj_thumb_layout() {
    place_thumbkey(3) rotate([0, 0, thumb_plate_tr_rotation]) children();
    place_thumbkey(2) rotate([0, 0, thumb_plate_tl_rotation]) children();
    place_thumbkey(1) rotate([0, 0, thumb_plate_ml_rotation]) children();
    place_thumbkey(0) rotate([0, 0, thumb_plate_bl_rotation]) children();
  }
  module oct_corner(i, diameter) {
    r = diameter / 2;
    j = (i+1)%8;
    m = r * tan(22.5);
    x = [ m,  r,  r,  m, -m, -r, -r, -m];
    y = [ r,  m, -m, -r, -r, -m,  m,  r];
    translate([x[j], y[j], 0]) children();
  }
  module tbcj_edge_post(i) {
    oct_corner(i, tbcj_outer_diameter)
      cube([post_size, post_size, tbcj_thickness], center=true);
  }
  module tbcj_holder() {
    for (i = [0 : 7]) {
      hull() {
        cube([post_size, post_size, tbcj_thickness], center=true);
        tbcj_edge_post(i);
        tbcj_edge_post(i+1);
      }
    }
  }
  // Most of top face, between keyswitch pads
  module tbcj_connectors() {
    triangle_hulls() {
      place_thumbkey(2) web_post_tr();
      place_thumbkey(2) web_post_br();
      place_thumbkey(3) web_post_tl();
      place_thumbkey(3) web_post_bl();
    }
    triangle_hulls() {
      place_thumbkey(0) web_post_tr();
      place_thumbkey(0) web_post_br();
      place_thumbkey(1) web_post_tl();
      place_thumbkey(1) web_post_bl();
    }
    triangle_hulls() {
      place_thumbkey(2) web_post_tl();
      place_thumbkey(1) web_post_tr();
      place_thumbkey(2) web_post_bl();
      place_thumbkey(1) web_post_br();
      place_thumbkey(2) web_post_br();
      place_thumbkey(3) web_post_bl();
      place_thumbkey(3) web_post_br();
    }
    triangle_hulls() {
      place_thumbkey(2) web_post_tl();
      key_place(0, cornerrow) web_post_bl();
      place_thumbkey(2) web_post_tr();
      key_place(0, cornerrow) web_post_br();
      place_thumbkey(3) web_post_tl();
      key_place(1, cornerrow) web_post_bl();
      place_thumbkey(3) web_post_tr();
      key_place(1, cornerrow) web_post_br();
      key_place(2, lastrow) web_post_bl();
      place_thumbkey(3) web_post_tr();
      key_place(2, lastrow) web_post_bl();
      place_thumbkey(3) web_post_br();
      key_place(2, lastrow) web_post_br();
      key_place(3, lastrow) web_post_bl();
    }
    triangle_hulls() {
      tbcj_place() tbcj_edge_post(4);
      place_thumbkey(0) web_post_bl();
      tbcj_place() tbcj_edge_post(5);
      place_thumbkey(0) web_post_br();
      tbcj_place() tbcj_edge_post(6);
    }
    triangle_hulls() {
      place_thumbkey(0) web_post_br();
      tbcj_place() tbcj_edge_post(6);
      place_thumbkey(1) web_post_bl();
    }
    triangle_hulls() {
      place_thumbkey(1) web_post_bl();
      tbcj_place() tbcj_edge_post(6);
      place_thumbkey(1) web_post_br();
      place_thumbkey(3) web_post_bl();
    }
    triangle_hulls() {
      tbcj_place() tbcj_edge_post(6);
      place_thumbkey(3) web_post_bl();
      tbcj_place() tbcj_edge_post(7);
      place_thumbkey(3) web_post_br();
      tbcj_place() tbcj_edge_post(0);
      place_thumbkey(3) web_post_br();
      key_place(3, lastrow) web_post_bl();
    }
  }
  // inner wall connecting thumb cluster and main part
  module tbcj_connection() {
    bottom_hull() {
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate2(-1, 0)))
        web_post();
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate3(-1, 0)))
        web_post();
      place_thumbkey(1) translate(wall_locate2(-0.3, 1)) web_post_tr();
      place_thumbkey(1) translate(wall_locate3(-0.3, 1)) web_post_tr();
    }
    hull() {
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate2(-1, 0)))
        web_post();
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate3(-1, 0)))
        web_post();
      place_thumbkey(1) translate(wall_locate2(-0.3, 1)) web_post_tr();
      place_thumbkey(1) translate(wall_locate3(-0.3, 1)) web_post_tr();
      place_thumbkey(2) web_post_tl();
    }
    hull() {
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate1(-1, 0))) web_post();
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate2(-1, 0))) web_post();
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate3(-1, 0))) web_post();
      place_thumbkey(2) web_post_tl();
    }
    hull() {
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), [0,0,0]))web_post();
      translate(matrix_transform(inner_wall_placement_matrix(cornerrow, -1), wall_locate1(-1, 0))) web_post();
      key_place(0, cornerrow) web_post_bl();
      place_thumbkey(2) web_post_tl();
    }
    hull() {
      place_thumbkey(1) web_post_tr();
      place_thumbkey(1) translate(wall_locate1(-0.3, 1)) web_post_tr();
      place_thumbkey(1) translate(wall_locate2(-0.3, 1)) web_post_tr();
      place_thumbkey(1) translate(wall_locate3(-0.3, 1)) web_post_tr();
      place_thumbkey(2) web_post_tl();
    }
  }
  module tbcj_walls() {
    wall_brace(thumb_keys[1], -0.3, 1, thumb_keys[1], 0, 1) {
       web_post_tr();
       web_post_tl();
    }
    wall_brace(thumb_keys[0], 0, 1, thumb_keys[0], 0, 1) {
       web_post_tr();
       web_post_tl();
    }
    wall_brace(thumb_keys[0], -1, 0, thumb_keys[0], -1, 0) {
       web_post_tl();
       web_post_bl();
    }
    wall_brace(thumb_keys[0], -1, 0, thumb_keys[0], 0, 1) {
       web_post_tl();
       web_post_tl();
    }
    wall_brace(thumb_keys[1], 0, 1, thumb_keys[0], 0, 1) {
      web_post_tl();
      web_post_tr();
    }
    module make_walls(data) {
      for (i = [0 : $children-2]) {
        wall_brace(data[i][0], data[i][1], data[i][2], data[i+1][0], data[i+1][1], data[i+1][2]) {
          children(i);
          children(i+1);
        }
      }
    }
    
    make_walls([
      [thumb_keys[0], -1, 0],
      [translate_matrix(ball_origin), 0, -1],
      [translate_matrix(ball_origin), 0, -1],
      [translate_matrix(ball_origin), 0, -1],
      [translate_matrix(ball_origin), 1, -1],
      [translate_matrix(ball_origin), 1, 0],
      [key_placement_matrix(3, lastrow), 0, -1]
    ]) {
      web_post_bl();
      tbcj_edge_post(4);
      tbcj_edge_post(3);
      tbcj_edge_post(2);
      tbcj_edge_post(1);
      tbcj_edge_post(0);
      web_post_bl();
    }
  }

  module tbcj_place() {
    translate(ball_origin) children();
  }
  module tbcj_thumb() {
    tbcj_thumb_layout() single_plate();
    tbcj_place() tbcj_holder();
  }
  
  module thumb_shape() {
    assert(thumb_style == "TRACKBALL_CJ", "CJ trackball is the only one supported");
    tbcj_thumb();
    tbcj_connectors();
    tbcj_connection();
    tbcj_walls();
  }

  children();
  add_trackball_socket(ball_origin)
    thumb_shape();
}

// == screw inserts ==

all_screw_insert_positions =
  let (
    offsets = lookup([
      [
        "INTERIOR",
        wall_locate3(-1, 0) + [wall_base_x_thickness, 0, 0],
        wall_locate2(1, 0) + [mount_height/2 + -wall_base_x_thickness/2, 0, 0],
        wall_locate2(0, -1) - [0, (mount_height / 2) + -wall_base_y_thickness/2, 0],
        wall_locate2(0, 1) + [0, (mount_height / 2) + -wall_base_y_thickness/3, 0]
      ],
      [
        "EXTERIOR",
        wall_locate3(-1, 0),
        wall_locate2(1, 0) + [mount_height/2 + wall_base_x_thickness/2, 0, 0],
        wall_locate2(0, -1) - [0, (mount_height / 2) + wall_base_y_thickness*2/3, 0],
        wall_locate2(0, 1) + [0, (mount_height / 2) + wall_base_y_thickness*2/3, 0]
      ],
      [
        "ORIGINAL",
        wall_locate3(-1, 0),
        wall_locate2(1, 0) + [mount_height/2, 0, 0],
        wall_locate2(0, -1) - [0, mount_height / 2, 0],
        wall_locate2(0, 1) + [0, (mount_height / 2), 0]
      ]
    ], screw_offset_type),

    //FIXME: What's the actual height of the top of the plate, to set Z?
    screw_insert_z = 0,
    set_z = function(pos) [pos.x, pos.y, screw_insert_z],

    inner_wall_position = function(row)         set_z(inner_wall_placement_matrix(row, 0) * concat(offsets[1], [1])),
    outer_wall_position = function(column, row) set_z(key_placement_matrix(column, row) * concat(offsets[2], [1])),
    front_wall_position = function(column, row) set_z(key_placement_matrix(column, row) * concat(offsets[3], [1])),
    back_wall_position  = function(column, row) set_z(key_placement_matrix(column, row) * concat(offsets[4], [1]))
  ) [
    inner_wall_position(0),
    inner_wall_position(cornerrow),
    front_wall_position(3, lastrow),
    back_wall_position(3, 0),
    outer_wall_position(lastcol, 0),
    outer_wall_position(lastcol, cornerrow)
  ];

module screw_insert_outer() {
  cylinder(r = screw_insert_outer_radius, h = screw_insert_height + 1.5, center = true);
  translate([0, 0, screw_insert_height / 2]) sphere(r = screw_insert_outer_radius);
}

module screw_insert_outers() {
  for (i = [0 : len(all_screw_insert_positions)-1]) {
    translate(all_screw_insert_positions[i]) screw_insert_outer();
  }
}

module screw_insert_hole() {
  translate([0, 0, -1]) cylinder(r = 1.7, h = screw_insert_height + 1, center = true);
}

module screw_insert_holes() {
  for (i = [0 : len(all_screw_insert_positions)-1]) {
    translate(all_screw_insert_positions[i]) screw_insert_hole();
  }
}

module add_screw_inserts() {
  difference() {
    union() {
      children();
      screw_insert_outers();
    }
    screw_insert_holes();
  }
}

// == controller ==

module external_mount_hole() {
  external_start =
    [external_holder_width/2, 0, 0, 0] +
    (key_placement_matrix(0, 0) * concat((wall_locate3(0, 1) + [0, mount_height/2, 0]), [1]));

  translate([
    external_start.x + external_holder_xoffset,
    external_start.y + external_holder_yoffset,
    external_holder_height / 2 - .05
  ]) {
    cube([external_holder_width, 20.0, external_holder_height+0.1], center=true);
    translate([0, -5, 0])
      cube([external_holder_width+8, 10.0, external_holder_height+8+0.1], center=true);
  }
}

module add_controller() {
  if (controller_mount_type == "EXTERNAL") {
    difference() {
      children();
      external_mount_hole();
    }
  } else {
    assert(false, str("Unknown controller mount type ", controller_mount_type));
  }
}

// == OLED ==

module add_oled_clip_mount() {
  mount_ext_width = oled("mount_width") + 2 * oled("mount_rim");
  mount_ext_height = oled("mount_height") + 2 * oled("clip_thickness")
          + 2 * oled("clip_undercut") + 2 * oled("clip_overhang") + 2 * oled("mount_rim");
  
  module place_oled() {
    translate(oled("mount_location_xyz"))
      rotate(oled("mount_rotation_xyz"))
        children();
  }
  module hole() {
    place_oled() cube([mount_ext_width, mount_ext_height, oled("mount_cut_depth") + 0.01], center=true);
  }
  module clip_undercut() {
    translate([0, 0, oled("clip_undercut_thickness")])
      cube([
        oled("clip_width") + 2 * oled("clip_width_clearance"),
        oled("mount_height") + 2 * oled("clip_thickness") + 2 * oled("clip_overhang") + 2 * oled("clip_undercut"),
        oled("mount_depth") + 0.1
      ], center=true);
  }
  module plate() {
    translate([0, 0, -oled("thickness")/2])
      cube([
        oled("mount_width") + .1,
        oled("mount_height") - 2 * oled("mount_connector_hole"),
        oled("mount_depth") - oled("thickness")
      ], center=true);
  }
  module clip_slot() {
    cube([
      oled("clip_width") + 2 * oled("clip_width_clearance"),
      oled("mount_height") + 2 * oled("clip_thickness") + 2 * oled("clip_overhang"),
      oled("mount_depth") + .1
    ], center=true);
  }

  difference() {
    children();
    hole();
  }
  place_oled() {
    difference() {
      cube([
        mount_ext_width,
        mount_ext_height,
        oled("mount_depth")
      ], center=true);
      cube([
        oled("mount_width"),
        oled("mount_height"),
        oled("mount_depth") + 0.1
      ], center=true);
      clip_slot();
      clip_undercut();
    }
    plate();
  }
}

module add_oled() {
  add_oled_clip_mount() children();
  assert(oled_mount_type == "CLIP", "Only CLIP is supported currently.");
}

// == model ==

module cut_off_bottom() {
  difference() {
    children();
    translate([0, 0, -20]) cube([350, 350, 40], center = true);
  }
}

module model_side() {
  cut_off_bottom()
    add_thumb_cluster()
    add_controller()
    add_key_holes()
    add_oled()
    add_screw_inserts()
    case_walls();
}

model_side();
