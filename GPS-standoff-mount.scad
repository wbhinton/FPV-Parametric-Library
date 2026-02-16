// =============================================================================
// PROJECT: UNIVERSAL GPS STANDOFF MOUNT
// VERSION: 2.9 (Full Parametric Entry - X/Z Window Control)
// =============================================================================

/* [1. FRAME SETTINGS] */
standoff_dist   = 28.0;  
standoff_dia    = 5.5;   
standoff_height = 25.0;  
wall_thickness  = 2.4; 

/* [2. GPS COMPARTMENT SETTINGS] */
gps_angle       = 5;    
gps_offset      = 10.0;  
gps_w           = 20.2;  
gps_l           = 22.2;  
gps_d           = 6.0;   

/* [3. WIRE WINDOW SETTINGS] */
// Width of the rear wire entrance slot (mm)
wire_window_w   = 12.0;  
// Height of the rear wire entrance slot (mm)
wire_window_h   = 4.0;   
// Horizontal offset: 0 = Centered. (+) is Right, (-) is Left.
wire_window_x   = 0.0;
// Vertical offset: 0 = Bottom of cavity. Increase to move window up.
wire_window_z   = 0.0;   

/* [4. HARDWARE & RETENTION] */
ziptie_width    = 3.5;   
ziptie_thick    = 2.2; 
wire_hole_dia   = 5.0; 

/* [5. INTERNAL CALCULATIONS] */
$fn = 60;
box_w = gps_w + (wall_thickness * 2);
box_l = gps_l + (wall_thickness * 2);
box_d = gps_d + wall_thickness; 

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    // --- STEP 1: SOLID BODY ---
    union() {
        for(i=[-1, 1]) {
            translate([i * standoff_dist/2, 0, 0])
                cylinder(h=standoff_height, d=standoff_dia + (wall_thickness*2));
        }

        translate([0, 0, standoff_height]) 
            rotate([-gps_angle, 0, 0])
                translate([0, gps_offset + (box_l/2), -box_d/2]) 
                    cube([box_w, box_l, box_d], center=true);

        for(i=[-1, 1]) {
            hull() {
                translate([0, 0, standoff_height]) 
                    rotate([-gps_angle, 0, 0])
                        translate([i * (box_w/2 - 1), gps_offset + (box_l/2), -box_d/2])
                            cube([2, box_l, box_d], center=true);
                translate([i * standoff_dist/2, 0, 0])
                    cylinder(h=1, d=standoff_dia + (wall_thickness*2));
            }
        }
    }

    // --- STEP 2: SUBTRACTIONS ---
    
    // A. Standoff Holes
    for(i=[-1, 1]) {
        translate([i * standoff_dist/2, 0, -1])
            cylinder(h=standoff_height + 2, d=standoff_dia - 0.1, $fn=8);
    }

    // B. Internal Cavity Group (Angled Box Interior)
    translate([0, 0, standoff_height])
        rotate([-gps_angle, 0, 0])
            translate([0, gps_offset + (box_l/2), 0]) {
                
                // 1. The Main GPS Cavity
                translate([0, 0, -gps_d/2 + 0.1])
                    cube([gps_w, gps_l, gps_d + 0.2], center=true);
                
                // 2. THE REAR WIRE WINDOW (Now with X and Z adjustment)
                translate([wire_window_x, -gps_l/2, -gps_d + (wire_window_h/2) + wire_window_z])
                    cube([wire_window_w, wall_thickness * 6, wire_window_h], center=true);

                // 3. Zip-Tie Trench & Side Windows
                translate([0, 0, -gps_d - (ziptie_thick/2)])
                    cube([box_w + 50, ziptie_width, ziptie_thick], center=true);
                
                // 4. Floor Push-out Port
                translate([0, 0, -50])
                    cylinder(h=100, d=wire_hole_dia);
            }
}