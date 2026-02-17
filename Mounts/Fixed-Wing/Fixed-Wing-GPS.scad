// =============================================================================
// PROJECT: FLEXIBLE FIXED-WING GPS MOUNT
// VERSION: 1.1 (Educational / Conformal Base)
// DESCRIPTION: A glue-on mount featuring a "lattice" base to wrap around 
//              fuselages and a "faired" profile to reduce drag.
// =============================================================================

/* [1. BASE PLATE SETTINGS] */

// The width of the glue footprint.
base_w          = 35.0;  

// The length of the glue footprint.
base_l          = 45.0;  

// 1.2mm is the "Sweet Spot" for flexibility—thick enough to hold, thin enough to bend.
base_thick      = 1.2;   

// The width of the relief cuts that allow the TPU to curve.
slot_width      = 1.5;   

/* [2. GPS COMPARTMENT SETTINGS] */

// 0 = Flat. If your wing is angled, you can tilt the box to keep the GPS level.
gps_angle       = 0;     

gps_w           = 20.2;  
gps_l           = 22.2;  
gps_d           = 6.0;   
wall_thickness  = 2.0;   

/* [3. HARDWARE & RETENTION] */

ziptie_width    = 3.5;   
ziptie_thick    = 1.6; 

// The portal where the wires enter the box from the back.
wire_window_w   = 10.0;
wire_window_h   = 3.5;

// The diameter of the hole in the bottom (useful for poking the GPS out).
wire_hole_dia   = 5.0;   

/* [4. INTERNAL CALCULATIONS] */

$fn = 60;
box_w = gps_w + (wall_thickness * 2);
box_l = gps_l + (wall_thickness * 2);
box_d = gps_d + 1.2; // 1.2mm floor thickness

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP 1: THE SOLID BODY ---
    union() {
        
        // A. The Flexible Base Plate
        // This is the "sticker" that gets glued to the foam.
        translate([0, 0, base_thick/2])
            cube([base_w, base_l, base_thick], center=true);
        
        // B. The Aerodynamic Fairing
        // We use 'hull' to blend the base into the GPS box.
        // This prevents sharp edges that cause air turbulence (drag).
        hull() {
            // Anchor 1: A thin slice sitting on the base.
            translate([0, 0, base_thick])
                cube([box_w + 10, box_l + 10, 0.1], center=true);
            
            // Anchor 2: The actual GPS housing box.
            translate([0, 0, box_d/2 + base_thick + 2])
                rotate([-gps_angle, 0, 0])
                    cube([box_w, box_l, box_d], center=true);
        }
    }

    // --- STEP 2: THE SUBTRACTIONS (The "Milling" Phase) ---

    // A. FLEX RELIEF SLOTS
    // We use a 'for' loop to repeat the cuts every 8mm.
    // This turns a stiff plate into a flexible "tank tread" design.
    for(i = [-base_l/2 + 5 : 8 : base_l/2 - 5]) {
        translate([0, i, -1])
            cube([base_w + 2, slot_width, base_thick + 2], center=true);
    }

    // B. Internal Cavity Group (Everything here is relative to the GPS box)
    translate([0, 0, box_d/2 + base_thick + 2])
        rotate([-gps_angle, 0, 0]) {
                
            // 1. The main cavity for the GPS module.
            translate([0, 0, (box_d/2 - gps_d/2) + 0.1])
                cube([gps_w, gps_l, gps_d + 0.2], center=true);
            
            // 2. The Zip-Tie Trench.
            // This allows the zip-tie to go UNDER the GPS so it stays flush.
            translate([0, 0, -gps_d/2 - (ziptie_thick/2)])
                cube([box_w + 50, ziptie_width, ziptie_thick], center=true);

            // 3. The Rear Wire Window.
            // Where the wires enter the back of the box.
            translate([0, -gps_l/2, -gps_d/2 + (wire_window_h/2)])
                cube([wire_window_w, wall_thickness * 6, wire_window_h], center=true);
            
            // 4. The Center Push-out Port.
            // A long vertical drill that goes through the floor and the base.
            translate([0, 0, -50])
                cylinder(h=100, d=wire_hole_dia);
        }
}