// =============================================================================
// PROJECT: UNIVERSAL "AERO-GOPRO" ELLIPSE MOUNT
// VERSION: 2.3 (Flex-Slots Restored)
// DESCRIPTION: Re-added the tank-tread flex relief slots to allow the wide 
//              base to conform to curved surfaces.
// =============================================================================

/* [1. HARDWARE SCALING] */
bolt_dia        = 3.0;   
tab_wall_thickness = 4.0; 
nut_dia         = 5.5;   
nut_depth       = 2.0;   

/* [2. BASE & PRONG SETTINGS] */
base_w          = 35.0;  
base_l          = 55.0;  
base_thick      = 1.2;   
tab_thick       = 3.0;   
tab_gap         = 3.2;   
mount_height    = 13.0;  
ramp_reach      = 18.0; 
// Width of the flex cuts
slot_width      = 1.6;
// Distance between flex cuts
slot_pitch      = 9.0;
$fn = 80; 

/* [3. INTERNAL CALCULATIONS] */
tab_outer_dia   = bolt_dia + (tab_wall_thickness * 1.5); 
total_tab_width = (tab_thick * 3) + (tab_gap * 2);

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP 1: THE SOLID BODY ---
    union() {
        // A. THE ELLIPTICAL BASE
        scale([base_w/base_l, 1, 1])
            cylinder(h=base_thick, d=base_l, center=false);
        
        // B. THE SYMMETRICAL WIDE PYLON
        hull() {
            translate([0, -ramp_reach, 0])
                cylinder(h=base_thick, d=total_tab_width*1); 
            
            translate([0, ramp_reach, 0])
                cylinder(h=base_thick, d=total_tab_width*1);

            translate([0, 0, mount_height])
                rotate([0, 90, 0])
                    cylinder(h=total_tab_width, d=tab_outer_dia, center=true);
        }
    }

    // --- STEP 2: THE SUBTRACTIONS ---

    // A. BOLT HOLE
    translate([0, 0, mount_height])
        rotate([0, 90, 0])
            cylinder(h=total_tab_width + 10, d=bolt_dia, center=true);

    // B. NUT TRAP
    translate([total_tab_width/2 - nut_depth + 0.1, 0, mount_height])
        rotate([0, 90, 0])
            cylinder(h=nut_depth + 1, d=nut_dia / cos(30), $fn=6);

    // C. FULL-DEPTH PRONG GAPS
    for(x = [-1, 1]) {
        translate([x * (tab_thick/2 + tab_gap/2), 0, mount_height + 0.5])
            cube([tab_gap, ramp_reach * 2.5, tab_outer_dia + 1.0], center=true);
    }

    // D. FLEX RELIEF SLOTS (The 'Tank Tread')
    // Logic: Cuts across the Y-axis to allow the X-axis to bend.
    for(i = [-base_l/2 + 6 : slot_pitch : base_l/2 - 6]) {
        translate([0, i, -0.1])
            cube([base_w + 10, slot_width, base_thick + 0.2], center=true);
    }
}