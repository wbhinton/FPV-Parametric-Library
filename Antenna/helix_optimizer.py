#!/usr/bin/env python3
"""
GA-Optimized Uniform Helical Antenna Parameter Generator & Visualizer
Iteratively solves for the optimal constant radius and axial length based on target frequency,
number of turns, and desired pitch angle (3°-10° range for flat ground plane).
Outputs variables for OpenSCAD.
"""

import os
import sys
import argparse
import matplotlib.pyplot as plt
import numpy as np

def main():
    parser = argparse.ArgumentParser(description="Uniform Helical Antenna Optimizer")
    parser.add_argument("--freq", type=float, default=None, help="Target frequency in GHz or MHz (default: 5.79 GHz)")
    parser.add_argument("--wire", type=float, default=2.05, help="Wire diameter in mm (default: 2.05)")
    parser.add_argument("--turns", type=float, default=10.0, help="Number of turns (default: 10.0)")
    parser.add_argument("--pitch", type=float, default=8.0, help="Target pitch angle in degrees (3°-10° range, default: 8.0°)")
    parser.add_argument("--scad", type=str, default="OptimizedHelicalAntenna.scad", help="Path to OpenSCAD file to update")
    parser.add_argument("--output-dir", type=str, default=".", help="Directory to save the plot image")
    args = parser.parse_args()

    # Interactive prompt if run with no command-line arguments
    if len(sys.argv) == 1:
        print("=== Interactive Uniform Helical Antenna Optimizer ===")
        freq_input = input("Enter target frequency (e.g., 5.79 for GHz, or 5790 for MHz) [5.79]: ").strip()
        if freq_input:
            args.freq = float(freq_input)
        else:
            args.freq = 5.79

        wire_input = input("Enter wire diameter in mm [2.05]: ").strip()
        if wire_input:
            args.wire = float(wire_input)

        turns_input = input("Enter number of turns [10.0]: ").strip()
        if turns_input:
            args.turns = float(turns_input)

        pitch_input = input("Enter pitch angle in degrees (3-10 range) [8.0]: ").strip()
        if pitch_input:
            args.pitch = float(pitch_input)

        scad_input = input("Enter path to OpenSCAD file to update [OptimizedHelicalAntenna.scad]: ").strip()
        if scad_input:
            args.scad = scad_input
    else:
        # Fallback to default if not specified via CLI
        if args.freq is None:
            args.freq = 5.79

    # Normalize frequency: If > 100, assume it's in MHz and convert to GHz
    if args.freq > 100:
        print(f"Interpreting frequency {args.freq} as MHz. Converting to {args.freq / 1000.0:.3f} GHz.")
        args.freq = args.freq / 1000.0

    # Validate pitch angle
    if not (3.0 <= args.pitch <= 10.0):
        print(f"WARNING: Target pitch angle ({args.pitch}°) is outside the recommended 3°–10° range for flat ground planes.")

    # Constants
    c = 299792458  # speed of light in m/s
    f_target = args.freq

    # Wavelength in meters & millimeters
    lambda_m = c / (f_target * 1e9)
    lambda_mm = lambda_m * 1000

    # Iterative solver:
    # Corrected GA empirical equation (decimal point shifted by 10 to yield physical dimensions)
    # y = L/lambda
    # D_over_lambda = 0.205 + 0.079 * y - 0.00515 * y^2
    # L = N * S = N * pi * D * tan(pitch_angle)
    # y = N * pi * D_over_lambda * tan(pitch_angle)
    
    alpha_rad = np.radians(args.pitch)
    k = args.turns * np.pi * np.tan(alpha_rad)
    
    # Solve system:
    # y = k * (0.205 + 0.079 * y - 0.00515 * y^2)
    # 0.00515 * k * y^2 + (1 - 0.079 * k) * y - 0.205 * k = 0
    A = 0.00515 * k
    B = 1.0 - 0.079 * k
    C = -0.205 * k
    
    # Quadratic formula roots
    discriminant = B**2 - 4*A*C
    if discriminant < 0:
        # Fallback to fixed point iteration
        L_over_lambda = 1.0
        for _ in range(1000):
            D_over_lambda = 0.205 + 0.079 * L_over_lambda - 0.00515 * (L_over_lambda ** 2)
            L_over_lambda_new = k * D_over_lambda
            if abs(L_over_lambda_new - L_over_lambda) < 1e-7:
                L_over_lambda = L_over_lambda_new
                break
            L_over_lambda = L_over_lambda_new
        y_sol = L_over_lambda
    else:
        # Positive root represents L/lambda
        y_sol = (-B + np.sqrt(discriminant)) / (2 * A)

    # Compute parameters from normalized solution
    L_over_lambda = y_sol
    D_over_lambda = 0.205 + 0.079 * L_over_lambda - 0.00515 * (L_over_lambda ** 2)
    
    optimized_diameter_mm = D_over_lambda * lambda_mm
    total_height_mm = L_over_lambda * lambda_mm
    pitch_spacing_mm = total_height_mm / args.turns
    reflector_dia_mm = 0.75 * lambda_mm

    # Print OpenSCAD formatted variables
    print("// =====================================================================")
    print(f"// OPTIMIZED STRAIGHT HELICAL PARAMETERS FOR TARGET FREQUENCY: {f_target:.3f} GHz")
    print(f"// Wavelength: {lambda_mm:.3f} mm")
    print(f"// Chosen Pitch Angle: {args.pitch:.2f}° (Flat ground plane optimized)")
    print("// =====================================================================")
    print(f"optimized_diameter = {optimized_diameter_mm:.3f}; // Constant helix mean diameter in mm")
    print(f"pitch_spacing = {pitch_spacing_mm:.3f}; // Constant spacing between turns in mm")
    print(f"total_height = {total_height_mm:.3f}; // Total axial height (L) in mm")
    print(f"reflector_diameter = {reflector_dia_mm:.3f}; // Optimal flat reflector diameter (0.75 lambda) in mm")
    print(f"turns = {args.turns:.2f}; // Number of turns")
    print("// =====================================================================\n")

    # Generate profile plot
    z_vals = np.linspace(0, total_height_mm, 100)
    a_mm = optimized_diameter_mm / 2.0
    radius_vals = np.full_like(z_vals, a_mm)

    plt.figure(figsize=(8, 4))
    plt.plot(z_vals, radius_vals, label="Helix Radius (a)", color="crimson", linewidth=2.5)
    plt.plot(z_vals, -radius_vals, color="crimson", linestyle="--", alpha=0.5, label="Symmetric Radius Profile")
    plt.title(f"Uniform Helical Antenna Profile ({f_target:.2f} GHz, {args.turns:.2f} Turns, Pitch: {args.pitch}°)", fontsize=11, fontweight='bold')
    plt.xlabel("Antenna Height z (mm)", fontsize=10)
    plt.ylabel("Helix Radius a (mm)", fontsize=10)
    plt.ylim(-a_mm * 1.5, a_mm * 1.5)
    plt.grid(True, linestyle=":", alpha=0.6)
    plt.legend()
    plt.tight_layout()

    # Save plot
    os.makedirs(args.output_dir, exist_ok=True)
    plot_path = os.path.join(args.output_dir, "helix_taper.png")
    plt.savefig(plot_path, dpi=150)
    print(f"Antenna profile plot saved to: {plot_path}")

    # SCAD File Auto-Update
    if args.scad:
        scad_path = args.scad
        if os.path.exists(scad_path):
            import re
            print(f"Updating OpenSCAD file variables in: {scad_path}")
            with open(scad_path, 'r') as f:
                content = f.read()

            freq_mhz = int(round(f_target * 1000))
            content = re.sub(r'(centerFrequency\s*=\s*)\d+(\s*;)', r'\g<1>{:d}\g<2>'.format(freq_mhz), content)
            content = re.sub(r'(turns\s*=\s*)[\d\.]+(\s*;)', r'\g<1>{:.2f}\g<2>'.format(args.turns), content)
            content = re.sub(r'(optimized_diameter\s*=\s*)[\d\.]+(\s*;)', r'\g<1>{:.3f}\g<2>'.format(optimized_diameter_mm), content)
            content = re.sub(r'(pitch_spacing\s*=\s*)[\d\.]+(\s*;)', r'\g<1>{:.3f}\g<2>'.format(pitch_spacing_mm), content)
            content = re.sub(r'(total_height\s*=\s*)[\d\.]+(\s*;)', r'\g<1>{:.3f}\g<2>'.format(total_height_mm), content)
            content = re.sub(r'(reflector_diameter\s*=\s*)[\d\.]+(\s*;)', r'\g<1>{:.3f}\g<2>'.format(reflector_dia_mm), content)

            with open(scad_path, 'w') as f:
                f.write(content)
            print("OpenSCAD file successfully updated!")
        else:
            print(f"OpenSCAD file not found at: {scad_path}. Skipping auto-update.")

if __name__ == "__main__":
    main()
