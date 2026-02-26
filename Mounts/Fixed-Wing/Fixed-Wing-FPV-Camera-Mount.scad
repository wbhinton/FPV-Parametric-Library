// =============================================================================
// PROJECT: PARAMETRIC FPV WING MOUNT
// VERSION: 1.8 
// DESCRIPTION: Restored trailing edge fairing with universal prism rotation.
//              Optimized for strength and laminar airflow.
// =============================================================================

/* [1. CAMERA DIMENSIONS] */
cam_w           = 19.0;  
cam_h           = 19.0;  
cam_d           = 18.0;  
m2_hole_dia     = 2.2;   
wall_thick      = 4.0;   

/* [2. BASE & POSITIONING] */
base_w          = 39.0;  
base_l          = 65.0;  // Lengthened for the fairing
base_thick      = 1.5;   
base_shift      = -10.0; 
mount_height    = 15.0; 
$fn = 80; 

/* [3. AERO FAIRING SETTINGS] */
// Distance from the axle to the tip of the tail
rear_reach      = 30.0; 
// Width of the very tip of the tail
tip_width       = 15.0;

/* [4. INTERNAL CALCULATIONS] */
corner_radius   = sqrt(pow(cam_d/2, 2) + pow(cam_h/2, 2)); 
safe_swing_r    = corner_radius + 0.8; 
inner_w         = cam_w + 2.0; 
total_width     = inner_w + (wall_thick * 2);

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP 1: THE SOLID BODY ---
    union() {
        // A. THE ELLIPTICAL FLEX-BASE
        scale([base_w/base_l, 1, 1])
            cylinder(h=base_thick, d=base_l, center=false);
        
        // B. THE AERO-PYLON (Shifts with base_shift)
        translate([0, base_shift, 0])
        hull() {
            // The Top Mounting Knuckle (Axle Area)
            translate([0, 0, mount_height])
                rotate([0, 90, 0])
                    cylinder(h=total_width, d=cam_h + 4, center=true);
            
            // Vertical Support Pillar
            translate([0, 0, mount_height/2])
                cube([total_width, cam_d, mount_height], center=true);

            // Trailing Edge Fairing (The "Tail")
            translate([0, rear_reach, 0])
                cylinder(h=base_thick, d=tip_width);
        }
    }

    // --- STEP 2: THE "PRISM-SWING" SUBTRACTION ---
    translate([0, base_shift, mount_height])
    rotate([0, 90, 0]) {
        
        // 1. THE MAIN CLEARANCE DRUM
        cylinder(h=inner_w, r=safe_swing_r, center=true);
        
        // 2. THE AXLE HOLE
        cylinder(h=total_width + 5, d=m2_hole_dia, center=true);
    }

    // --- STEP 3: DYNAMIC FLEX RELIEF SLOTS ---
    for(i = [-base_l/2 + 8 : 10 : base_l/2 - 8]) {
        // Only cut if it's outside the structural footprint of the pylon
        if (i < base_shift - 5 || i > base_shift + rear_reach - 5) {
            translate([0, i, -0.1])
                cube([base_w + 10, 1.6, base_thick + 0.2], center=true);
        }
    }
}