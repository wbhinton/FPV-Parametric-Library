// =============================================================================
// PROJECT: 5.8 GHz HELICAL ANTENNA PARAMETRIC GEOMETRY ENGINE
// VERSION: 2.2 (Reflector Cutting Template Added)
// LICENSE: Creative Commons Zero (CC0) / Public Domain
// AUTHOR: Weston Hinton (2026)
// DESCRIPTION: Automated helical tracking antenna engine optimized for 
//              0.6mm nozzle setups. Features an added thin-disc template 
//              for scoring/tracing raw FR4 PCB stock manually.
// =============================================================================

/* [Antenna Tuning Specs] */
// Center Frequency in MHz (e.g., 5790 for Raceband 1,3,5,8 mix)
centerFrequency = 5790; // [5000:10:6000]
// Number of turns (5 is the sweet spot for FPV goggles)
turns = 5; // [1:1:16]
// Circular polarization direction
polarization = "right"; // [left: Left, right: Right]
// Diameter of your physical copper wire in mm (12 AWG ≈ 2.05mm)
wireDiameter = 2.05;

/* [Reflector Customization] */
// Reflector sizing scale relative to wavelength (0.75 lambda is minimum)
reflectorScale = 0.75; // [0.75: Minimum (0.75 X Lambda), 0.85: Oversized, 0.95: High Shielding, 1.00: Max Performance]

/* [Slicer & Print Optimization] */
// Your printer's nozzle diameter in mm (Optimized for 0.6mm setups)
nozzleSize = 0.6; // [0.4, 0.6, 0.8]
// Target layer height for vertical prints (determines brim steps)
layerHeight = 0.24; 
// Desired perimeter count for structural walls
wallPerimeters = 3; 
// Desired thickness of the structural support plate (in mm)
frameDepth = 3.0; 
// Diametric padding for printed holes to counteract plastic shrinkage
holeClearance = 0.25;

/* [Hardware Specs] */
// Outer diameter of the semi-rigid coax shield (RG402 is approx 3.6mm)
coaxialDiameter = 3.6;
// Thickness of your reflector plate material (Standard PCB is 1.6mm)
reflectorThickness = 1.6;

/* [Render Controls] */
part = "all"; // [all: All Parts, winding: Winding template, top: Top support frame, bottom: Bottom support frame, reflector: Reflector Base, cover: Reflector Cover, cutting_template: Reflector Cutting JIG, frame: All frame parts]

/* [Hidden RF Math Engine] */
c = 299792458 * 1000; // mm/s
lambda = c / (centerFrequency * 1000000); 
meanDiameter = lambda / PI; 
D = meanDiameter - wireDiameter; 
pitchSpacing = meanDiameter * PI * tan(12.5); 
L = turns * pitchSpacing; 

calculatedReflectorDiameter = reflectorScale * lambda; 

/* [Slicer-Driven Geometry Calcs] */
extrusionWidth = nozzleSize * 1.125; 
walls = extrusionWidth * wallPerimeters;
reflectorWalls = extrusionWidth * 3; 
reflectorCoverWalls = extrusionWidth * 2;

depth = round(frameDepth / layerHeight) * layerHeight;
reflectorCoverBrimHeight = layerHeight * 3; 
reflectorBackCoverHeight = layerHeight * 4; 

innerDiameter = D;
conductorDiameter = wireDiameter;
height = L;
spacing = pitchSpacing;
reflectorDiameter = calculatedReflectorDiameter + 3;

$fn = 64;
direction = polarization;
enableReflectorMounts = "enabled";
innerRadius = innerDiameter / 2;
conductorRadius = conductorDiameter / 2;

cutoutRadius = (spacing - (walls + conductorRadius) * 2) / 2;
cutoutY = cutoutRadius + depth / 2 + walls * 1.5;

// Helper function to calculate the Z-height of the wire at any turn coordinate t (angle / 360)
// Flat at 1.5mm above reflector for first 90 degrees (t <= 0.25), then climbs at standard pitchSpacing.
function wire_z_turns(t) = 
    (t < 0) ? (1.5 + t * pitchSpacing) :
    (t <= 0.25) ? 1.5 : 
    (1.5 + (t - 0.25) * pitchSpacing);

topRadius = innerRadius + conductorRadius - cutoutRadius;
holeRadius = conductorRadius + (holeClearance / 2); 

holeWrapperRadius = conductorRadius + walls;
holeWrapperY = innerRadius + conductorRadius;
holeWrapperZ = conductorRadius + walls;

reflectorRadius = reflectorDiameter / 2;
reflectorDiameterOuter = reflectorDiameter + reflectorWalls * 2;
reflectorCoverHeight = reflectorWalls + reflectorThickness + reflectorCoverBrimHeight;
reflectorCoverDepth = depth + 0.4;
reflectorCoverBrim = extrusionWidth * 3; 

coverWidth = reflectorDiameter + reflectorWalls * 2 + reflectorCoverWalls * 2;
reflectorWallOffset = reflectorCoverWalls + reflectorWalls;
reflectorBrimTotal = reflectorCoverBrim * 2;
widthCross = 0.4 + reflectorDiameterOuter;
coverRadius = coverWidth / 2;

coaxialRadius = coaxialDiameter / 2;
reflectorBackCoverSnapHeight = reflectorWalls - 0.2;
reflectorBackCoverSnapWidth = extrusionWidth * 4;
reflectorBackCoverOuterRadius = coverRadius - reflectorCoverWalls - reflectorWalls - 0.2;
reflectorBackCoverOuterWidth = reflectorDiameter - 0.4;

renderPart();

// =============================================================================
// ASSEMBLY CONTROLLER
// =============================================================================
module renderPart() {
    gap = 8; 
    
    if(part == "all") {
        translate([0, 0, depth / 2]) renderTop();
        translate([coverWidth + gap, 0, depth / 2]) renderBottom();
     
        translate([0, -coverWidth / 2 - reflectorThickness - reflectorWalls - gap, 0]) 
            template(cw = (direction == "right") ? false : true);
        
        translate([-coverWidth / 2, -coverWidth - reflectorThickness - reflectorWalls - gap, 0]) roundReflector();
        translate([coverWidth / 2 + gap, -coverWidth - reflectorThickness - reflectorWalls - gap, 0]) coverRound();
        
        // Offset template to the far right side of the print bed setup
        translate([coverWidth * 2 + gap * 2, 0, 0]) reflectorCuttingTemplate();
    }

    if(part == "frame") {
        translate([0, 0, depth / 2]) renderTop();
        translate([coverWidth + gap, 0, depth / 2]) renderBottom();
        translate([0, -coverWidth - gap, 0]) roundReflector();
        translate([coverWidth + gap, -coverWidth - gap, 0]) coverRound();
    }

    if(part == "winding") template(cw = (direction == "right") ? false : true);
    if(part == "top") renderTop();
    if(part == "bottom") renderBottom();
    if(part == "reflector") roundReflector();
    if(part == "cover") coverRound();
    if(part == "cutting_template") reflectorCuttingTemplate();
}

// =============================================================================
// HELICAL WINDING MANDREL MODULE
// =============================================================================
module template(cw = true) {
    local_overlap = 0.05; 
    
    additionalHeight = height / turns;
    totalHeight = height + additionalHeight;
    
    fdm_groove_padding = 0.15; 
    tool_radius = conductorRadius + fdm_groove_padding;
    coil_center_line_r = meanDiameter / 2;
    
    mandrel_pillar_r = coil_center_line_r + (conductorRadius * 0.4);
    
    difference() {
        cylinder(h = totalHeight, r = mandrel_pillar_r);
        
        for (theta = [0 : 3 : (turns + 1) * 360]) {
            translate([coil_center_line_r * cos(theta * (cw ? -1 : 1)), coil_center_line_r * sin(theta * (cw ? -1 : 1)), wire_z_turns(theta / 360)])
                sphere(r = tool_radius, $fn = 16);
        }
    }
}

// =============================================================================
// NEW: REFLECTOR CUTTING JIG TEMPLATE
// =============================================================================
module reflectorCuttingTemplate() {
    // 4 solid layers thick at 0.24mm layer height
    template_thickness = layerHeight * 4; 

    // Outer disc matching the target PCB cut radius precisely (no coax cutout hole needed for side-feed)
    cylinder(h = template_thickness, r = reflectorRadius, $fn = 128);
}

// =============================================================================
// MECHANICAL HOUSING COMPONENTS
// =============================================================================
module roundReflector() {
    translate([coverRadius, coverRadius, 0]) {
        difference() {
            cylinder(r = coverRadius, h = reflectorCoverHeight);
            translate([0, 0, reflectorCoverBrimHeight]) cylinder(r = reflectorRadius, h = reflectorCoverHeight);
            translate([0, 0, -1]) cylinder(r = reflectorRadius - reflectorCoverBrim, h = reflectorCoverHeight + 2);
            translate([-widthCross / 2, -reflectorCoverDepth / 2, -1]) cube([widthCross, reflectorCoverDepth, reflectorCoverHeight + 2]);
            translate([-reflectorCoverDepth / 2, 0, -1]) cube([reflectorCoverDepth, widthCross / 2, reflectorCoverHeight + 2]);
        }
    }
}

module coverRound() {        
    difference() {
        translate([coverRadius, coverRadius, 0]) {
            union(){
                cylinder(r = coverRadius, h = reflectorBackCoverHeight);
                difference() {
                    cylinder(r = reflectorBackCoverOuterRadius, h = reflectorBackCoverHeight + reflectorBackCoverSnapHeight);
                    cylinder(r = reflectorBackCoverOuterRadius - reflectorBackCoverSnapWidth, h = reflectorBackCoverHeight + reflectorBackCoverSnapHeight + 1);
                }
            }
        }
        translate([reflectorCoverWalls - 0.2, coverWidth/2 - reflectorCoverDepth, reflectorBackCoverHeight]) cube([widthCross, reflectorCoverDepth * 2, reflectorCoverHeight + 2]);
        translate([coverWidth / 2 - reflectorCoverDepth, reflectorCoverWalls - 0.2, reflectorBackCoverHeight]) cube([reflectorCoverDepth * 2, widthCross, reflectorCoverHeight + 2]);
    }
}

module renderTop() { rotate([0, 270, 270]) top(); }
module renderBottom() { rotate([0, 270, 270]) bottom(); }
    
module top() {
    slitHeight = (height) / 2 + 0.2;
    turnOffset = 0;
    difference() {
        support(turnOffset = turnOffset, mounts = (enableReflectorMounts == "enabled") ? true : false);
        translate([-depth, -depth / 2 - 0.05, -1]) cube([depth + 2, depth + 0.1, slitHeight + 1]);
        hull() {
            rotate([0,90,0]) {
                translate([-wire_z_turns(turns + turnOffset / pitchSpacing), -innerDiameter, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                translate([-wire_z_turns(turns + turnOffset / pitchSpacing), -cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                translate([-wire_z_turns(turns + 1 + turnOffset / pitchSpacing), -innerDiameter, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                translate([-wire_z_turns(turns + 1 + turnOffset / pitchSpacing), -cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
            }
        }
    }
}

module bottom() {
    slitOffset = (height / 2) - 0.2;
    turnOffset = spacing / 4;
    difference() {
        support(turnOffset = turnOffset, mounts = (enableReflectorMounts == "enabled") ? true : false, both = false);
        translate([-depth, -depth / 2 - 0.05, slitOffset]) cube([depth + 2, depth + 0.1, height]);
        hull() {
            rotate([0,90,0]) {
                translate([-wire_z_turns(turns - 0.5 + turnOffset / pitchSpacing), innerDiameter, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                translate([-wire_z_turns(turns - 0.5 + turnOffset / pitchSpacing), cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                translate([-wire_z_turns(turns + 0.5 + turnOffset / pitchSpacing), innerDiameter, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                translate([-wire_z_turns(turns + 0.5 + turnOffset / pitchSpacing), cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
            }
        }
    }
}

module support(turnOffset = 0, mounts = true, both = true) {
    difference() {
        union() {
            difference() {
                union() {
                    spineWidth = holeWrapperY + holeWrapperRadius;
                    translate([-depth / 2, -spineWidth, 0]) cube([depth, spineWidth * 2, turns * spacing + holeWrapperRadius * 2]);
                }

                rotate([0,90,0]) {
                    hull() {
                        translate([-wire_z_turns(-turnOffset / pitchSpacing), -cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                        translate([-wire_z_turns(-turnOffset / pitchSpacing), -cutoutY * 2, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                        translate([-wire_z_turns(-1 - turnOffset / pitchSpacing), -cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                        translate([-wire_z_turns(-1 - turnOffset / pitchSpacing), -cutoutY * 2, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                    }
                    hull() {
                        translate([-wire_z_turns(-0.5 - turnOffset / pitchSpacing), holeWrapperY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                        translate([-wire_z_turns(-0.5 - turnOffset / pitchSpacing), cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                        translate([-wire_z_turns(-1.5 - turnOffset / pitchSpacing), holeWrapperY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                        translate([-wire_z_turns(-1.5 - turnOffset / pitchSpacing), cutoutY, -depth + 1]) cylinder(r = cutoutRadius, h = depth + 2);
                    }
                }
            }
            if(mounts && both) {
                difference() {
                    translate([-depth / 2,-reflectorDiameterOuter / 2, -reflectorWalls - reflectorThickness]) cube([depth, reflectorDiameterOuter, reflectorWalls * 2 + reflectorThickness]);
                    translate([-depth / 2 - 1,-reflectorRadius, -reflectorThickness]) cube([depth + 2, reflectorDiameter, reflectorThickness]);
                    translate([-depth / 2 - 1, -reflectorRadius + reflectorWalls, -reflectorWalls - reflectorThickness - 1]) cube([depth + 2, reflectorDiameter - reflectorWalls * 2, reflectorWalls + 2]);
                }
            }
            if(mounts && !both) {
                difference() {
                    translate([-depth / 2, 0, -reflectorWalls - reflectorThickness]) cube([depth, reflectorDiameterOuter / 2, reflectorWalls * 2 + reflectorThickness]);
                    translate([-depth / 2 - 1,-reflectorRadius, -reflectorThickness]) cube([depth + 2, reflectorDiameter, reflectorThickness]);
                    translate([-depth / 2 - 1, -reflectorRadius + reflectorWalls, -reflectorWalls - reflectorThickness - 1]) cube([depth + 2, reflectorDiameter - reflectorWalls * 2, reflectorWalls + 2]);
                }
            }
        }
        for(i=[0:1:turns - 1]) {
            rotate([0,90,0]) translate([-wire_z_turns(i + 0.5 + turnOffset / pitchSpacing), -holeWrapperY, -depth + 1]) cylinder(r = holeRadius, h = depth + 2);
        }
        for(i=[0:1:turns]) {
            rotate([0,90,0]) translate([-wire_z_turns(i + turnOffset / pitchSpacing), holeWrapperY, -depth + 1]) cylinder(r = holeRadius, h = depth + 2);
        }
    }
}