// =============================================================================
// PROJECT: PARAMETRIC TPU FPV CAMERA LENS CAP
// LICENSE: Creative Commons Zero (CC0) / Public Domain
// DESCRIPTION: Flexible lens protector for micro/nano FPV cameras (RunCam, 
//              Caddx, DJI O3, Walksnail, Foxeer). Optimized for TPU perimeters.
//              Oriented with cavity facing upward for clean, support-free prints.
// =============================================================================

/* [Camera Lens Dimensions] */
// Outer diameter of the lens barrel at its widest point (in mm)
lens_diameter       = 14.0; // [8.0:0.1:25.0]

// Depth/height of the lens barrel to cover (in mm)
lens_depth          = 6.5;  // [3.0:0.1:20.0]

// Fit adjustment: 0.0 for exact, negative for stretch-fit (TPU stretches ~0.1 - 0.2mm)
fit_tolerance       = -0.05; 

/* [Slicer & Wall Multipliers] */
// Printer nozzle diameter in mm
nozzle_diameter     = 0.6;  // [0.2, 0.4, 0.6, 0.8]

// Wall thickness as an exact integer count of nozzle extrusion passes
wall_perimeters     = 2;    // [1:1:6]

// Base cap thickness as an exact integer count of nozzle extrusion passes
cap_perimeters      = 3;    // [2:1:8]

// Layer height for print slices (in mm)
layer_height        = 0.24; // [0.12, 0.16, 0.20, 0.24, 0.28, 0.3]

/* [Features & Usability] */
// Add an internal air-relief / anti-suction notch
add_air_relief_vent = true;

// Slight internal taper angle (degrees) to wedge snugly without slipping off
taper_angle         = 1.0; 

/* [Hidden Calculations] */
$fn = 96;
overlap = 0.05;

// Extrusion math: standard slicers extrude lines ~1.125x nozzle diameter
extrusion_width   = nozzle_diameter * 1.125;
wall_thickness    = extrusion_width * wall_perimeters;
cap_thickness     = max(extrusion_width * cap_perimeters, layer_height * 4);

// Target internal bore dimensions
// Top mouth is wide; bottom floor is slightly tapered for snug retention
bore_top_dia      = lens_diameter + fit_tolerance;
bore_top_radius   = bore_top_dia / 2;

taper_delta       = lens_depth * tan(taper_angle);
bore_bottom_radius = max(bore_top_radius - taper_delta, bore_top_radius * 0.95);

// Outer dimensions (matching taper from base to rim)
outer_bottom_radius = bore_bottom_radius + wall_thickness;
outer_top_radius    = bore_top_radius + wall_thickness;
total_height        = lens_depth + cap_thickness;

// =============================================================================
// CONSOLE READOUT
// =============================================================================
echo("=== TPU LENS CAP SPECIFICATIONS ===");
echo(STR_BORE_DIAMETER     = bore_top_dia, "mm");
echo(STR_WALL_THICKNESS    = wall_thickness, "mm (", wall_perimeters, "perimeters )");
echo(STR_CAP_BASE_THICK    = cap_thickness, "mm");
echo(STR_TOTAL_HEIGHT      = total_height, "mm");
echo("===================================");

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================
render_lens_cap();

module render_lens_cap() {
    difference() {
        // 1. SOLID POSITIVE BODY (Flat closed end resting on build plate at Z=0)
        cylinder(h = total_height, r1 = outer_bottom_radius, r2 = outer_top_radius);

        // 2. INTERNAL LENS CAVITY (Bore open to the top)
        translate([0, 0, cap_thickness])
            cylinder(h = lens_depth + overlap, r1 = bore_bottom_radius, r2 = bore_top_radius);

        // 3. INTERNAL AIR RELIEF GROOVES (Prevents vacuum lock during removal)
        if (add_air_relief_vent) {
            for (angle = [0, 180]) {
                rotate([0, 0, angle])
                    translate([bore_bottom_radius - 0.4, -0.6, cap_thickness])
                        cube([0.8, 1.2, lens_depth + overlap]);
            }
        }

        // 4. ENTRANCE LEAD-IN CHAMFER (At the top mouth for easy push-on fit)
        translate([0, 0, total_height - 0.8 + overlap])
            cylinder(h = 0.8 + overlap, r1 = bore_top_radius, r2 = bore_top_radius + 0.6, $fn = 96);
    }
}