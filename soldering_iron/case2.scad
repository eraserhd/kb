
width = 4;
left_depth = 3.5;
right_depth = 2.8;

wood_base_thickness = 1/2;

upright_diameter = 5/8;
wood_base_corner_diameter = 1;

upright_positions = function(inset = 0)
  let (
    edge_distance = wood_base_corner_diameter/2
  ) [
    [edge_distance+inset, edge_distance+inset],
    [width-2*edge_distance-2*inset, edge_distance+inset],
    [width-2*edge_distance-2*inset, right_depth-2*edge_distance-2*inset],
    [edge_distance+inset, left_depth-2*edge_distance-2*inset]
  ];

module wood_base() {
    roundover_radius = wood_base_thickness/8;
    minkowski() {
        linear_extrude(wood_base_thickness - roundover_radius) {
            offset(r=wood_base_corner_diameter/2, $fn=20) {
                polygon(upright_positions(roundover_radius/2));
            }
        }
        sphere(d=roundover_radius*2);
    }
}

module upright() {
    cylinder(2, d=upright_diameter, $fn=20);
}

module uprights() {
    for (pos = upright_positions())
      translate(pos)
        upright();
}

wood_base();
translate([0,0,wood_base_thickness])
  uprights();
