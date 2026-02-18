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
// PROJECT: VERTICAL FIXED-WING "AERO-FOIL" ELRS MOUNT
// VERSION: 1.2 (Symmetrical Airfoil & Glue-Retention)
// DESCRIPTION: Dual-teardrop profile (Airfoil) for zero-drag performance.
//              Optimized for glue-retention (no zip-tie slots).
// =============================================================================

/* [1. BASE PLATE SETTINGS] */
base_w          = 20.0;  
base_l          = 45.0;  // Slightly longer to accommodate the dual-taper
base_thick      = 1.2;   
slot_width      = 1.6;   

/* [2. ANTENNA HARDWARE SPECS] */
dipole_arm_l    = 13.0;  
junction_l      = 5.5;   
junction_dia    = 3.2;   
wire_dia        = 1.6;   
feedline_dia    = 2.0;   
wall_thickness  = 2.2; 

/* [3. AERO SETTINGS] */
// How far the "points" of the teardrop extend from the center (mm)
aero_taper_dist = 18.0; 
$fn = 60;

/* [4. DYNAMIC CALCULATIONS] */
pylon_h = dipole_arm_l + junction_l; 
pylon_dia = junction_dia + (wall_thickness * 2);

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP 1: THE SOLID BODY (The Symmetrical Airfoil) ---
    union() {
        // A. The Flexible Base Plate
        translate([0, 0, base_thick/2])
            cube([base_w, base_l, base_thick], center=true);
        
        // B. The Double-Teardrop Pylon (Airfoil)
        hull() {
            // 1. The Central Cylinder (Houses the hardware)
            cylinder(h=pylon_h + base_thick, d=pylon_dia);
            
            // 2. The Leading Edge (Front Point)
            translate([0, -aero_taper_dist, 0])
                cylinder(h=base_thick, d=1.5); 
            
            // 3. The Trailing Edge (Rear Point)
            translate([0, aero_taper_dist, 0])
                cylinder(h=base_thick, d=1.5); 

            // 4. Base Gusset (Structural support)
            translate([0, 0, base_thick])
                cube([pylon_dia + 4, pylon_dia + 4, 0.1], center=true);
        }
    }

    // --- STEP 2: THE SUBTRACTIONS ---

    // A. FLEX RELIEF SLOTS (Bottom membrane only)
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.1])
            cube([base_w + 2, slot_width, base_thick + 0.1], center=true);
    }

    // B. THE ANTENNA CAVITY (Top-Down)
    translate([0, 0, pylon_h + base_thick]) {
        
        // 1. Vertical Dipole Bore
        translate([0, 0, -pylon_h - 1])
            cylinder(h=pylon_h + 2, d=wire_dia);
            
        // 2. T-Junction "Saddle" 
        rotate([0, 90, 0])
            cylinder(h=junction_l + 0.5, d=junction_dia, center=true);
            
        // 3. Feedline Exit (Rear-facing)
        translate([0, pylon_dia/2, 0])
            rotate([90, 0, 0])
                cylinder(h=aero_taper_dist + 5, d=feedline_dia);

        // 4. Top Access Slots (Clean drop-in)
        cube([junction_l + 0.5, junction_dia, 10], center=true);
        translate([0, aero_taper_dist/2, 0])
            cube([feedline_dia, aero_taper_dist, 10], center=true);
    }

    // C. WIRE POKEOUT (Through-base access)
    translate([0, 0, -1])
        cylinder(h=base_thick + 5, d=feedline_dia);
}
