"""
Auto-detect content bounds in PDF pages for smart cropping.
Uses PyMuPDF to render pages and find non-white content areas.
"""
import fitz  # PyMuPDF
from dataclasses import dataclass
from typing import Optional
import json


@dataclass
class CropBounds:
    """Crop bounds in PDF points (1/72 inch)."""
    top: float
    bottom: float
    left: float
    right: float

    def to_dict(self):
        return {
            'top': round(self.top, 1),
            'bottom': round(self.bottom, 1),
            'left': round(self.left, 1),
            'right': round(self.right, 1),
        }

    @classmethod
    def from_dict(cls, d):
        return cls(
            top=d['top'],
            bottom=d['bottom'],
            left=d['left'],
            right=d['right'],
        )


def detect_content_bounds(pdf_path: str, padding: float = 20.0) -> Optional[CropBounds]:
    """
    Detect content bounds for a PDF by analyzing pixel content.

    Args:
        pdf_path: Path to the PDF file
        padding: Extra padding to add around detected content (in points)

    Returns:
        CropBounds with the amount to trim from each edge, or None if detection fails
    """
    try:
        doc = fitz.open(pdf_path)
        if doc.page_count == 0:
            return None

        # Analyze first page (assumes consistent margins across pages)
        page = doc[0]
        media_box = page.mediabox  # Full page size

        # Render at 72 DPI (1:1 with PDF points)
        pix = page.get_pixmap(dpi=72)
        width, height = pix.width, pix.height

        # Get pixel data
        samples = pix.samples  # Raw pixel bytes (RGB or RGBA)
        stride = pix.stride
        n = pix.n  # Components per pixel (3 for RGB, 4 for RGBA)

        # Find content bounds by scanning for non-white pixels
        # White threshold (allow near-white for antialiasing)
        threshold = 250

        min_x, min_y = width, height
        max_x, max_y = 0, 0

        for y in range(height):
            for x in range(width):
                idx = y * stride + x * n
                r, g, b = samples[idx], samples[idx + 1], samples[idx + 2]

                # Check if pixel is "content" (not white)
                if r < threshold or g < threshold or b < threshold:
                    min_x = min(min_x, x)
                    max_x = max(max_x, x)
                    min_y = min(min_y, y)
                    max_y = max(max_y, y)

        doc.close()

        # If no content found, return None
        if max_x <= min_x or max_y <= min_y:
            return None

        # Calculate trim amounts (how much to remove from each edge)
        # Add padding to keep some whitespace around content
        crop = CropBounds(
            top=max(0, min_y - padding),
            bottom=max(0, height - max_y - padding),
            left=max(0, min_x - padding),
            right=max(0, width - max_x - padding),
        )

        return crop

    except Exception as e:
        print(f"Error detecting content bounds: {e}")
        return None


def detect_content_bounds_fast(pdf_path: str, padding: float = 20.0) -> Optional[CropBounds]:
    """
    Faster version that samples rows/columns instead of every pixel.
    Good enough for sheet music with clear margins.
    """
    try:
        doc = fitz.open(pdf_path)
        if doc.page_count == 0:
            return None

        page = doc[0]

        # Render at lower DPI for speed
        pix = page.get_pixmap(dpi=36)  # Half resolution
        width, height = pix.width, pix.height
        samples = pix.samples
        stride = pix.stride
        n = pix.n

        threshold = 250

        # Find top edge (first row with content)
        top_trim = 0
        for y in range(height):
            has_content = False
            for x in range(0, width, 4):  # Sample every 4th pixel
                idx = y * stride + x * n
                if samples[idx] < threshold or samples[idx + 1] < threshold or samples[idx + 2] < threshold:
                    has_content = True
                    break
            if has_content:
                top_trim = y
                break

        # Find bottom edge (last row with content)
        bottom_trim = 0
        for y in range(height - 1, -1, -1):
            has_content = False
            for x in range(0, width, 4):
                idx = y * stride + x * n
                if samples[idx] < threshold or samples[idx + 1] < threshold or samples[idx + 2] < threshold:
                    has_content = True
                    break
            if has_content:
                bottom_trim = height - 1 - y
                break

        # Find left edge
        left_trim = 0
        for x in range(width):
            has_content = False
            for y in range(0, height, 4):
                idx = y * stride + x * n
                if samples[idx] < threshold or samples[idx + 1] < threshold or samples[idx + 2] < threshold:
                    has_content = True
                    break
            if has_content:
                left_trim = x
                break

        # Find right edge
        right_trim = 0
        for x in range(width - 1, -1, -1):
            has_content = False
            for y in range(0, height, 4):
                idx = y * stride + x * n
                if samples[idx] < threshold or samples[idx + 1] < threshold or samples[idx + 2] < threshold:
                    has_content = True
                    break
            if has_content:
                right_trim = width - 1 - x
                break

        doc.close()

        # Scale back to full resolution (72 DPI) and add padding
        scale = 2  # We rendered at 36 DPI, PDF is 72 DPI
        crop = CropBounds(
            top=max(0, (top_trim * scale) - padding),
            bottom=max(0, (bottom_trim * scale) - padding),
            left=max(0, (left_trim * scale) - padding),
            right=max(0, (right_trim * scale) - padding),
        )

        return crop

    except Exception as e:
        print(f"Error detecting content bounds: {e}")
        return None


# Use the fast version by default
detect_bounds = detect_content_bounds_fast
