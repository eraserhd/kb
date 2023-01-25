
// preview[view:north east, tilt:top]

//%translate([12.5,-35,0])
//	rotate([0,0,90])
//	import("C:\\misc\\db25_cutout.stl");

/* [Cutout] */

// Type of cut out
dbType = "DB15"; //[DB09, VGA, DB15, DB25]

// Screw hole type
ScrewHoleType = "SLOT"; //[HOLE, SLOT, BigSlot]

// Cutout Heigth
CutoutHeight = 20; //[1:50]

/* [Options] */

// Genrate Cutout
GenerateDbCutout = "Yes"; //[Yes, No]

// Tiedown Support Pins. Normaly you will want to generate these seperate from the cutout.
GenerateSupportPins = "No"; //[Yes, No]

// Tie Down straps. Normaly you will generate these on there own.
GenerateTieDownSraps = "No"; //[Yes, No]

cutoutDB(dbType, ScrewHoleType, GenerateDbCutout, GenerateSupportPins);

/* [About] */
// This is meant to be a library for DB and DE connectors. If you have any sugestion feel free to send me a message.
About = ""; //[]





/* [Hidden] */

$fn=40;


//
// inType DB09,15,25,VGA
//
// inScrewHoleType HOLE, SLOT
//



/*
cutoutDB09vga("SLOT");
translate([15,0,0]) cutoutDB09vga("HOLE");

translate([30,0,0]) cutoutDB15("SLOT");
translate([45,0,0]) cutoutDB15("HOLE");

translate([60,0,0]) cutoutDB25("SLOT");
translate([75,0,0]) cutoutDB25("HOLE");

*/

if(GenerateTieDownSraps == "Yes"){
	holdDownStraps();
}
module cutoutDB(inType, inScrewHoleType, wGenerateDbCutout, wGenerateSupportPins){
	
	//wGenerateDbCutout = "" ? "Yes" : "No" ;
	//wGenerateSupportPins = "" ? "No" : "Yes" ;
	
	if(inType == "DB09" || inType == "VGA"){
		cutoutDB09vga(inScrewHoleType, wGenerateDbCutout, wGenerateSupportPins);
	} else if(inType == "DB15"){
		cutoutDB15(inScrewHoleType, wGenerateDbCutout, wGenerateSupportPins);
	} else if(inType == "DB25"){
		cutoutDB25(inScrewHoleType, wGenerateDbCutout, wGenerateSupportPins);
	}
}

module cutoutDB09vga(inScreewHoleType, wGenerateDbCutout, wGenerateSupportPins){
	holeWidth = 8.2;
	HoleHeight = 4;	
	cutoutDBx(holeWidth, HoleHeight, inScreewHoleType, wGenerateDbCutout, wGenerateSupportPins);
}
module cutoutDB15(inScreewHoleType, wGenerateDbCutout, wGenerateSupportPins){
	holeWidth = 16;
	HoleHeight = 4;	
	cutoutDBx(holeWidth, HoleHeight, inScreewHoleType, wGenerateDbCutout, wGenerateSupportPins);
}
module cutoutDB25(inScreewHoleType, wGenerateDbCutout, wGenerateSupportPins){
	holeWidth = 19.6;
	HoleHeight = 4;	
	cutoutDBx(holeWidth, HoleHeight, inScreewHoleType, wGenerateDbCutout, wGenerateSupportPins);
}
module cutoutDBx(inHoleWidth, inHoleHeight, inScreewHoleType, wGenerateDbCutout, wGenerateSupportPins){
	screwHoleWidth = inHoleWidth + 5;
	if(wGenerateDbCutout == "Yes"){
		hull(){
			translate([-inHoleHeight, inHoleWidth,  		0]) cylinder(h = CutoutHeight, d = 4, center = true); // upper right
			translate([-inHoleHeight, -inHoleWidth, 		0]) cylinder(h = CutoutHeight, d = 4, center = true); // upper left
			translate([inHoleHeight,  inHoleWidth  -.5, 0]) cylinder(h = CutoutHeight, d = 4, center = true); // lower right
			translate([inHoleHeight,  -inHoleWidth +.5, 0]) cylinder(h = CutoutHeight, d = 4, center = true); // lower left
		}
		holeDiamiter = 4;
		if(inScreewHoleType == "HOLE"){
			translate([0,  screwHoleWidth,0]) cylinder(h = CutoutHeight, d = holeDiamiter, center = true);
			translate([0, -screwHoleWidth,0]) cylinder(h = CutoutHeight, d = holeDiamiter, center = true);
		} else if(inScreewHoleType == "SLOT"){
			holeDiamiter = 4 ;
			hull(){
				translate([0,  screwHoleWidth,0]) cylinder(h = CutoutHeight, d = holeDiamiter, center = true);
				translate([0, -screwHoleWidth,0]) cylinder(h = CutoutHeight, d = holeDiamiter, center = true);
			}
		}	else {
			holeDiamiter = 6 ;
			hull(){
				translate([0,  screwHoleWidth,0]) cylinder(h = CutoutHeight, d = holeDiamiter, center = true);
				translate([0, -screwHoleWidth,0]) cylinder(h = CutoutHeight, d = holeDiamiter, center = true);
			}	
		}
	}
	placeSupportPins(screwHoleWidth, wGenerateSupportPins);
}
module placeSupportPins(screwHoleWidth, wGenerateSupportPins){
	if(wGenerateSupportPins == "Yes" ){
		translate([12,screwHoleWidth,0]) supportPins();
		translate([12,-screwHoleWidth,0]) supportPins();
		translate([-12,screwHoleWidth,0]) supportPins();
		translate([-12,-screwHoleWidth,0]) supportPins();
	}
}
module supportPins(){
		difference(){
			hull(){
				cube([8,12,.1], center=true);
				translate([0,0,3]) cube([5,5,.1], center=true);
			}
			translate([0,0,4]) cylinder(h = 4, d = 2, center = true);
		}
}

module holdDownStraps(){
	translate([0,-5,0]) rotate([90,0,0]) holdDownStrap();
	translate([0,+5,0]) rotate([90,0,0]) holdDownStrap();
}

module holdDownStrap(){
	difference(){
		cube([34,5,2], center=true);
		translate([12,0,0]) cylinder(h = 6, d = 2, center = true);
		translate([-12,0,0]) cylinder(h = 6, d = 2, center = true);
	}
}

translate([15,0,0]) cutoutDB09vga("HOLE");
