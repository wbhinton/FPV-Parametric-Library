// =============================================================================
// PROJECT: VIFLY UNIVERSAL C-BRACKET (OCTO-SLEEVE)
// VERSION: 1.5 (Octagonal Bore & Secured Floor)
// DESCRIPTION: Features an octagonal standoff hole for a superior TPU fit
//              and a solid bottom plate for buzzer security.
// =============================================================================

/* [1. STANDOFF SETTINGS] */
// Diameter of the standoff (Standard 5mm). Octagon shape handles the fit.
standoff_dia    = 5.1; 
wall_thick      = 1.6; 

/* [2. BUZZER DIMENSIONS] */
buz_w           = 11.5; 
buz_l           = 18.0; 
jaw_depth       = 11.0;  

/* [3. FEATURE SETTINGS] */
ziptie_w        = 3;
button_z_offset = 15.0; 
button_dia      = 6.5;

/* [4. INTERNAL CALCULATIONS] */
// $fn=8 creates the octagonal bore
$fn = 60;
total_h = buz_l + 2; 

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP 1: THE SOLID BODY ---
    union() {
        // A. The Standoff Sleeve (Outer remains round for aero)
        cylinder(h=total_h, d=standoff_dia + (wall_thick * 2));
        
        // B. The Dual Side Jaws
        for(y = [-1, 1]) {
            translate([standoff_dia/2 + jaw_depth/2 + wall_thick/2, y * (buz_w/2 + wall_thick/2), total_h/2])
                cube([jaw_depth + wall_thick, wall_thick, total_h], center=true);
        }
            
        // C. Structural Back-Plate
        translate([standoff_dia/2 + wall_thick/2, 0, total_h/2])
            cube([wall_thick, buz_w + wall_thick*2, total_h], center=true);

        // D. The Secured Floor
        translate([standoff_dia/2 + jaw_depth/2 + wall_thick/2, 0, wall_thick/2])
            cube([jaw_depth + wall_thick, buz_w + wall_thick*2, wall_thick], center=true);
    }

    // --- STEP 2: THE SUBTRACTIONS ---

    // A. THE OCTAGONAL STANDOFF BORE
    // We use $fn=8 here to create the internal ridges for better TPU fit.
    translate([0, 0, -1])
        rotate([0, 0, 22.5]) // Rotates octagon so flats face the buzzer
            cylinder(h=total_h + 2, d=standoff_dia / cos(180/8), $fn=8);

    // B. THE BUTTON WINDOW
    translate([standoff_dia/2 + jaw_depth, buz_w/2 + wall_thick/2, 2 + button_z_offset])
        rotate([90, 0, 0])
            cylinder(h=10, d=button_dia, center=true);

    // C. RETENTION ZIP-TIE TRENCH
    translate([0, 0, total_h/2 + 2])
        difference() {
            cylinder(h=ziptie_w, d=standoff_dia + jaw_depth * 4, center=true);
            cylinder(h=ziptie_w + 1, d=standoff_dia + (wall_thick * 0.75), center=true);
        }
}