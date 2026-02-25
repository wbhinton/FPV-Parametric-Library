// =============================================================================
// PROJECT: FPV PARAMETRIC LIBRARY - DRONE COOLING STAND
// VERSION: 5.6 (Internal Fan Mount + Threaded Inserts)
// DESCRIPTION: Fan mounts to the INSIDE of the stand. 
//              Inserts are pressed into the ceiling.
// =============================================================================

/* [1. FAN & GRILLE SETTINGS] */
fan_size        = 80.0; 
fan_mount_hole  = 71.5; 
hex_d           = 10.0;  
hex_spacing     = 2.5;   

/* [2. STAND DIMENSIONS] */
// Ensure stand_height is greater than fan_thick (usually 25mm)
stand_height    = 40.0; 
outer_margin    = 15.0; 
wall_thick      = 3.0;

/* [3. HARDWARE & INSERTS] */
xt60_screw_dist = 22.0;
// Diameter for M3 heat-set inserts (adjust for your specific brand)
insert_hole_dia = 4.2;   
// Depth of the insert boss growing DOWN from the ceiling
boss_height     = 8.0;

/* [4. GLOBAL SETUP] */
$fn = 60;
total_dim = fan_size + (outer_margin * 2);

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    // A. THE MAIN ENCLOSURE
    union() {
        difference() {
            rounded_rect(total_dim, total_dim, stand_height, 8);
            // Hollow out the underside
            translate([0, 0, -1]) 
                rounded_rect(total_dim - (wall_thick*2), total_dim - (wall_thick*2), stand_height - wall_thick, 6);
        }
        
        // B. INTERNAL CEILING BOSSES
        // These grow DOWN from the top to receive the fan and inserts
        for(x = [-fan_mount_hole/2, fan_mount_hole/2], y = [-fan_mount_hole/2, fan_mount_hole/2])
            translate([x, y, stand_height - boss_height])
                cylinder(h = boss_height, d = insert_hole_dia + 4);
    }

    // --- THE SUBTRACTIONS (Drilling) ---
    
    // 1. DYNAMIC HEX GRILLE (Drilling through the top plate)
    let (step_x = hex_d + hex_spacing, 
         step_y = (hex_d + hex_spacing) * 0.866) 
    {
        for (x = [-fan_size/2 : step_x : fan_size/2]) {
            for (y = [-fan_size/2 : step_y : fan_size/2]) {
                shift_x = (floor(y / step_y + 0.5) % 2 == 0) ? 0 : step_x / 2;
                if (sqrt(pow(x + shift_x, 2) + pow(y, 2)) < (fan_size / 2 - 2)) {
                    translate([x + shift_x, y, stand_height - wall_thick - 1])
                        cylinder(h = wall_thick + 5, d = hex_d, $fn=6);
                }
            }
        }
    }

    // 2. M3 THREADED INSERT HOLES (Bored from the bottom up)
    for(x = [-fan_mount_hole/2, fan_mount_hole/2], y = [-fan_mount_hole/2, fan_mount_hole/2])
        translate([x, y, stand_height - boss_height - 1]) 
            cylinder(h = boss_height + 0.1, d = insert_hole_dia);

    // 3. XT60 PORT
    translate([0, -total_dim/2, stand_height/2]) 
        rotate([90, 0, 0]) xt60_cutout();

    // 4. AIR INTAKE ARCHES
    for(r = [0, 90, 180, 270])
        rotate([0, 0, r])
            translate([0, -total_dim/2, 0])
                hull() {
                    translate([-20, 0, 12]) rotate([90, 0, 0]) cylinder(h=15, d=18, center=true);
                    translate([20, 0, 12]) rotate([90, 0, 0]) cylinder(h=15, d=18, center=true);
                }
}

// =============================================================================
// MODULES
// =============================================================================

module xt60_cutout() {
    cube([16, 9, 20], center=true);
    for(x = [-xt60_screw_dist/2, xt60_screw_dist/2])
        translate([x, 0, 0]) cylinder(h=20, d=2.5, center=true);
}

module rounded_rect(w, l, h, r) {
    hull() {
        for(x = [-w/2+r, w/2-r], y = [-l/2+r, l/2-r])
            translate([x, y, 0]) cylinder(h=h, r=r);
    }
}