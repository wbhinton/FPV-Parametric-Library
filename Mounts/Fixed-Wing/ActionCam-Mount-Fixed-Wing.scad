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
// PROJECT: FIXED-WING "AERO-GOPRO" ELLIPSE MOUNT
// VERSION: 1.6 (Final Annotated Version)
// DESCRIPTION: Aerodynamic action camera mount with an elliptical base.
//              Optimized for TPU printing and conformal wing gluing.
// =============================================================================

/* [1. BASE PLATE SETTINGS] */

// The 'Span' of the glue surface (Left to Right)
base_w          = 45.0;  
// The 'Chord' of the glue surface (Front to Back)
base_l          = 65.0;  
// The 'Membrane' thickness (Keep this thin for best wing-wrap)
base_thick      = 1.2;   
// Gap for the flex-slots (Helps the part bend around a fuselage)
slot_width      = 1.6;   

/* [2. GOPRO 3-TAB SETTINGS] */

// Thickness of a single vertical mounting prong
tab_thick       = 3.0;   
// The gap required to fit a standard 2-tab camera housing
tab_gap         = 3.2;   
// Distance from the glue-line to the center of the bolt hole
mount_height    = 13.0; 
// Standard M5 bolt diameter (includes 0.2mm tolerance for TPU)
m5_hole_dia     = 5.2;   
// Standard M5 hex nut (Flat-to-Flat dimension)
m5_nut_dia      = 8.2;   
// How deep the nut sits (Allows the bolt to grab deep threads)
m5_nut_depth    = 1.5; 

/* [3. AERO SETTINGS] */

// The 'Reach' of the nose to split the air
leading_edge_dist = 26.0; 
// Detail Level: 80-100 is best for smooth elliptical curves
$fn = 80; 

/* [4. INTERNAL CALCULATIONS] */

// Logic: (3 prongs * their thickness) + (2 gaps between them)
total_tab_width = (tab_thick * 3) + (tab_gap * 2);

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

// THE 'DIFFERENCE' FUNCTION: 
// It takes the first object and 'subtracts' everything that follows it.
difference() {
    
    // --- STEP 1: THE SOLID BODY (POSITIVE GEOMETRY) ---
    union() {
        
        // A. THE ELLIPTICAL BASE
        // Logic: We start with a round cylinder and 'squash' it 
        // on the X-axis to create a perfect elliptical footprint.
        scale([base_w/base_l, 1, 1])
            cylinder(h=base_thick, d=base_l, center=false);
        
        // B. THE AERO-PEDESTAL (THE PYLON)
        // Logic: 'hull' stretches a skin between multiple shapes.
        hull() {
            // This is the 'neck' that supports the tabs
            translate([0, 0, (mount_height-7)/2])
                cube([total_tab_width, 10, mount_height-7], center=true);
            
            // This is the Leading Edge (The 'Nose')
            translate([0, -leading_edge_dist, 0])
                cylinder(h=base_thick, d=1.5); 
            
            // This is the Trailing Edge (The 'Spine')
            translate([0, 20, 0])
                cylinder(h=base_thick, d=total_tab_width);
        }
        
        // C. THE MOUNTING TAB BLOCK
        // Logic: We create a single block here; the slots are cut in Step 2.
        translate([0, 0, mount_height])
            rotate([0, 90, 0])
                hull() {
                    // The rounded top of the prongs
                    cylinder(h=total_tab_width, d=14.5, center=true);
                    // Blending the tabs down into the pylon
                    translate([7, 0, 0]) 
                        cube([1, 10, total_tab_width], center=true);
                }
    }

    // --- STEP 2: THE SUBTRACTIONS (THE MILLING PHASE) ---

    // A. THE M5 BOLT HOLE
    // Logic: A horizontal drill that pierces all three tabs.
    translate([0, 0, mount_height])
        rotate([0, 90, 0])
            cylinder(h=total_tab_width + 10, d=m5_hole_dia, center=true);

    // B. THE M5 NUT TRAP
    // Logic: A 6-sided cylinder (hexagon) that creates the nut-lock.
    translate([total_tab_width/2 - m5_nut_depth + 0.1, 0, mount_height])
        rotate([0, 90, 0])
            cylinder(h=m5_nut_depth + 1, d=m5_nut_dia / cos(30), $fn=6);

    // C. THE PRONG GAPS
    // Logic: Removing two blocks of material to leave three prongs behind.
    for(x = [-1, 1]) {
        translate([x * (tab_thick/2 + tab_gap/2), 0, mount_height + 5])
            cube([tab_gap, 25, 25], center=true);
    }

    // D. FLEX RELIEF SLOTS (THE 'TANK TREAD')
    // Logic: Cuts into the bottom 1.2mm to allow the TPU to 'hinge'.
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.1])
            cube([base_w + 5, slot_width, base_thick + 0.1], center=true);
    }
}
