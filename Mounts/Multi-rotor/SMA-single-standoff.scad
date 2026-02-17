// =============================================================================
// PROJECT: OPTIMIZED SMA MOUNT
// VERSION: 1.9 (Educational / Library Edition)
// DESCRIPTION: A compact, high-strength SMA mount designed for TPU printing.
//              Features a "Hex-Lock" to keep the antenna pigtail from spinning.
// =============================================================================

/* [1. FRAME SETTINGS] */

// The diameter of your aluminum standoff.
standoff_dia    = 5.5;   

// The total height of the part that slides over the standoff.
sleeve_height   = 15.0;  

// Thickness of the TPU walls. 2.4mm is a "magic number" (6 walls @ 0.4mm nozzle).
wall_thickness  = 2.4; 

/* [2. ANTENNA ORIENTATION] */

// The "Twist" or Roll. 0 = Antenna points up, 90 = Antenna points sideways.
antenna_roll    = 45;    

// How far the center of the antenna sits from the center of the standoff.
offset_dist     = 15.0;  

/* [3. SMA HARDWARE SPECS] */

// The threaded part of the SMA pigtail.
sma_hole_dia    = 6.4;   

// The width of the metal nut (flat-to-flat).
sma_hex_size    = 6.6;   

// How deep the nut sits inside the TPU (standard is 4mm - 5mm).
sma_hex_depth   = 4.5;   

// The "ceiling" thickness above the nut that the antenna washer sits on.
ceiling_thick   = 3.0; 

/* [4. PRINT OPTIMIZATION] */

// Adds a tiny bit of extra room so hardware fits even with TPU shrinkage.
fit_tolerance   = 0.15; 

// The "Resolution" of your circles. 60 is a sweet spot for FPV parts.
$fn = 60;

/* [5. INTERNAL CALCULATIONS] */

// Total height of the antenna housing head.
housing_h = sma_hex_depth + ceiling_thick;

// Total outer diameter of the antenna housing.
sma_outer_dia = sma_hole_dia + (wall_thickness * 2);

// Finding the middle of the sleeve to center the arm.
mid_point = sleeve_height / 2;

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

// The 'difference' function tells OpenSCAD: "Take the first object and 
// subtract everything that follows from it."
difference() {
    
    // --- STEP 1: THE SOLID BODY ---
    // We 'union' (glue) these pieces together before cutting holes in them.
    union() {
        
        // A. The Standoff Sleeve (The anchor point)
        cylinder(h=sleeve_height, d=standoff_dia + (wall_thickness*2));
        
        // B. The Structural Bridge (The Stalk)
        translate([0, 0, mid_point]) {
            
            // 'hull' is like stretching a rubber band around two shapes.
            // It creates a smooth, tapered transition between them.
            hull() {
                
                // Shape 1: A tall, thin slice on the side of the sleeve.
                // This spreads the crash-stress across the whole sleeve.
                cube([standoff_dia + (wall_thickness*2), 0.1, sleeve_height * 0.8], center=true);
                
                // Shape 2: The tilted head where the antenna lives.
                translate([offset_dist, 0, 0])
                    rotate([antenna_roll, 0, 0])
                        cylinder(h=housing_h, d=sma_outer_dia, center=true);
            }
        }
    }

    // --- STEP 2: THE SUBTRACTIONS (Cutting the holes) ---
    
    // A. The Standoff Hole
    // We use $fn=8 to make an octagon. This creates 'tension points' that 
    // grip the standoff better than a perfect circle.
    translate([0, 0, -1])
        cylinder(h=sleeve_height + 2, d=standoff_dia - 0.1, $fn=8);

    // B. The SMA Machining
    // We move and rotate EXACTLY like we did in Step 1 to line up the holes.
    translate([offset_dist, 0, mid_point]) {
        rotate([antenna_roll, 0, 0]) {
            
            // 1. The Through-Hole (For the threaded barrel)
            // We make it extra long (+20) so it punches through both sides.
            cylinder(h=housing_h + 20, d=sma_hole_dia + fit_tolerance, center=true);
            
            // 2. The Hex Lock (The Nut Pocket)
            // $fn=6 makes a hexagon. This locks the nut so it won't spin.
            translate([0, 0, -housing_h/2 - 0.1]) 
                cylinder(h=sma_hex_depth + 0.1, d=(sma_hex_size + fit_tolerance) / cos(30), $fn=6);
            
            // 3. The Top Deck Leveler
            // This 'shaves' the top of the tilted head so the washer sits perfectly flat.
            translate([0, 0, housing_h/2])
                cylinder(h=2, d=sma_outer_dia + 2);
        }
    }
}