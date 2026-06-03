// =============================================================================
// PROJECT: WH-SERVO-INTERFACE - v1.6
// LICENSE: Creative Commons Zero (CC0) / Public Domain
// AUTHOR: Weston Hinton (2026)
// DESCRIPTION: Servo horn engine featuring adjustable bottom floor thickness
//              to control exactly how deep the retaining screw seats into the shaft.
// =============================================================================
/* =============================================================================
   SPLINE REFERENCE CHART (Use these values to populate parameters below)
   =============================================================================
   SERVO TYPE / PRESET             | TEETH (T) | OUTER DIA (mm) | CAVITY DEPTH (mm)
   --------------------------------+-----------+----------------+------------------
   EMAX ES08MA II / ES08MD II      |    15     |      4.0       |       3.75
   Futaba Standard (MKS, Savox)    |    25     |      5.92      |       4.0
   Futaba Micro (1F Spec)          |    15     |      4.0       |       3.75
   Futaba Mini (2F Spec)           |    21     |      4.5       |       4.0
   Hitec Standard (C1 Spec)        |    24     |      5.76      |       4.0
   Hitec Sub-Micro (A1 Spec)       |    15     |      3.9       |       3.2
   Standard SG90 9g (Clone)        |    21     |      4.9       |       3.2
   TowerPro SG90 9g (Genuine)      |    21     |      4.7       |       3.2
   =============================================================================
*/

/* [1. Horn Style Options] */
// 1: Spoke Arms (uses 'arm_count'), 2: Full Circular Disc
horn_style       = 1;     
// Number of arms to generate (1 to 4) - Only used if horn_style is 1
arm_count        = 1;     

/* [2. Linkage Variables] */
horn_length      = 14.0;  // Center of spline to furthest attachment hole (or Disc Radius)
horn_thickness   = 2.1;   // Thickness of the output arms/disc
hole_spacing     = 4.0;   // Distance between linkage holes
hole_diameter    = 2.5;   // Diameter for clevis/pushrod pins

/* [3. FDM Optimization] */
// Minimum material thickness around the linkage holes (radial padding)
hole_padding     = 2.6;   // Increase for higher structural strength

/* [4. Spline Interface Configuration] */
spline_teeth        = 15;    // Number of teeth 
spline_outer_dia    = 4.0;   // Major (outer) diameter of output shaft
spline_depth        = 3.75;  // Total depth of engagement cavity
retaining_screw_dia = 2.2;   // Center screw hole diameter
fit_tolerance       = 0.15;  // Material compensation (0.15 - 0.20 for PETG-CF)

/* [5. Fastener Engagement Control] */
// Thickness of solid plastic between the bottom bed surface and start of splines
screw_floor_thickness = 1.0;  // Lower this value to give your screw more thread reach!

/* [Hidden Internal Geometry] */
$fn = 100;
overlap = 0.05; 

r_outer = (spline_outer_dia / 2) + fit_tolerance;
r_inner = r_outer - 0.3; 

tip_diameter = hole_diameter + (hole_padding * 2);
hub_dia = spline_outer_dia + 4.5; 

// Hub height is now dynamically driven by the desired floor thickness
hub_height = spline_depth + screw_floor_thickness;

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    // 1. SOLID COMPOSITE BODY
    union() {
        // Spline Hub Collar Base
        cylinder(h = hub_height, d = hub_dia);
        
        // Output Geometry Selection
        if (horn_style == 2) {
            // STYLE 2: FULL CONTROL DISC
            cylinder(h = horn_thickness, r = horn_length + hole_padding);
        } else {
            // STYLE 1: MULTI-SPOKE RADIATING ARMS
            if (arm_count > 0 && arm_count <= 4) {
                for (arm = [0 : arm_count - 1]) {
                    rotate([0, 0, arm * (360 / arm_count)]) {
                        hull() {
                            cylinder(h = horn_thickness, d = hub_dia);
                            translate([horn_length, 0, 0])
                                cylinder(h = horn_thickness, d = tip_diameter);
                        }
                    }
                }
            }
        }
    }

    // 2. THE SUBTRACTIVE SPLINE SHAFT
    // Shifts dynamically based on the calculated hub height
    translate([0, 0, hub_height - spline_depth]) {
        linear_extrude(height = spline_depth + overlap) {
            star_polygon(num_teeth = spline_teeth, r1 = r_outer, r2 = r_inner);
        }
    }

    // 3. MAIN CENTER RETAINING SCREW HOLE
    translate([0, 0, -overlap])
        cylinder(h = hub_height + 2*overlap, d = retaining_screw_dia);

    // 4. LINKAGE HOLE ARRAY SUBTRACTION
    if (horn_style == 2) {
        for (rot_angle = [0, 90, 180, 270]) {
            rotate([0, 0, rot_angle]) {
                for (dist = [horn_length : -hole_spacing : hub_dia/2 + hole_padding]) {
                    translate([dist, 0, -overlap])
                        cylinder(h = horn_thickness + 2*overlap, d = hole_diameter);
                }
            }
        }
    } else {
        if (arm_count > 0 && arm_count <= 4) {
            for (arm = [0 : arm_count - 1]) {
                rotate([0, 0, arm * (360 / arm_count)]) {
                    for (dist = [horn_length : -hole_spacing : hub_dia/2 + hole_padding]) {
                        translate([dist, 0, -overlap])
                            cylinder(h = horn_thickness + 2*overlap, d = hole_diameter);
                    }
                }
            }
        }
    }
}

// =============================================================================
// MATHEMATICAL CORE MODULES
// =============================================================================

module star_polygon(num_teeth, r1, r2) {
    count = num_teeth * 2;
    step  = 360 / count;
    
    points = [
        for (i = [0 : count - 1]) 
            let(
                r = (i % 2 == 0) ? r1 : r2,
                angle = i * step
            )
            [ r * cos(angle), r * sin(angle) ]
    ];
    
    polygon(points);
}