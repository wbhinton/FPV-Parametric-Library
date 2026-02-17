// =============================================================================
// PROJECT: FIXED-WING OMNI-AERO ELRS MOUNT
// VERSION: 1.2 (4-Way Chamfer & Educational Comments)
// DESCRIPTION: A glue-on horizontal mount with all-around aerodynamic 
//              smoothing and recessed channels for ELRS antennas.
// =============================================================================

/* [1. BASE PLATE SETTINGS] */

// Total footprint width
base_w          = 32.0;  
// Total footprint length
base_l          = 48.0;  
// The flexible "hinge" layer (gluing surface)
base_thick      = 1.2;   
// The padded block that holds the antenna
pad_thick       = 4.5;   
// Relief cuts that allow the TPU to curve around a wing
slot_width      = 1.6;   

/* [2. ANTENNA HARDWARE SPECS] */

wire_dia        = 2.6;   
junction_dia    = 5.2;   
junction_l      = 7.5;   
feedline_dia    = 3.0;   
total_span      = 36.0;  

/* [3. RETENTION & AERO] */

ziptie_width    = 3.5;   
ziptie_thick    = 1.8; 
// Moves the zip-tie back to clamp the coax, not the dipoles
ziptie_offset   = 6.0;  
// Size of the aerodynamic ramps on all sides
aero_chamfer    = 3.0;

/* [4. INTERNAL CALCULATIONS] */

$fn = 60;
total_h = base_thick + pad_thick;

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP 1: THE SOLID BODY ---
    union() {
        // We start with a rounded block using the 'hull' of four cylinders.
        hull() {
            for(x=[-1,1], y=[-1,1]) {
                translate([x * (base_w/2 - 2), y * (base_l/2 - 2), 0])
                    cylinder(h=total_h, r=2);
            }
        }
    }

    // --- STEP 2: THE SUBTRACTIONS (The "Machining" Phase) ---

    // A. OMNI-DIRECTIONAL CHAMFERING
    // This 'for' loop rotates a cutting cube to shave all four edges.
    for(angle=[0, 90, 180, 270]) rotate([0, 0, angle]) {
        // We pick the distance based on whether we are cutting the side or end
        dist = (angle == 0 || angle == 180) ? base_l/2 : base_w/2;
        
        translate([0, dist, total_h])
            rotate([45, 0, 0])
                cube([max(base_w, base_l) + 10, aero_chamfer * 2, aero_chamfer * 2], center=true);
    }

    // B. FLEX RELIEF SLOTS (The "Tank Tread")
    // These only cut through the bottom 1.2mm membrane.
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.1])
            cube([base_w + 2, slot_width, base_thick + 0.1], center=true);
    }

    // C. THE ANTENNA CHANNELS (Milled into the top)
    translate([0, 0, total_h]) {
        
        // 1. Dipole Arms (Horizontal Bar)
        rotate([0, 90, 0])
            cylinder(h=total_span, d=wire_dia, center=true);
            
        // 2. T-Junction (The Center Node)
        rotate([0, 90, 0])
            cylinder(h=junction_l, d=junction_dia, center=true);
            
        // 3. Feedline Channel (The Tail)
        translate([0, base_l/4, 0])
            rotate([90, 0, 0])
                cylinder(h=base_l/2 + 2, d=feedline_dia, center=true);
                
        // 4. Snap-Fit Entry Slots (Top Access)
        cube([total_span, wire_dia, wire_dia * 3], center=true);
        cube([junction_l, junction_dia, junction_dia * 3], center=true);
        translate([0, base_l/4, 0])
            cube([feedline_dia, base_l/2, feedline_dia * 3], center=true);
    }

    // D. OFFSET ZIP-TIE TRENCH
    // This is carved into the 'floor' of the channels.
    translate([0, ziptie_offset, total_h - feedline_dia - ziptie_thick/2])
        cube([base_w + 2, ziptie_width, ziptie_thick], center=true);
}