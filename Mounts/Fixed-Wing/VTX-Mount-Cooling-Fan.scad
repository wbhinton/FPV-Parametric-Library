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
// PROJECT: FPV PARAMETRIC LIBRARY - V-STACK VTX MOUNT
// VERSION: 3.9.1 (Base Insert Ready)
// DESCRIPTION: Added heat-set insert recesses to the base plate standoffs.
// =============================================================================

/* [1. VIEW & RENDER CONTROL] */
mode = 2; // [1:Assembly View, 2:Base Plate (Bottom), 3:The Hat (Top)]

/* [2. VTX (VIDEO TRANSMITTER) DIMENSIONS] */
vtx_w = 30.5;  
vtx_l = 30.5;  
vtx_pcb_thick = 1.6;   
base_standoff_h = 6.0;   
standoff_dia = 7.0;   

/* [3. FAN & PLENUM SETTINGS] */
fan_w = 32.0;  
fan_l = 32.0;
fan_aperture = 35.0;  
fan_gap = 8.0;   
fan_plate_thick = 5.0;   
plate_padding = 4.0; 
leg_extension = 4.0;

/* [4. HARDWARE & FIT] */
insert_hole_dia = 4.5;   
insert_hole_depth = 4.5;
screw_dia = 3.4;   
screw_head_dia = 6.5;   
screw_head_depth = 2.5;  

/* [5. GLOBAL SETUP] */
base_w = 48.0;  
base_l = 58.0;  
base_thick = 1.2;   
$fn = 60;

// --- DYNAMIC CALCULATIONS ---
hat_z_pos = base_thick + base_standoff_h + vtx_pcb_thick;
total_hat_h = (fan_gap - leg_extension) + fan_plate_thick + leg_extension;

fan_diag_reach = sqrt(pow(fan_w/2, 2) + pow(fan_l/2, 2));
required_plate_w = max(vtx_w, fan_diag_reach * 2) + (plate_padding * 2);
required_plate_l = max(vtx_l, fan_diag_reach * 2) + (plate_padding * 2);

// =============================================================================
// MAIN EXECUTION
// =============================================================================

if (mode == 1) {
    base_plate();
    %translate([0, 0, base_thick + base_standoff_h + vtx_pcb_thick/2])
        cube([vtx_w + 5, vtx_l + 5, vtx_pcb_thick], center=true);
    translate([0, 0, hat_z_pos]) the_hat();
} 
else if (mode == 2) {
    base_plate();
} 
else if (mode == 3) {
    translate([0, 0, total_hat_h]) rotate([180, 0, 0]) the_hat();
}

// =============================================================================
// MODULES
// =============================================================================

module base_plate() {
    difference() {
        union() {
            rounded_rect(base_w, base_l, base_thick, 8);
            for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2]) {
                translate([x, y, base_thick - 0.1]) {
                    cylinder(h=base_standoff_h, d=standoff_dia);
                    hull() {
                        cylinder(h=0.1, d=standoff_dia + 6);
                        translate([0, 0, 3]) cylinder(h=0.1, d=standoff_dia);
                    }
                }
            }
        }
        // SUBTRACTIONS
        for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2]) {
            // 1. Bolt Through-Hole
            translate([x, y, -1]) 
                cylinder(h=base_standoff_h + base_thick + 2, d=screw_dia);
            
            // 2. INSERT RECESS (At the top of the standoff)
            translate([x, y, base_thick + base_standoff_h - insert_hole_depth + 0.1])
                cylinder(h=insert_hole_depth, d=insert_hole_dia);
        }
        
        // Flex Slots
        for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6])
            translate([0, i, -0.1]) cube([base_w + 10, 1.6, base_thick + 0.5], center=true);
    }
}

module the_hat() {
    difference() {
        union() {
            // 1. TOP PLATE
            translate([0, 0, total_hat_h - fan_plate_thick])
                rounded_rect(required_plate_w, required_plate_l, fan_plate_thick, 8);
            
            // 2. HULLED PLENUM WALLS
            for(x_side = [-vtx_w/2, vtx_w/2]) {
                hull() {
                    for(y_side = [-vtx_l/2, vtx_l/2]) {
                        translate([x_side, y_side, (total_hat_h - fan_plate_thick + leg_extension)/2])
                            cylinder(h = total_hat_h - fan_plate_thick - leg_extension, d = standoff_dia, center=true);
                    }
                }
            }
            
            // 3. CORNER PILLARS
            for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2])
                translate([x, y, 0]) cylinder(h=total_hat_h - 0.1, d=standoff_dia);
        }

        // A. FAN AIRWAY
        translate([0, 0, total_hat_h - 10]) cylinder(h=20, d=fan_aperture);

        // B. FAN INSERT HOLES (Rotated 45)
        rotate([0, 0, 45])
            for(x = [-fan_w/2, fan_w/2], y = [-fan_l/2, fan_l/2])
                translate([x, y, total_hat_h - insert_hole_depth + 0.1]) 
                    cylinder(h=insert_hole_depth + 1, d=insert_hole_dia);

        // C. VTX MOUNTING HOLES (Top Down)
        for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2]) {
            translate([x, y, -1]) cylinder(h=total_hat_h + 2, d=screw_dia);
            translate([x, y, total_hat_h - screw_head_depth + 0.01]) 
                cylinder(h=screw_head_depth + 1, d=screw_head_dia);
        }
        
        // D. FAN BOLT CLEARANCE
        rotate([0, 0, 45])
            for(x = [-fan_w/2, fan_w/2], y = [-fan_l/2, fan_l/2])
                translate([x, y, -1]) cylinder(h=total_hat_h + 2, d=3.2);
    }
}

module rounded_rect(w, l, h, r) {
    hull() {
        for(x = [-w/2+r, w/2-r], y = [-l/2+r, l/2-r])
            translate([x, y, 0]) cylinder(h=h, r=r);
    }
}
