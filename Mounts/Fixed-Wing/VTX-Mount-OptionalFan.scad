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
// PROJECT: FIXED-WING "V-STACK" VTX + MODULAR FAN MOUNT
// VERSION: 2.4 (Chamfered Standoff Bases)
// DESCRIPTION: Added structural chamfers to standoff bases for high-G stability.
// =============================================================================

/* [1. MODULAR OPTIONS] */
use_fan_mount   = 1; 

/* [2. BASE PLATE SETTINGS] */
base_w          = 58.0;  
base_l          = 58.0;  
base_thick      = 1.2;   
base_radius     = 8.0;   
slot_width      = 1.6;   

/* [3. VTX STACK SETTINGS] */
stack_vtx_w     = 30.5;  
stack_vtx_l     = 30.5;  
stack_vtx_h     = 6.0;   
vtx_thickness   = 6.5;   

/* [4. FAN STACK SETTINGS] */
stack_fan_w     = 24.0;  
stack_fan_l     = 24.0;  
fan_gap         = 3.0;   

/* [5. HARDWARE & CHAMFER SPECS] */
standoff_dia    = 8.5;   
// Vertical and horizontal size of the reinforcement
chamfer_h       = 3.0; 
insert_hole_dia = 4.0;   
insert_hole_depth = 4.5; 
screw_clearance_dia = 3.0; 

$fn = 60;

/* [6. DYNAMIC CALCULATIONS] */
total_fan_h = stack_vtx_h + vtx_thickness + fan_gap;

// =============================================================================
// MODULES
// =============================================================================

module reinforced_standoff(total_h) {
    // 1. The Main Cylinder
    cylinder(h=total_h, d=standoff_dia);
    
    // 2. The Chamfered Base
    // Creates a smooth slant from a wider footprint up to the cylinder
    hull() {
        cylinder(h=0.1, d=standoff_dia + (chamfer_h * 2));
        translate([0, 0, chamfer_h])
            cylinder(h=0.1, d=standoff_dia);
    }
}

module stepped_hole(total_h) {
    translate([0, 0, total_h - insert_hole_depth + 0.01])
        cylinder(h=insert_hole_depth + 1, d=insert_hole_dia);
    translate([0, 0, -1])
        cylinder(h=total_h + 2, d=screw_clearance_dia);
}

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    union() {
        // A. The Flexible Base Plate
        hull() {
            for(x = [-base_w/2 + base_radius, base_w/2 - base_radius]) {
                for(y = [-base_l/2 + base_radius, base_l/2 - base_radius]) {
                    translate([x, y, 0])
                        cylinder(h=base_thick, r=base_radius);
                }
            }
        }
        
        // B. VTX Standoffs with Reinforcement
        for(x = [-stack_vtx_w/2, stack_vtx_w/2]) {
            for(y = [-stack_vtx_l/2, stack_vtx_l/2]) {
                translate([x, y, base_thick - 0.1])
                    reinforced_standoff(stack_vtx_h);
            }
        }
        
        // C. Fan Standoffs with Reinforcement
        if (use_fan_mount == 1) {
            rotate([0, 0, 45]) {
                for(x = [-stack_fan_w/2, stack_fan_w/2]) {
                    for(y = [-stack_fan_l/2, stack_fan_l/2]) {
                        translate([x, y, base_thick - 0.1])
                            reinforced_standoff(total_fan_h);
                    }
                }
            }
        }
    }

    // --- STEP 2: THE SUBTRACTIONS ---

    // VTX Holes
    for(x = [-stack_vtx_w/2, stack_vtx_w/2]) {
        for(y = [-stack_vtx_l/2, stack_vtx_l/2]) {
            translate([x, y, 0])
                stepped_hole(stack_vtx_h + base_thick);
        }
    }

    // Fan Holes
    if (use_fan_mount == 1) {
        rotate([0, 0, 45]) {
            for(x = [-stack_fan_w/2, stack_fan_w/2]) {
                for(y = [-stack_fan_l/2, stack_fan_l/2]) {
                    translate([x, y, 0])
                        stepped_hole(total_fan_h + base_thick);
                }
            }
        }
    }

    // Flex Relief Slots
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.1])
            cube([base_w + 10, slot_width, base_thick + 0.5], center=true);
    }
}
