// =============================================================================
// PROJECT: UNIVERSAL ELRS T-ANTENNA MOUNT
// VERSION: 6.5 (Master Library Edition)
// DESCRIPTION: Modular mount for T-style dipole antennas. Features a "revolving"
//              entrance that allows for 360-degree cable routing flexibility.
// =============================================================================

/* [1. USER EDITABLE PARAMETERS] */

// Thickness of the TPU skin. 2.4mm = exactly 6 walls with a 0.4mm nozzle.
wall_thickness  = 2.4;   

// Smoothness of circles. 60 provides high-quality prints without lag.
$fn = 60; 

// The outer diameter of your frame's aluminum standoff.
standoff_dia    = 6.34;   

// Total vertical height of the TPU mount.
sleeve_height   = 25.0;  

// 0 = Vertical (Up/Down), 1 = Horizontal (Left/Right).
antenna_orientation = 0; 

// REVOLUTION: Rotates the loading slit and cable exit around the cradle.
// 0 = Outward, 90 = Side, 180 = Toward Standoff.
slot_rotation_deg = 45; 

/* [2. ANTENNA HARDWARE SPECS] */

// Diameter of the thin flexible antenna wires.
wire_dia        = 2.4;   

// Diameter of the rigid plastic center junction (the "T").
junction_dia    = 4.8;   

// Length of the rigid center junction.
junction_width  = 6.5;   

// Total length of the cradle arm.
cradle_length   = 25.0;  

// Diameter of the coax cable leading to the receiver.
feedline_dia    = 2.6;   

/* [3. ZIP-TIE & PLACEMENT] */

// Width of the zip-tie channel.
ziptie_width    = 3.2;   

// Distance between the centers of the two zip-tie slots.
ziptie_spacing  = 14.0;   

// TPU "floor" thickness inside the zip-tie channel for antenna protection.
ziptie_floor    = 0.8;

// Distance (air gap) between the standoff and the antenna cradle.
plane_offset    = 4.5;   

/* [4. INTERNAL CALCULATIONS] */

total_offset = (standoff_dia/2) + wall_thickness + plane_offset;
rot_angle = (antenna_orientation == 1) ? 90 : 0;

// =============================================================================
// GEOMETRIC CONSTRAINTS (The "Safety Catch")
// =============================================================================

assert(sleeve_height >= cradle_length, 
    str("ERROR: sleeve_height (", sleeve_height, ") must be >= cradle_length"));

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP A: THE SOLID "CLAY" ---
    union() {
        // Create the sleeve that slides over the standoff.
        cylinder(h=sleeve_height, d=standoff_dia + (wall_thickness*2));
        
        // 'hull' creates a smooth, strong bridge between the sleeve and the cradle.
        hull() {
            translate([0, 0, sleeve_height/2])
                cube([standoff_dia + wall_thickness, 0.1, sleeve_height], center=true);
            
            translate([total_offset, 0, sleeve_height/2])
                rotate([rot_angle, 0, 0])
                    cylinder(h=cradle_length, d=junction_dia + (wall_thickness*2), center=true);
        }
    }

    // --- STEP B: THE "FINAL MACHINING" (Subtractions) ---
    
    // 1. The Standoff Hole. We use 8 sides (Octagon) for better TPU friction.
    translate([0, 0, -1])
        cylinder(h=sleeve_height + 2, d=standoff_dia - 0.1, $fn=8);

    // 2. THE ANTENNA CAVITY.
    // We move to the cradle's position and orient it (Vertical vs Horizontal).
    translate([total_offset, 0, sleeve_height/2])
        rotate([rot_angle, 0, 0]) {
            
            // STATIC BORES: These stay put because the dipole wires don't revolve.
            cylinder(h=cradle_length + 2, d=wire_dia, center=true); 
            cylinder(h=junction_width, d=junction_dia, center=true); 
            
            // REVOLVING FEATURES: These spin around the longitudinal (Z) axis.
            // This is the "Clockface" logic.
            rotate([0, 0, slot_rotation_deg]) {
                
                // The Snap-Fit Slit: The "Entry Door" for the antenna.
                translate([0, -wire_dia/2, -cradle_length/2 - 1])
                    cube([junction_dia + 10, wire_dia, cradle_length + 2]);
                    
                // The Feedline Exit: The "Tunnel" for the coax cable.
                rotate([0, 90, 0])
                    cylinder(h=junction_dia + 10, d=feedline_dia);
            }
        }

    // 3. THE ZIP-TIE CHANNELS.
    // These are placed symmetrically around the center T-junction.
    for(i=[-1, 1]) {
        translate([total_offset, 0, sleeve_height/2])
            rotate([rot_angle, 0, 0])
                translate([0, 0, i * (ziptie_spacing/2)])
                    difference() {
                        // The channel depth.
                        cylinder(h=ziptie_width, d=junction_dia + (wall_thickness*4), center=true);
                        // The inner core to prevent crushing the antenna.
                        cylinder(h=ziptie_width + 1, d=junction_dia + ziptie_floor, center=true);
                    }
    }
}