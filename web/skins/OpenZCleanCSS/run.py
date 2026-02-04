import cv2
import numpy as np
import os
from pathlib import Path


def process_image(image_path, output_path):
    """Process a single image: make purple transparent and white black.
    For images with 'disabled' in filename, creates an empty transparent image."""
    # Read image with alpha channel
    img = cv2.imread(str(image_path), cv2.IMREAD_UNCHANGED)
    if img is None:
        raise ValueError(f"Could not read image: {image_path}")

    # For disabled images, create empty transparent image with same dimensions
    if "disabled" in str(image_path).lower():
        height, width = img.shape[:2]
        # Create empty BGRA image (fully transparent)
        transparent_img = np.zeros((height, width, 4), dtype=np.uint8)
        if not cv2.imwrite(str(output_path), transparent_img):
            raise ValueError(f"Failed to save image: {output_path}")
        return

    # Ensure image has alpha channel
    # Convert image to BGRA if needed
    if len(img.shape) == 2:  # Grayscale
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
        alpha = np.ones(img.shape[:2], dtype=img.dtype) * 255
        img = np.dstack((img, alpha))
    elif len(img.shape) == 3:
        if img.shape[2] == 3:  # BGR
            alpha = np.ones(img.shape[:2], dtype=img.dtype) * 255
            img = np.dstack((img, alpha))
        elif img.shape[2] == 4:  # BGRA
            pass
        else:
            raise ValueError(f"Unexpected number of channels: {img.shape[2]}")

    # Convert to HSV for better color detection
    hsv = cv2.cvtColor(img[:, :, :3], cv2.COLOR_BGR2HSV)

    # Create mask for white pixels using HSV
    white_mask = (hsv[:, :, 1] < 30) & (hsv[:, :, 2] > 240)

    # Create mask for purple pixels using HSV
    # Purple hue range in HSV is around 270-290 degrees (135-145 in OpenCV's 0-180 range)
    purple_lower = np.array([135, 25, 25])
    purple_upper = np.array([145, 255, 255])
    purple_mask = cv2.inRange(hsv, purple_lower, purple_upper)

    # Convert purple areas to transparent
    img[purple_mask > 0, 3] = 0  # Set alpha to 0 for purple areas

    # Convert white areas to black with full opacity
    img[white_mask, 0] = 0  # Blue channel
    img[white_mask, 1] = 0  # Green channel
    img[white_mask, 2] = 0  # Red channel
    img[white_mask, 3] = 255  # Full opacity

    # Save the processed image
    if not cv2.imwrite(str(output_path), img):
        raise ValueError(f"Failed to save image: {output_path}")


def main():
    """Process all images in the input directory."""
    # X:\OpenZND\Common\FieldButton
    input_dir = Path("X:/OpenZND/Common/FieldButton")
    output_dir = Path("X:/OpenZND/Common/FieldButton")

    # Create output directory if it doesn't exist
    output_dir.mkdir(exist_ok=True)

    # Process each image
    for file_path in input_dir.glob("*"):
        # Check if the file is an image based and starts with "icon"
        if file_path.suffix.lower() in (
            ".png",
            ".jpg",
            ".jpeg",
        ) and file_path.name.startswith("icon"):
            try:
                output_path = output_dir / file_path.name
                process_image(file_path, output_path)
                print(f"Successfully processed: {file_path.name}")
            except Exception as e:
                print(f"Error processing {file_path.name}: {str(e)}")


if __name__ == "__main__":
    main()
