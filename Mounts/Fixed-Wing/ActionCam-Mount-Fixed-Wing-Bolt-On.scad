// Copyright (C) 2026 Weston Hinton <wbhinton@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// =============================================================================
// PROJECT: PARAMETRIC TPU ACTION CAM MOUNT
// VERSION: 3.3 
// =============================================================================

/* [1. MOUNTING INTERFACE] */
// Width spacing of the base mounting bolts (center-to-center)
pattern_w       = 19.0;  
// Length spacing of the base mounting bolts (center-to-center)
pattern_l       = 19.0;  
// Diameter of base mounting hardware (e.g., M3 screws)
base_bolt_dia   = 3.4;   
// Thickness of the structural base flange
base_thick      = 2;   
// Diameter of the reinforced collar around base screws
lug_dia         = 8.0;   

/* [2. ACTION CAM PRONGS] */
bolt_dia           = 3.0;   
tab_wall_thickness = 3.6;  
nut_dia            = 5.5;   
nut_depth          = 2.0;   
tab_thick          = 3.0;   
tab_gap            = 3.2;   
mount_height       = 10.0; 
ramp_reach         = 5.0;   

/* [3. INTERNAL CALCULATIONS] */
tab_outer_dia   = bolt_dia + (tab_wall_thickness * 1.5); 
total_tab_width = (tab_thick * 3) + (tab_gap * 2);
$fn = 80; 

// =================================================================
// MAIN ASSEMBLY
// =================================================================

difference() {
    
    // --- STEP 1: THE SOLID SKELETON ---
    union() {
        // A. THE 4 CORNER MOUNTING LUGS
        for(x = [-1, 1], y = [-1, 1]) {
            translate([x * pattern_w/2, y * pattern_l/2, 0])
                cylinder(h=base_thick, d=lug_dia, center=false);
        }
        
        // B. THE SKELETONIZED STRUCTURAL TRUSS
        hull() {
            for(x = [-1, 1], y = [-1, 1]) {
                translate([x * pattern_w/2, y * pattern_l/2, 0])
                    cylinder(h=base_thick, d=lug_dia, center=false);
            }
        }
        
        // C. THE BI-DIRECTIONAL PYLON (Symmetrical Ramp)
        hull() {
            translate([0, -ramp_reach, 0])
                cylinder(h=base_thick, d=total_tab_width); 
            translate([0, ramp_reach, 0])
                cylinder(h=base_thick, d=total_tab_width);

            translate([0, 0, mount_height])
                rotate([0, 90, 0])
                    cylinder(h=total_tab_width, d=tab_outer_dia, center=true);
        }
    }

    // --- STEP 2: SUBTRACTIONS ---

    // A. GO-PRO CAMERA INTERFACE (Hinge Bolt)
    translate([0, 0, mount_height])
        rotate([0, 90, 0])
            cylinder(h=total_tab_width + 10, d=bolt_dia, center=true);

    // B. NUT TRAP
    translate([total_tab_width/2 - nut_depth + 0.1, 0, mount_height])
        rotate([0, 90, 0])
            cylinder(h=nut_depth + 1, d=nut_dia / cos(30), $fn=6);

    // C. FULL-DEPTH PRONG GAPS
    // Absolute cut sizing prevents short cuts when slammed down low
    for(x = [-1, 1]) {
        translate([x * (tab_thick/2 + tab_gap/2), 0, mount_height + 0.5])
            cube([tab_gap, pattern_l * 2.5, tab_outer_dia + 1.0], center=true);
    }

    // D. 4X BASE BOLT MOUNTING HOLES
    for(x = [-1, 1], y = [-1, 1]) {
        translate([x * pattern_w/2, y * pattern_l/2, -0.5])
            cylinder(h=base_thick + 2.0, d=base_bolt_dia, center=false);
    }
}