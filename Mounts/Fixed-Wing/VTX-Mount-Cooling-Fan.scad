// =============================================================================
// PROJECT: FPV PARAMETRIC LIBRARY - V-STACK VTX MOUNT
// VERSION: 3.7 (Fully Documented / Novice-Friendly)
// DESCRIPTION: A two-part modular system for mounting a VTX and a cooling fan.
//              The "Base" mounts to the aircraft, and the "Hat" mounts to the VTX.
// =============================================================================

/* [1. VIEW & RENDER CONTROL] */
// Use 'Assembly' to check fit, 'Base' or 'Hat' to export your STL files.
mode = 1; // [1:Assembly View, 2:Base Plate (Bottom), 3:The Hat (Top)]

/* [2. VTX (VIDEO TRANSMITTER) DIMENSIONS] */
// The standard mounting hole width (e.g., 30.5, 25.5, or 20.0)
vtx_w = 30.5;  
// The standard mounting hole length
vtx_l = 30.5;  
// Thickness of the actual green VTX circuit board
vtx_pcb_thick = 1.6;   
// Distance between the base plate and the bottom of the VTX (Airflow space)
base_standoff_h = 6.0;   
// Diameter of the vertical support pillars
standoff_dia = 8.0;   

/* [3. FAN & PLENUM SETTINGS] */
// Distance between fan mounting holes
fan_w = 28.0;  
fan_l = 28.0;
// Diameter of the main air hole in the center
fan_aperture = 30.0;  
// Vertical distance from the top of the VTX board to the fan plate
fan_gap = 6.0;   
// Thickness of the top plate (must be deep enough for your heat-set inserts)
fan_plate_thick = 5.0;   
// Extra plastic border around the furthest mounting holes
plate_padding = 4.0; 
// How much the pillars extend below the walls to avoid hitting VTX components
leg_extension = 2.0;

/* [4. HARDWARE & FIT] */
// Diameter of the hole for M3 heat-set inserts (usually 4.0mm)
insert_hole_dia = 4.0;   
// How deep the heat-set insert is
insert_hole_depth = 4.5;
// Diameter for the M3 screw to pass through (3.4mm gives a loose fit)
screw_dia = 3.4;   
// Diameter of the head of your M3 screw (to ensure it sits flush)
screw_head_dia = 6.5;   
// How deep the screw head should be buried into the plastic
screw_head_depth = 2.5;  

/* [5. GLOBAL GEOMETRY] */
base_w = 48.0;  
base_l = 58.0;  
base_thick = 1.2;   
// Resolution of circles (60 is a good balance for speed vs smoothness)
$fn = 60;

// =============================================================================
// --- DYNAMIC CALCULATIONS (Math handled by the script) ---
// =============================================================================

// Determine where to place the Hat in the Assembly view
hat_z_pos = base_thick + base_standoff_h + vtx_pcb_thick;
// Determine how tall the Hat is in total
total_hat_h = (fan_gap - leg_extension) + fan_plate_thick + leg_extension;

// We rotate the fan 45 degrees. This math finds how far the corners "reach"
// so the plate can automatically grow to cover them.
fan_diag_reach = sqrt(pow(fan_w/2, 2) + pow(fan_l/2, 2));
required_plate_w = max(vtx_w, fan_diag_reach * 2) + (plate_padding * 2);
required_plate_l = max(vtx_l, fan_diag_reach * 2) + (plate_padding * 2);

// =============================================================================
// --- MAIN EXECUTION BLOCK ---
// =============================================================================

if (mode == 1) {
    // Mode 1: ASSEMBLY. Shows how the parts fit together.
    base_plate();
    
    // The "%" makes this a 'Ghost' VTX board for visual reference only.
    %translate([0, 0, base_thick + base_standoff_h + vtx_pcb_thick/2])
        cube([vtx_w + 5, vtx_l + 5, vtx_pcb_thick], center=true);
    
    // Place the Hat on top of the VTX
    translate([0, 0, hat_z_pos]) the_hat();
} 
else if (mode == 2) {
    // Mode 2: EXPORT BASE.
    base_plate();
} 
else if (mode == 3) {
    // Mode 3: EXPORT HAT. 
    // It is automatically flipped 180 degrees so the flat plate sits on the bed.
    translate([0, 0, total_hat_h]) rotate([180, 0, 0]) the_hat();
}

// =============================================================================
// --- MODULES (The actual 3D logic) ---
// =============================================================================

module base_plate() {
    difference() {
        union() {
            // Create the main mounting footprint
            rounded_rect(base_w, base_l, base_thick, 8);
            
            // Build the VTX support pillars
            for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2]) {
                translate([x, y, base_thick - 0.1]) {
                    cylinder(h=base_standoff_h, d=standoff_dia);
                    // Add a flared 'chamfer' at the bottom for strength
                    hull() {
                        cylinder(h=0.1, d=standoff_dia + 6);
                        translate([0, 0, 3]) cylinder(h=0.1, d=standoff_dia);
                    }
                }
            }
        }
        // Drill the bolt holes through the pillars
        for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2])
            translate([x, y, -1]) cylinder(h=base_standoff_h + 5, d=screw_dia);
            
        // Cut the "Tank Tread" flex slots into the base
        for(i = [-base_l/2 + 6 : 9 : base_l/2 - 6])
            translate([0, i, -0.1]) cube([base_w + 10, 1.6, base_thick + 0.5], center=true);
    }
}

module the_hat() {
    difference() {
        union() {
            // 1. The Main Fan Mounting Plate (Rounded Rectangle)
            translate([0, 0, total_hat_h - fan_plate_thick])
                rounded_rect(required_plate_w, required_plate_l, fan_plate_thick, 8);
            
            // 2. The Plenum Walls (Air tunnels on the sides)
            // These terminate at the center of the pillars.
            for(x = [-1, 1])
                translate([x * (vtx_w/2), 0, (total_hat_h - fan_plate_thick + leg_extension)/2])
                    cube([4, vtx_l, total_hat_h - fan_plate_thick - leg_extension], center=true);
            
            // 3. The Corner Posts (Full height pillars for structural strength)
            for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2])
                translate([x, y, 0]) cylinder(h=total_hat_h - 0.1, d=standoff_dia);
        }

        // A. Cut the large hole for the fan airflow
        translate([0, 0, total_hat_h - 10]) cylinder(h=20, d=fan_aperture);

        // B. Cut the holes for the Fan Heat-Set Inserts (Rotated 45 degrees)
        rotate([0, 0, 45])
            for(x = [-fan_w/2, fan_w/2], y = [-fan_l/2, fan_l/2])
                translate([x, y, total_hat_h - insert_hole_depth + 0.1]) 
                    cylinder(h=insert_hole_depth + 1, d=insert_hole_dia);

        // C. Drill the main VTX bolt holes and the head recesses
        for(x = [-vtx_w/2, vtx_w/2], y = [-vtx_l/2, vtx_l/2]) {
            // The screw shank hole
            translate([x, y, -1]) cylinder(h=total_hat_h + 2, d=screw_dia);
            // The recess for the bolt head so it stays flush
            translate([x, y, total_hat_h - screw_head_depth + 0.01]) 
                cylinder(h=screw_head_depth + 1, d=screw_head_dia);
        }
        
        // D. Final clearance for the fan bolts (prevents bottoming out)
        rotate([0, 0, 45])
            for(x = [-fan_w/2, fan_w/2], y = [-fan_l/2, fan_l/2])
                translate([x, y, -1]) cylinder(h=total_hat_h + 2, d=3.2);
    }
}

// --- HELPER MODULE: Rounded Rectangle ---
module rounded_rect(w, l, h, r) {
    hull() {
        for(x = [-w/2+r, w/2-r], y = [-l/2+r, l/2-r])
            translate([x, y, 0]) cylinder(h=h, r=r);
    }
}