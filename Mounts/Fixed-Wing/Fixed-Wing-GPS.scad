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
// PROJECT: FPV COMPONENT LIBRARY - FIXED WING GPS
// VERSION: 2.8 (Pure Flange Architecture - No Artifacts)
// DESCRIPTION: Hull anchors directly to Z=0. Base size controls the flange.
// =============================================================================

/* [1. FLANGE & FLEX SETTINGS] */
// Tilt to compensate for wing angle
gps_angle       = 5;    
// Width of the mounting footprint
base_w          = 35.0;  
// Length of the mounting footprint
base_l          = 55.0;  
// Width of the relief cuts
slot_width      = 1.5;   
// Depth of the relief cuts (cuts from the bottom up)
slot_depth      = 1.0;
// Distance between centers of relief cuts
slot_pitch      = 6.0;   
corner_radius   = 2.0;   

/* [2. GPS UNIT DIMENSIONS] */
gps_w = 21;              
gps_l = 21;              
gps_h = 8.0;            
wall  = 1.2;             

/* [3. WIRE & HARDWARE] */
// 1:Front, 2:Right, 3:Back, 4:Left
wire_side    = 3;        
wire_width   = 12;      
wire_offset  = 0;      
zt_width     = 3.5;      
zt_depth     = 1.5;      
nob_height   = 1.2;      
chamfer_size = 2.0;      

/* [4. INTERNAL CALCULATIONS] */
box_w = gps_w + (wall*2);
box_l = gps_l + (wall*2);
$fn = 60;                

// ============================================================
// --- MAIN ASSEMBLY ---
// ============================================================

difference() {
    
    // --- STEP 1: SOLID GEOMETRY ---
    union() {
        // The Aerodynamic Fairing / Flange
        // Anchored directly to Z=0 to avoid artifacts
        hull() {
            // Anchor 1: The Footprint on the foam
            rounded_rect(base_w, base_l, 0.1);
            
            // Anchor 2: The flared base of the GPS box (lifted for the fairing)
            translate([0, 0, 4])
                rotate([-gps_angle, 0, 0])
                    gps_outer_shell_solid();
        }
        
        // Internal Corner Nobs (Anchored inside the tilted box)
        translate([0, 0, 4])
            rotate([-gps_angle, 0, 0])
                for(x=[-1,1], y=[-1,1])
                    translate([x*(gps_w/2 - 2), y*(gps_l/2 - 2), 0])
                        cylinder(h=nob_height + 0.1, d=3);
    }

    // --- STEP 2: PARAMETRIC FLEX RELIEF SLOTS ---
    // Cuts upward from slightly below Z=0
    for(i = [-base_l/2 + 5 : slot_pitch : base_l/2 - 5]) {
        translate([0, i, slot_depth/2 - 0.1]) 
            cube([base_w + 2, slot_width, slot_depth], center=true);
    }

    // --- STEP 3: INTERNAL VOIDS ---
    translate([0, 0, 4])
        rotate([-gps_angle, 0, 0]) {
            
            // GPS Cavity
            translate([0, 0, nob_height])
                rounded_rect(gps_w + 0.4, gps_l + 0.4, gps_h + 5);
            
            // Floor Relief
            rounded_rect(gps_w - 4, gps_l - 4, nob_height + 0.1);

            // Ejection hole (goes all the way through)
            translate([0, 0, -50]) cylinder(h=100, d=10);

            // Wire Exit
            rotate([0, 0, (wire_side-1) * -90])
                translate([wire_offset - (wire_width/2), - (gps_l/2) - wall - 5, 0])
                    cube([wire_width, wall + 10, gps_h + 1]);

            // Zip-tie Channel
            translate([0, 0, (zt_depth/2) - zt_depth])
                cube([gps_w + (wall*2) + 10, zt_width, zt_depth * 2], center=true);
        }
}

// ============================================================
// --- MODULES ---
// ============================================================

module gps_outer_shell_solid() {
    hull() {
        rounded_rect(box_w + (chamfer_size*2), box_l + (chamfer_size*2), 0.1);
        translate([0, 0, chamfer_size])
            rounded_rect(box_w, box_l, 0.1);
    }
    rounded_rect(box_w, box_l, gps_h);
}

module rounded_rect(w, l, h) {
    hull() {
        for(x=[-1,1], y=[-1,1])
            translate([x*(w/2 - corner_radius), y*(l/2 - corner_radius), 0])
                cylinder(h=h, r=corner_radius);
    }
}
