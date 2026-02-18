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
// PROJECT: FIXED-WING "HIGH-PINCH" TOWER 
// VERSION: 2.1 (Buried Hex Key Edition)
// DESCRIPTION: Added hex_offset to allow the hex recess to be buried,
//              providing space for a nut to thread on top of the SMA barrel.
// =============================================================================

/* [1. BASE PLATE SETTINGS] */
base_w          = 35.0;  
base_l          = 55.0;  
base_thick      = 1.2;   
slot_width      = 1.6;   
slot_depth      = 0.6; 

/* [2. TOWER GEOMETRY] */
tower_h         = 20.0;  
sma_hole_dia    = 8.0;   
cable_slot_w    = 3.5;
wall_thickness  = 2.4;   
leading_edge_dist = 24.0; 

/* [3. SMA HEX KEY (BURIED LOGIC)] */
enable_hex      = true;
// Flat-to-flat size of the SMA base
hex_size        = 8.1; 
// Total height of the hexagonal cavity
hex_depth       = 4.0;
// How far down the hex starts (leaves space for the nut above)
hex_offset      = 3.0; 

/* [4. RETENTION] */
ziptie_width    = 3.0;
ziptie_thick    = 1.0;
ziptie_drop     = 5.0; 
ziptie_forward_shift = 0.5;

/* [5. INTERNAL CALCULATIONS] */
$fn = 60;
tower_dia = sma_hole_dia + (wall_thickness * 2);
spine_run   = (tower_dia * 1.5) - (tower_dia / 2);
spine_angle = atan2(spine_run, tower_h);

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    // --- STEP 1: THE SOLID BODY ---
    union() {
        scale([base_w / base_l, 1, 1])
            cylinder(h=base_thick, d=base_l);
        
        hull() {
            cylinder(h=tower_h + base_thick, d=tower_dia);
            
            translate([0, -leading_edge_dist, 0])
                cylinder(h=base_thick, d=1.5); 
            
            translate([0, tower_dia * 1.5, 0])
                cylinder(h=base_thick, d=tower_dia);

            translate([0, 0, base_thick])
                cube([tower_dia + 4, tower_dia + 4, 0.1], center=true);
        }
    }

    // --- STEP 2: THE SUBTRACTIONS ---

    // A. BOTTOM-FACE FLEX RELIEF SLOTS
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.05])
            cube([base_w + 5, slot_width, slot_depth + 0.1], center=true);
    }

    // B. THE SMA BORE (Full through hole)
    translate([0, 0, -1])
        cylinder(h=tower_h + base_thick + 5, d=sma_hole_dia);

    // C. BURIED HEX RECESS
    if (enable_hex) {
        // We move the hex down by the offset
        translate([0, 0, tower_h + base_thick - hex_depth - hex_offset])
            cylinder(h=hex_depth, d=hex_size / cos(30), $fn=6);
    }

    // D. THE REAR LOADING SLOT
    translate([0, tower_dia, (tower_h + base_thick)/2])
        cube([cable_slot_w, tower_dia * 2, tower_h + base_thick + 10], center=true);

    // E. THE HIGH-POSITIONED ZIP-TIE TRENCH
    translate([0, (tower_dia/2) + ziptie_forward_shift, tower_h + base_thick - ziptie_drop])
        rotate([spine_angle, 0, 0]) 
            cube([tower_dia + 10, ziptie_thick, ziptie_width], center=true);

    // F. BOTTOM CABLE PORT
    translate([0, 0, -1])
        cylinder(h=base_thick + 5, d=sma_hole_dia);
}
