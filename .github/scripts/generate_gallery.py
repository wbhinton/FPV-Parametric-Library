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

def ensure_directory(path):
    if not os.path.exists(path):
        os.makedirs(path)

def generate_image(scad_file):
    base_name = os.path.splitext(os.path.basename(scad_file))[0]
    output_image = os.path.join(PREVIEW_DIR, base_name + IMG_EXT)
    
    # Check if image exists and is newer than the scad file
    if os.path.exists(output_image):
        scad_mtime = os.path.getmtime(scad_file)
        img_mtime = os.path.getmtime(output_image)
        if img_mtime > scad_mtime:
            print(f"Skipping {scad_file} (uptodate)")
            return output_image

    print(f"Rendering {scad_file} -> {output_image}")
    try:
        # OpenSCAD command: openscad -o output.png --imgsize=1024,768 input.scad
        cmd = [
            "openscad",
            "-o", output_image,
            "--imgsize=" + IMG_SIZE,
            "--colorscheme=Tomorrow Night",
            "--viewall",
            "--autocenter",
            scad_file
        ]
        subprocess.run(cmd, check=True)
        return output_image
    except subprocess.CalledProcessError as e:
        print(f"Error rendering {scad_file}: {e}")
        return None
    except FileNotFoundError:
        print("Error: openscad command not found. Please install OpenSCAD.")
        return None

def update_readme(images):
    if not os.path.exists(README_FILE):
        print(f"Error: {README_FILE} not found.")
        return

    with open(README_FILE, "r") as f:
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
    
    with open(README_FILE, "w") as f:
        f.write(new_content)
    
    print("README updated successfully.")

def main():
    ensure_directory(PREVIEW_DIR)
    
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

    update_readme(generated_images)

if __name__ == "__main__":
    main()
