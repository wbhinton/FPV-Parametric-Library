// =============================================================================
// PROJECT: FIXED-WING "V-STACK" VTX + MODULAR FAN MOUNT
// VERSION: 2.3 (Stepped Bore for Heat-Set Inserts)
// DESCRIPTION: Features a primary hole for the insert and a secondary 
//              smaller hole for screw clearance to prevent binding.
// =============================================================================

/* [1. MODULAR OPTIONS] */
use_fan_mount   = 1; 

/* [2. BASE PLATE SETTINGS] */
base_w          = 48.0;  
base_l          = 58.0;  
base_thick      = 1.2;   
base_radius     = 8.0;   
slot_width      = 1.6;   

/* [3. VTX STACK SETTINGS] */
stack_vtx_w     = 20.0;  
stack_vtx_l     = 20.0;  
stack_vtx_h     = 6.0;   
vtx_thickness   = 6.5;   

/* [4. FAN STACK SETTINGS] */
stack_fan_w     = 24.0;  
stack_fan_l     = 24.0;  
fan_gap         = 3.0;   

/* [5. HARDWARE & INSERT SPECS] */
standoff_dia    = 7.5;   
// Primary hole for the heat-set insert (e.g., 4.0mm for M3)
insert_hole_dia = 4.0;   
// Depth of the heat-set insert itself
insert_hole_depth = 4.5; 
// Secondary hole for the screw to pass through (usually 1mm smaller)
screw_clearance_dia = 3.0; 

$fn = 60;

/* [6. DYNAMIC CALCULATIONS] */
total_fan_h = stack_vtx_h + vtx_thickness + fan_gap;

// =============================================================================
// MODULES (Reusable Code Blocks)
// =============================================================================

module stepped_hole(total_h) {
    // 1. Primary Insert Hole (Top-down)
    translate([0, 0, total_h - insert_hole_depth + 0.01])
        cylinder(h=insert_hole_depth + 1, d=insert_hole_dia);
    
    // 2. Secondary Clearance Hole (The rest of the way through)
    translate([0, 0, -1])
        cylinder(h=total_h + 2, d=screw_clearance_dia);
}

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    
    // --- STEP 1: THE SOLID BODY ---
    union() {
        hull() {
            for(x = [-base_w/2 + base_radius, base_w/2 - base_radius]) {
                for(y = [-base_l/2 + base_radius, base_l/2 - base_radius]) {
                    translate([x, y, 0])
                        cylinder(h=base_thick, r=base_radius);
                }
            }
        }
        
        // VTX Standoffs
        for(x = [-stack_vtx_w/2, stack_vtx_w/2]) {
            for(y = [-stack_vtx_l/2, stack_vtx_l/2]) {
                translate([x, y, 0])
                    cylinder(h=stack_vtx_h + base_thick, d=standoff_dia);
            }
        }
        
        // Fan Standoffs
        if (use_fan_mount == 1) {
            rotate([0, 0, 45]) {
                for(x = [-stack_fan_w/2, stack_fan_w/2]) {
                    for(y = [-stack_fan_l/2, stack_fan_l/2]) {
                        translate([x, y, 0])
                            cylinder(h=total_fan_h + base_thick, d=standoff_dia);
                    }
                }
            }
        }
    }

    // --- STEP 2: THE SUBTRACTIONS ---

    // VTX Stepped Holes
    for(x = [-stack_vtx_w/2, stack_vtx_w/2]) {
        for(y = [-stack_vtx_l/2, stack_vtx_l/2]) {
            translate([x, y, 0])
                stepped_hole(stack_vtx_h + base_thick);
        }
    }

    // Fan Stepped Holes
    if (use_fan_mount == 1) {
        rotate([0, 0, 45]) {
            for(x = [-stack_fan_w/2, stack_fan_w/2]) {
                for(y = [-stack_fan_l/2, stack_fan_l/2]) {
                    translate([x, y, 0])
                        stepped_hole(total_fan_h + base_thick);
                }
            }
        }
    }

    // Flex Relief Slots
    for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6]) {
        translate([0, i, -0.1])
            cube([base_w + 10, slot_width, base_thick + 0.1], center=true);
    }
}