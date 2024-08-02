width = 5;
left_depth = 4.25;
right_depth = 3.5;
height = 6.5;
top_height = 3/4;

wood_base_thickness = 3/4;

upright_diameter = 5/8;
wood_base_corner_diameter = 1;
wood_color = "brown";

upright_cap_height = 3/16;
upright_cap_diameter = 0.866; 

top_form_thickness = 3/4;
top_form_corner_diameter = 3/4;
top_form_top_radius = 1/4;
top_form_fancy_inset = 1/64;

transformer_dimensions = [2.61, 2.34, 2.68];
transformer_position = [
    -(transformer_dimensions.x/2),
    wood_base_corner_diameter,
    wood_base_thickness + 0.25
];

upright_positions =
  let (
    edge_distance = wood_base_corner_diameter/2
  ) [
    [-width/2 + edge_distance, edge_distance],
    [ width/2 - edge_distance, edge_distance],
    [ width/2 - edge_distance, right_depth - edge_distance],
    [ 0,                       left_depth - edge_distance],
    [-width/2 + edge_distance, right_depth - edge_distance]
  ];
