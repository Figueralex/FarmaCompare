import os
from PIL import Image

def resize_and_pad_logo(input_path, output_path, scale_factor=0.85):
    print(f"Opening logo at: {input_path}")
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"Input image not found: {input_path}")
        
    img = Image.open(input_path).convert("RGBA")
    orig_width, orig_height = img.size
    print(f"Original size: {orig_width}x{orig_height}")
    
    # Calculate new dimensions (85% of original)
    new_width = int(orig_width * scale_factor)
    new_height = int(orig_height * scale_factor)
    print(f"New scaled size ({int(scale_factor * 100)}%): {new_width}x{new_height}")
    
    # Resize the image using Resampling.LANCZOS
    resized_img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Create a new transparent image of the original size
    padded_img = Image.new("RGBA", (orig_width, orig_height), (0, 0, 0, 0))
    
    # Calculate centering offsets
    offset_x = (orig_width - new_width) // 2
    offset_y = (orig_height - new_height) // 2
    
    # Paste the resized logo onto the transparent canvas
    padded_img.paste(resized_img, (offset_x, offset_y), resized_img)
    
    # Save the output image
    padded_img.save(output_path, "PNG")
    print(f"Successfully saved scaled/padded logo to: {output_path}")

if __name__ == "__main__":
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    logo_path = os.path.join(project_root, "assets", "images", "logo.png")
    output_path = os.path.join(project_root, "assets", "images", "logo_foreground.png")
    resize_and_pad_logo(logo_path, output_path, scale_factor=0.85)
