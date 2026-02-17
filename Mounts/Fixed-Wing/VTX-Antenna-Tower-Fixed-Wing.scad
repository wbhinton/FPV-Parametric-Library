// =============================================================================
// PROJECT: FIXED-WING "HIGH-PINCH" TOWER 
// VERSION: 1.9.1 (Subtractive Bottom Treads)
// DESCRIPTION: Slots are now moved to the main difference block for 
//              guaranteed rendering on the bottom face.
// =============================================================================

/* [1. BASE PLATE SETTINGS] */
base_w          = 35.0;  
base_l          = 55.0;  
base_thick      = 1.2;   
slot_width      = 1.6;   
slot_depth      = 0.6; // 50% depth is ideal for flexibility

/* [2. TOWER GEOMETRY] */
tower_h         = 20.0;  
sma_hole_dia    = 8;   
cable_slot_w    = 3.5;
wall_thickness  = 2.0;   
leading_edge_dist = 24.0; 

/* [3. RETENTION] */
ziptie_width    = 3.;
ziptie_thick    = 1.;
ziptie_drop     = 5.0; 
ziptie_forward_shift = 0.5;

/* [4. INTERNAL CALCULATIONS] */
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
        // A. THE ELLIPTICAL BASE PLATE
        scale([base_w / base_l, 1, 1])
            cylinder(h=base_thick, d=base_l);
        
        // B. THE AERO-TOWER
        hull() {
            cylinder(h=tower_h + base_thick, d=tower_dia);
            
            // Leading Edge
            translate([0, -leading_edge_dist, 0])
                cylinder(h=base_thick, d=1.5); 
            
            // Trailing Spine
            translate([0, tower_dia * 1.5, 0])
                cylinder(h=base_thick, d=tower_dia);

            // Base Reinforcement
            translate([0, 0, base_thick])
                cube([tower_dia + 4, tower_dia + 4, 0.1], center=true);
        }
    }

    // --- STEP 2: THE SUBTRACTIONS (Now all in one block) ---

    // A. BOTTOM-FACE FLEX RELIEF SLOTS
    // Moved here to ensure they are subtracted from the unioned body
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.05]) // Slight offset into the "ground"
            cube([base_w + 5, slot_width, slot_depth + 0.1], center=true);
    }

    // B. THE SMA BORE
    translate([0, 0, -1])
        cylinder(h=tower_h + base_thick + 5, d=sma_hole_dia);

    // C. THE REAR LOADING SLOT
    translate([0, tower_dia, (tower_h + base_thick)/2])
        cube([cable_slot_w, tower_dia * 2, tower_h + base_thick + 10], center=true);

    // D. THE HIGH-POSITIONED ZIP-TIE TRENCH
    translate([0, (tower_dia/2) + ziptie_forward_shift, tower_h + base_thick - ziptie_drop])
        rotate([spine_angle, 0, 0]) 
            cube([tower_dia + 10, ziptie_thick, ziptie_width], center=true);

    // E. BOTTOM CABLE PORT
    translate([0, 0, -1])
        cylinder(h=base_thick + 5, d=sma_hole_dia);
}