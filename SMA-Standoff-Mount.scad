// =============================================================================
// PROJECT: UNIVERSAL FPV SMA STANDOFF MOUNT
// VERSION: 4.0 (Final Parametric Library Version)
// DESCRIPTION: A support-free, TPU-optimized mount that slides over rear 
//              frame standoffs. Designed for SMA Bulkhead fittings.
// =============================================================================

/* [Frame Physical Dimensions] */
// Center-to-center distance between your rear standoffs (mm)
standoff_dist   = 20.0;  
// Diameter of your standoffs (Standard M3 is usually 5.0 to 5.5mm)
standoff_dia    = 5.0;   
// Height of standoffs (Distance between bottom and top plates)
standoff_height = 25.0;  
// Thickness of the TPU walls around the standoffs
wall_thickness  = 1.6;   
// Adjustment for fit (Negative values make the hole tighter for TPU "grip")
fit_tolerance   = 0.2;  

/* [Antenna Platform Settings] */
// Angle of the antenna tilted back from vertical (Degrees)
antenna_angle   = 25;    
// Distance from the front edge of the mount to the center of the SMA hole
platform_offset = 23.0;  
// Width of the rectangular mounting surface
platform_w      = 15.0;  
// Extra material behind the hole for crash durability (mm)
platform_padding = 8.0;  
// Thickness of the mounting plate (2.5mm is ideal for Bulkhead threads)
mounting_thick  = 2.5;   

/* [Hardware Specifications] */
// Diameter for the threaded SMA barrel (6.4mm - 6.6mm is standard)
sma_hole_dia    = 6.6;   
// Hex nut flat-to-flat size (8.0mm - 8.2mm is standard)
sma_hex_flat    = 8.2;   
// Thickness of the "Shoulder" that the nut presses against
shoulder_thick  = 1.25; 

/* [Internal Math - Do Not Change] */
$fn = 60; // Smoothness of circles
platform_l = platform_offset + platform_padding; // Total plate length

// =============================================================================
// RENDER LOGIC
// =============================================================================

difference() {
    // --- STEP 1: CREATE THE SOLID BODY ---
    union() {
        // Create the left and right standoff sleeves
        for(i=[-1, 1]) {
            translate([i * standoff_dist/2, 0, 0])
                cylinder(h=standoff_height, d=standoff_dia + (wall_thickness*2));
        }

        // Create the Mounting Platform (Angled Rectangle)
        // Positioned flush at (0,0,standoff_height)
        translate([0, 0, standoff_height]) 
            rotate([-antenna_angle, 0, 0])
                translate([-platform_w/2, 0, -mounting_thick]) 
                    cube([platform_w, platform_l, mounting_thick]);

        // Create the Structural Rib Trusses (Reinforcing Ramps)
        for(i=[-1, 1]) {
            hull() {
                // Top Anchor: Locked to the side face of the angled plate
                translate([0, 0, standoff_height]) 
                    rotate([-antenna_angle, 0, 0])
                        translate([i * (platform_w/2 - 1.25), platform_l/2, -mounting_thick/2])
                            cube([2.5, platform_l, mounting_thick], center=true);
                
                // Bottom Anchor: Flared base at the bottom of the sleeve
                translate([i * standoff_dist/2, 0, 0])
                    cylinder(h=1, d=standoff_dia + (wall_thickness*2));
            }
        }
    }

    // --- STEP 2: CARVE THE HOLES ---
    
    // Standoff Holes (Rendered as Octagons for better TPU friction/grip)
    for(i=[-1, 1]) {
        translate([i * standoff_dist/2, 0, -1])
            cylinder(h=standoff_height + 2, d=standoff_dia + fit_tolerance, $fn=8);
    }
    
    // The SMA Connector Stack (Hole + Hex Socket)
    translate([0, 0, standoff_height])
        rotate([-antenna_angle, 0, 0])
            translate([0, platform_offset, 0]) {
                
                // 1. Thread Path: Small hole going completely through the plate
                translate([0, 0, -50])
                    cylinder(h=55, d=sma_hole_dia);
                
                // 2. Hex Trap: Large 6-sided socket for the bulkhead base
                // Calculated to leave exactly 'shoulder_thick' of material on top
                translate([0, 0, -50]) 
                    cylinder(h=50 - shoulder_thick, d=sma_hex_flat / cos(30), $fn=6);
            }
}