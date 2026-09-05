// =============================================================================
// PROJECT: PARAMETRIC LI-ION TRUSS SPACER (AIRCRAFT / FPV PACKS)
// VERSION: 5.0 (Parametric Spacing with Automatic Truss Suppression)
// LICENSE: Creative Commons Zero (CC0) / Public Domain
// AUTHOR: Weston Hinton (2026)
// DESCRIPTION: Dynamic battery spacer engine. Allows custom cell spacing starting 
//              from a minimum tangent bound (outer wall tangent to inner bore).
//              Truss struts render dynamically only when spacing is added.
// =============================================================================

/* [Pack Shape & Layout] */
// Layout geometry style
packShape          = "triangle"; // [grid: Standard Grid, triangle: 3-Cell Delta Triangle]

/* [Cell Specs] */
// Actual cell diameter including shrink sleeve in mm (18650 ≈ 18.4, 21700 ≈ 21.4)
cellDiameter       = 18.4; // [10:0.1:35]

// Mechanical clearance added to bore diameter for smooth TPU press fit
fitTolerance       = 0.20; 

/* [Spacing Controls] */
// Extra spacing gap added between cell ring perimeters (0.0 = Minimum Tangent Fit)
cellSpacingGap     = 0.0; // [0.0:0.1:10.0]

/* [Grid Configuration (Used when packShape = "grid")] */
// Number of cells in X (Columns)
rowsX              = 3; // [1:1:12]

// Number of cells in Y (Rows)
rowsY              = 2; // [1:1:12]

/* [Spacer Mechanical Dimensions] */
// Overall vertical height of the spacer frame ring in mm
spacerHeight       = 8.0; 

// Width of individual truss struts connecting the cell rings (in mm)
trussWidth         = 1.8; 

/* [Slicer & Print Optimization] */
// Printer nozzle diameter in mm (Optimized for 0.6mm setups)
nozzleSize         = 0.6; // [0.4, 0.6, 0.8]

// Target layer height in mm
layerHeight        = 0.24; 

// Number of solid perimeter passes for ring walls
perimeterCount     = 3; 

// Retaining lip height in exact layer count (default: 3 layers)
retainerLayers     = 3; 

// Retaining lip width in exact nozzle perimeter passes (default: 2 passes)
retainerPasses     = 2; 

/* [Hidden Geometry Calculations] */
$fn = 64;
overlap = 0.05;

// Microscopic overlap to guarantee clean CGAL 2D manifold fusion during F6 render
manifold_fix = 0.02;

// Extrusion math matching FDM nozzle physics
extrusionWidth = nozzleSize * 1.125;
wallThickness  = extrusionWidth * perimeterCount;

// Dynamic Retaining Lip Dimensions driven by Slicer Specs
retainerLipDepth = layerHeight * retainerLayers;           // 3 layers = 0.72mm
retainerLipWidth = extrusionWidth * retainerPasses;        // 2 passes = 1.35mm

// Effective Cell Bore & Radii
boreDiameter  = cellDiameter + fitTolerance;
boreRadius    = boreDiameter / 2;
outerRadius   = boreRadius + wallThickness;

// MINIMUM TANGENT PITCH: Outer wall of A touches inner wall (bore) of B
min_tangent_pitch = boreRadius + outerRadius;

// ACTIVE PITCH: Minimum bound enforced + user-defined extra gap
pitch = max(min_tangent_pitch, min_tangent_pitch + cellSpacingGap) - manifold_fix;

// Rhombic Grid Geometry offsets (60° staggered layout)
pitchX     = pitch;
pitchY     = pitch * sin(60); 
rowShiftX  = pitch * cos(60); 

// Dynamic calculation of cell center points
function get_cell_centers() = 
    (packShape == "triangle") ? [
        [0, 0],                            // Cell 1: Bottom Left
        [pitch, 0],                        // Cell 2: Bottom Right
        [pitch / 2, pitch * sin(60)]       // Cell 3: Apex Center
    ] : [
        for (y = [0 : rowsY - 1], x = [0 : rowsX - 1])
            [(x * pitchX) + ((y % 2 == 1) ? rowShiftX : 0), y * pitchY]
    ];

cell_points = get_cell_centers();
num_cells   = len(cell_points);

// Enable truss struts only when there is explicit gap distance between outer walls
render_trusses = (cellSpacingGap > 0.05);

// =============================================================================
// RENDER CONTROLLER
// =============================================================================

echo("=== BATTERY SPACER METRICS (v5.0 - Dynamic Spacing) ===");
echo(STR_PACK_MODE             = packShape);
echo(STR_CELL_BORE_DIAMETER    = boreDiameter, "mm");
echo(STR_ADDED_GAP_SPACING     = cellSpacingGap, "mm");
echo(STR_CALCULATED_PITCH      = pitch, "mm");
echo(STR_TRUSS_RENDER_STATUS   = render_trusses ? "ENABLED" : "DISABLED (Tangent Fit)");
echo("=======================================================");

renderSpacer();

// =============================================================================
// MAIN ASSEMBLY MODULE
// =============================================================================

module renderSpacer() {
    difference() {
        // 1. UNIFIED SOLID BODY (Individual Rings + Conditional Truss Struts)
        linear_extrude(height = spacerHeight, convexity = 10) {
            union() {
                // A. Base Individual Cell Outer Rings
                for (pt = cell_points) {
                    translate(pt)
                        circle(r = outerRadius);
                }
                
                // B. Truss Lattice Struts (Only rendered when cellSpacingGap > 0)
                if (num_cells > 1 && render_trusses) {
                    for (i = [0 : num_cells - 2]) {
                        for (j = [i + 1 : num_cells - 1]) {
                            p1 = cell_points[i];
                            p2 = cell_points[j];
                            
                            d = norm([p1[0] - p2[0], p1[1] - p2[1]]);
                            
                            if (d < pitch + 1.0) {
                                truss_strut(p1, p2, offset_angle = 30, w = trussWidth);
                                truss_strut(p1, p2, offset_angle = -30, w = trussWidth);
                            }
                        }
                    }
                }
            }
        }

        // 2. CELL BORES & RETAINING SHOULDERS
        for (pt = cell_points) {
            // A. Full Terminal Hole (Passing through Z=0)
            translate([pt[0], pt[1], -overlap])
                cylinder(h = spacerHeight + (overlap * 2), r = boreRadius - retainerLipWidth);
            
            // B. Main Cell Body Pocket (Starting above lip height)
            translate([pt[0], pt[1], retainerLipDepth])
                cylinder(h = spacerHeight - retainerLipDepth + overlap, r = boreRadius);
        }
    }
}

// =============================================================================
// TRUSS STRUT HELPER MODULE
// Calculates angled tangential bridge struts between two circular nodes
// =============================================================================
module truss_strut(p1, p2, offset_angle = 0, w = 1.8) {
    dx = p2[0] - p1[0];
    dy = p2[1] - p1[1];
    base_angle = atan2(dy, dx);
    
    a1 = base_angle + offset_angle;
    a2 = base_angle + 180 - offset_angle;
    
    node1 = [p1[0] + outerRadius * cos(a1), p1[1] + outerRadius * sin(a1)];
    node2 = [p2[0] + outerRadius * cos(a2), p2[1] + outerRadius * sin(a2)];
    
    hull() {
        translate(node1) circle(d = w);
        translate(node2) circle(d = w);
    }
}