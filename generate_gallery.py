import os
import subprocess
import glob

# Configuration
SCAD_EXT = ".scad"
IMG_EXT = ".png"
PREVIEW_DIR = "previews"
README_FILE = "README.md"
IMG_SIZE = "1024,768"
GALLERY_START = "<!-- GALLERY_START -->"
GALLERY_END = "<!-- GALLERY_END -->"
STL_DIR = "models/STL"
STL_EXT = ".stl"

def ensure_directory(path):
    if not os.path.exists(path):
        os.makedirs(path)

def get_openscad_executable():
    # Check if openscad is in PATH
    try:
        subprocess.run(["openscad", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return "openscad"
    except FileNotFoundError:
        pass
        
    # Check common Windows paths
    windows_path_com = r"C:\Program Files\OpenSCAD\openscad.com"
    if os.path.exists(windows_path_com):
        return windows_path_com

    windows_path = r"C:\Program Files\OpenSCAD\openscad.exe"
    if os.path.exists(windows_path):
        return windows_path
        
    windows_path_x86_com = r"C:\Program Files (x86)\OpenSCAD\openscad.com"
    if os.path.exists(windows_path_x86_com):
        return windows_path_x86_com

    windows_path_x86 = r"C:\Program Files (x86)\OpenSCAD\openscad.exe"
    if os.path.exists(windows_path_x86):
        return windows_path_x86

    return None

OPENSCAD_BIN = get_openscad_executable()

def generate_image(scad_file):
    base_name = os.path.splitext(os.path.basename(scad_file))[0]
    output_image = os.path.join(PREVIEW_DIR, base_name + IMG_EXT)
    
    # Check if image exists, is valid (non-empty), and is newer than the scad file
    min_size = 1000 # Minimum size in bytes (e.g., to catch empty/failed renders)
    if os.path.exists(output_image) and os.path.getsize(output_image) > min_size:
        scad_mtime = os.path.getmtime(scad_file)
        img_mtime = os.path.getmtime(output_image)
        if img_mtime > scad_mtime:
            print(f"Skipping {scad_file} (uptodate)")
            return output_image

    print(f"Rendering {scad_file} -> {output_image}")
    
    if not OPENSCAD_BIN:
        print("Error: openscad command not found. Please install OpenSCAD.")
        return None

    try:
        # OpenSCAD command: openscad -o output.png --imgsize=1024,768 input.scad
        cmd = [
            OPENSCAD_BIN,
            "-o", output_image,
            "--imgsize=" + IMG_SIZE,
            "--colorscheme=Tomorrow Night",
            "--viewall",
            "--autocenter",
            scad_file
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error rendering {scad_file}: {result.stderr}")
            return None
        return output_image
    except Exception as e:
        print(f"Exception rendering {scad_file}: {e}")
        return None
    except FileNotFoundError:
        print("Error: openscad command not found. Please install OpenSCAD.")
        return None

def generate_stl(scad_file):
    base_name = os.path.splitext(os.path.basename(scad_file))[0]
    output_stl = os.path.join(STL_DIR, base_name + STL_EXT)
    
    # Check if STL exists and is newer than the scad file
    min_size = 1000 # Minimum size in bytes
    if os.path.exists(output_stl) and os.path.getsize(output_stl) > min_size:
        scad_mtime = os.path.getmtime(scad_file)
        stl_mtime = os.path.getmtime(output_stl)
        if stl_mtime > scad_mtime:
            print(f"Skipping STL for {scad_file} (uptodate)")
            return output_stl

    print(f"Generating STL {scad_file} -> {output_stl}")
    
    if not OPENSCAD_BIN:
        print("Error: openscad command not found. Please install OpenSCAD.")
        return None

    try:
        # OpenSCAD command: openscad -o output.stl input.scad
        cmd = [
            OPENSCAD_BIN,
            "-o", output_stl,
            scad_file
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error generating STL for {scad_file}: {result.stderr}")
            return None
        return output_stl
    except Exception as e:
        print(f"Exception generating STL for {scad_file}: {e}")
        return None
    except FileNotFoundError:
        print("Error: openscad command not found. Please install OpenSCAD.")
        return None

def update_readme(images):
    if not os.path.exists(README_FILE):
        print(f"Error: {README_FILE} not found.")
        return

    with open(README_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    if GALLERY_START not in content or GALLERY_END not in content:
        print(f"Error: Gallery markers not found in {README_FILE}.")
        return

    # Generate Markdown Table
    # Group images into rows of 3
    table_lines = ["", "| | | |", "|:---:|:---:|:---:|"]
    row = []
    
    # Sort images for consistent order
    images.sort()

    for img_path in images:
        # Create a relative link
        filename = os.path.basename(img_path)
        # Assuming previews are in root/previews
        rel_path = f"{PREVIEW_DIR}/{filename}"
        name = os.path.splitext(filename)[0].replace("-", " ")
        
        cell = f"![{name}]({rel_path})<br>**{name}**"
        row.append(cell)
        
        if len(row) == 3:
            table_lines.append(f"| {' | '.join(row)} |")
            row = []

    # Fill incomplete row
    if row:
        while len(row) < 3:
            row.append("")
        table_lines.append(f"| {' | '.join(row)} |")
    
    table_lines.append("")
    gallery_content = "\n".join(table_lines)

    # Replace content between markers
    start_idx: int = int(content.find(GALLERY_START) + len(GALLERY_START))
    end_idx: int = int(content.find(GALLERY_END))
    
    new_content = content[:start_idx] + gallery_content + content[end_idx:]
    
    with open(README_FILE, "w", encoding="utf-8") as f:
        f.write(new_content)
    
    print("README updated successfully.")

def main():
    ensure_directory(PREVIEW_DIR)
    ensure_directory(STL_DIR)
    
    # Find all scad files recursively
    scad_files = []
    for root, dirs, files in os.walk("."):
        if ".git" in dirs:
            dirs.remove(".git") # Optimization
        for file in files:
            if file.endswith(SCAD_EXT):
                scad_files.append(os.path.join(root, file))

    generated_images = []
    for scad in scad_files:
        img = generate_image(scad)
        if img:
            generated_images.append(img.replace(os.path.sep, '/'))
        
        generate_stl(scad)

    update_readme(generated_images)

if __name__ == "__main__":
    main()
