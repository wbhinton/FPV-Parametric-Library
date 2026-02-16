// =============================================================================
// PROJECT: FIXED-WING "HIGH-PINCH" TOWER 
// VERSION: 1.7 (Elevated Pinch & Reinforced Trailing Edge)
// DESCRIPTION: Zip-tie slot moved toward the top of the mast to maximize 
//              clamping force on the SMA connector barrel.
// =============================================================================

/* [1. BASE PLATE SETTINGS] */
base_w          = 35.0;  
base_l          = 60.0;  
base_thick      = 1.2;   
slot_width      = 1.6;   

/* [2. TOWER GEOMETRY] */
tower_h         = 25.0;  
sma_hole_dia    = 6.5;   
cable_slot_w    = 3.5;
wall_thickness  = 4.0;   
leading_edge_dist = 22.0; 

/* [3. RETENTION (The High Pinch)] */
ziptie_width    = 3.8;
ziptie_thick    = 1.8;
// REDUCED DROP: Clamps higher up for more stability (mm from top)
ziptie_drop     = 5.0; 
// Keeps the slot in the "meat" of the tower
ziptie_forward_shift = 0.5;

/* [4. INTERNAL CALCULATIONS] */
$fn = 60;
tower_dia = sma_hole_dia + (wall_thickness * 2);

// CALCULATE THE ANGLE: 
// Matches the slant of the rear spine.
spine_run   = (tower_dia * 1.5) - (tower_dia / 2);
spine_angle = atan2(spine_run, tower_h);

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    // --- STEP 1: THE SOLID BODY ---
    union() {
        // A. The Flexible Base Plate
        translate([0, 0, base_thick/2])
            cube([base_w, base_l, base_thick], center=true);
        
        // B. The Aero-Tower
        hull() {
            cylinder(h=tower_h + base_thick, d=tower_dia);
            
            // Leading Edge (Sharp entry)
            translate([0, -leading_edge_dist, 0])
                cylinder(h=base_thick, d=1.5); 
            
            // Trailing Spine (Tapered exit)
            translate([0, tower_dia * 1.5, 0])
                cylinder(h=base_thick, d=tower_dia);

            // Base Reinforcement
            translate([0, 0, base_thick])
                cube([tower_dia + 4, tower_dia + 4, 0.1], center=true);
        }
    }

    // --- STEP 2: THE SUBTRACTIONS ---

    // A. FLEX RELIEF SLOTS
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.1])
            cube([base_w + 2, slot_width, base_thick + 0.1], center=true);
    }

    // B. THE SMA BORE
    translate([0, 0, -1])
        cylinder(h=tower_h + base_thick + 5, d=sma_hole_dia);

    // C. THE REAR LOADING SLOT
    translate([0, tower_dia, (tower_h + base_thick)/2])
        cube([cable_slot_w, tower_dia * 2, tower_h + base_thick + 10], center=true);

    // D. THE HIGH-POSITIONED ZIP-TIE TRENCH
    // Tilted to match the spine but elevated for better leverage.
    translate([0, (tower_dia/2) + ziptie_forward_shift, tower_h + base_thick - ziptie_drop])
        rotate([spine_angle, 0, 0]) 
            cube([tower_dia + 10, ziptie_thick, ziptie_width], center=true);

    // E. BOTTOM CABLE PORT
    translate([0, 0, -1])
        cylinder(h=base_thick + 5, d=sma_hole_dia);
}