/**
 * Crop bounds for PDF content detection.
 * Values represent points to trim from each edge.
 */
export interface CropBounds {
  top: number;
  bottom: number;
  left: number;
  right: number;
}
