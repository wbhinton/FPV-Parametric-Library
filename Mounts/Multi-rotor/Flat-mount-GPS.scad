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
// ============================================================
// PROJECT: FPV COMPONENT LIBRARY - GPS MOUNT
// COMPONENT: HGLRC M100-5883 (21x21x8.02mm)
// VERSION: 2.2 (Refactored Chamfer + Full Documentation)
// ============================================================

// --- USER ADJUSTABLE SETTINGS ---
hole_spacing    = 20;    // Distance between centers of frame screws (Standard: 20-30mm)
hole_dia        = 3.4;   // Screw hole size (3.4mm gives a snug fit for M3 in TPU)
base_thickness  = 2;   // Thickness of the mounting plate
base_width      = 12.0;  // Diameter of the circular pads around the screws
corner_radius   = 2.0;   // Curvature of the corners (higher is smoother/stronger)

// --- GPS UNIT DIMENSIONS ---
gps_w = 21;              // Width of the GPS unit
gps_l = 21;              // Length of the GPS unit
gps_h = 8.0;            // Height of the GPS unit
wall  = 1.6;             // Wall thickness (1.6mm = 4 perimeters with 0.4mm nozzle)

// --- UTILITY & CLEARANCE SETTINGS ---
zt_width     = 3.5;      // Width of the zip-tie channel
zt_depth     = 1.5;      // Depth the zip-tie sits below the GPS floor
wire_width   = 12;      // Width of the opening for the GPS wires
wire_offset  = -4.5;      // Shift the wire exit right (+) or left (-) to match pads
nob_height   = 1.2;      // Height of internal corner pillars (creates magnetic air gap)
chamfer_size = 2.0;      // Vertical and horizontal size of the base reinforcement

// Dynamic calculation to ensure GPS box doesn't overlap screw heads
gps_offset_y = (base_width/2) + (gps_l/2) + wall + 2; 

$fn = 60;                // Smoothness of curves (60 is high quality)

// --- THE MASTER DIFFERENCE ---
// In OpenSCAD, 'difference' subtracts everything below the first object.
difference() {
    
    // STEP 1: ADD ALL SOLID GEOMETRY (What we want to print)
    union() {
        // Create the flat mounting footprint
        unified_base_solid();
        
        // Add the vertical GPS box structure (lowered slightly to fuse with base)
        translate([hole_spacing/2, gps_offset_y, base_thickness - 0.1])
            gps_outer_shell_solid();
            
        // Add the four internal corner pillars (Nobs)
        // These stay even after the cavity is cut out
        translate([hole_spacing/2, gps_offset_y, base_thickness - 0.1])
            for(x=[-1,1], y=[-1,1])
                translate([x*(gps_w/2 - 2), y*(gps_l/2 - 2), 0])
                    cylinder(h=nob_height + 0.1, d=3);
    }

    // STEP 2: SUBTRACT THE INTERNAL VOIDS (The "Holes")
    
    // Main GPS cavity (starts at the top of the pillars)
    translate([hole_spacing/2, gps_offset_y, base_thickness + nob_height])
        rounded_rect(gps_w + 0.4, gps_l + 0.4, gps_h + 5);
    
    // Floor relief (clears center space between pillars so zip-tie fits)
    translate([hole_spacing/2, gps_offset_y, base_thickness])
        rounded_rect(gps_w - 4, gps_l - 4, nob_height + 0.1);

    // Ejection hole (lets you push the GPS out from the bottom with a tool)
    translate([hole_spacing/2, gps_offset_y, -1])
        cylinder(h=base_thickness + 2, d=10);

    // Wire exit slot (extended forward to clear the chamfer flared base)
    translate([hole_spacing/2 + wire_offset - (wire_width/2), gps_offset_y - (gps_l/2) - wall - 5, base_thickness])
        cube([wire_width, wall + 10, gps_h + 1]);

    // STEP 3: FINAL HARDWARE CUTS (Screws and Zip-Ties)
    
    // Screw holes for frame attachment
    translate([0, 0, -1]) cylinder(h=base_thickness + 2, d=hole_dia);
    translate([hole_spacing, 0, -1]) cylinder(h=base_thickness + 2, d=hole_dia);

    // Zip-tie Channel (Trough in floor and windows in walls combined)
    // We use a double-depth cut to ensure no surface artifacts remain
    translate([hole_spacing/2, gps_offset_y, base_thickness + (zt_depth/2) - zt_depth])
        cube([gps_w + (wall*2) + 10, zt_width, zt_depth * 2], center=true);
}

// --- MODULES (The Building Blocks) ---

module unified_base_solid() {
    // Connects the screw pads and the GPS footprint into one solid slab.
    // We include the chamfer_size in the footprint so the base supports the flare.
    hull() {
        translate([0, 0, 0]) cylinder(h=base_thickness, d=base_width);
        translate([hole_spacing, 0, 0]) cylinder(h=base_thickness, d=base_width);
        translate([hole_spacing/2, gps_offset_y, 0])
            rounded_rect(gps_w + (wall*2) + (chamfer_size*2), gps_l + (wall*2) + (chamfer_size*2), base_thickness);
    }
}

module gps_outer_shell_solid() {
    // Generates the vertical box with a clean 45-degree chamfer at the bottom.
    // 'hull' between two sizes creates a mathematically perfect slanted surface.
    hull() {
        // Wide footprint at the very bottom
        rounded_rect(gps_w + (wall*2) + (chamfer_size*2), gps_l + (wall*2) + (chamfer_size*2), 0.1);
        
        // Target wall thickness at the top of the chamfer height
        translate([0, 0, chamfer_size])
            rounded_rect(gps_w + (wall*2), gps_l + (wall*2), 0.1);
    }
    // Main vertical wall volume extending to full height
    rounded_rect(gps_w + (wall*2), gps_l + (wall*2), gps_h);
}

module rounded_rect(w, l, h) {
    // Helper tool to create boxes with smooth corners using 'hull' on 4 cylinders.
    hull() {
        for(x=[-1,1], y=[-1,1])
            translate([x*(w/2 - corner_radius), y*(l/2 - corner_radius), 0])
                cylinder(h=h, r=corner_radius);
    }
}
