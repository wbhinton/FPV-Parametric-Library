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
// PROJECT: UNIVERSAL GPS STANDOFF MOUNT
// VERSION: 3.6 (Sharp Corner Edition)
// DESCRIPTION: Removed corner radii on the box for cleaner gusset integration.
// =============================================================================

/* [1. FRAME SETTINGS] */
standoff_dist   = 20.0;  
standoff_dia    = 5.5;   
standoff_height = 25.0;  
wall            = 1.6; 

/* [2. GPS COMPARTMENT SETTINGS] */
gps_angle       = 25;    
gps_offset      = 15.0;  
gps_w           = 21.0;  
gps_l           = 21.0;  
gps_h           = 8.0;   
nob_height      = 1.2;

/* [3. WIRE WINDOW SETTINGS] */
wire_width      = 12.0;  
wire_window_h   = 4.0;   
// Shift the window: (-) for Left, (+) for Right. 0 is Centered.
wire_offset     = -3.0; 

/* [4. HARDWARE & RETENTION] */
zt_width        = 3.;   
zt_depth        = 1.5; 
// Corner radius now only applies to the standoff sleeves
sleeve_radius   = 2.0;
$fn = 60;

/* [5. INTERNAL CALCULATIONS] */
box_w = gps_w + (wall * 2);
box_l = gps_l + (wall * 2);
box_d_total = gps_h + nob_height + 1.2; 

// Trig to keep top flush
tilt_lift = sin(gps_angle) * (box_l/2);
box_z_pos = standoff_height - (box_d_total / 2) - tilt_lift;

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    // --- STEP 1: SOLID GEOMETRY ---
    union() {
        // A. Standoff Sleeves
        for(i=[-1, 1]) {
            translate([i * standoff_dist/2, 0, 0])
                cylinder(h=standoff_height, d=standoff_dia + (wall*2));
        }

        // B. GPS Outer Shell (Sharp Corners)
        translate([0, gps_offset + (box_l/2), box_z_pos]) 
            rotate([-gps_angle, 0, 0]) {
                // Main sharp-edged box
                cube([box_w, box_l, box_d_total], center=true);
                
                // Internal Corner Nobs (Remains to support PCB)
                for(x=[-1,1], y=[-1,1])
                    translate([x*(gps_w/2 - 1.5), y*(gps_l/2 - 1.5), -box_d_total/2 + 1.2])
                        cylinder(h=nob_height + 0.1, d=3);
            }

        // C. SOLID TRIANGULAR GUSSETS
        for(side=[-1, 1]) { 
            hull() {
                // Round sleeve anchor
                translate([side * standoff_dist/2, 0, 0])
                    cylinder(h=standoff_height, d=standoff_dia + (wall*2));
                
                // Sharp box anchor (Full vertical edge)
                translate([0, gps_offset + (box_l/2), box_z_pos]) 
                    rotate([-gps_angle, 0, 0])
                        translate([side * (box_w/2 - 0.5), 0, 0])
                            cube([1, box_l, box_d_total], center=true);
            }
        }
    }

    // --- STEP 2: SUBTRACTIONS ---
    
    // A. SAFETY PLANE CUT
    translate([-100, -100, standoff_height])
        cube([200, 200, 50]);

    // B. STANDOFF HOLES
    for(i=[-1, 1]) {
        translate([i * standoff_dist/2, 0, -1])
            cylinder(h=standoff_height + 2, d=standoff_dia - 0.1, $fn=8);
    }

    // C. Internal Cavity (Sharp-edged)
    translate([0, gps_offset + (box_l/2), box_z_pos])
        rotate([-gps_angle, 0, 0]) {
            
            // 1. Main GPS Cavity
            translate([0, 0, -box_d_total/2 + 1.2 + nob_height + (gps_h+5)/2])
                cube([gps_w + 0.4, gps_l + 0.4, gps_h + 5], center=true);
            
            // 2. Floor relief
            translate([0,0, -box_d_total/2 + 1.2 + (nob_height+0.1)/2])
                cube([gps_w - 4, gps_l - 4, nob_height + 0.1], center=true);
            
            // 3. OFFSET WIRE WINDOW
            translate([wire_offset, -gps_l/2 - wall, -box_d_total/2 + 1.2 + nob_height + (wire_window_h/2)])
                cube([wire_width, wall * 4, wire_window_h], center=true);

            // 4. Zip-Tie Channel
            translate([0, 0, -box_d_total/2 + 1.2 - (zt_depth/2)])
                cube([box_w + 50, zt_width, zt_depth], center=true);
                
            // 5. Ejection Hole
            translate([0, 0, -50]) cylinder(h=100, d=10);
        }
}
