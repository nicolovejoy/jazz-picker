import { useEffect, useRef, useState } from 'react';
import * as pdfjsLib from 'pdfjs-dist';
import { FiX, FiZoomIn, FiZoomOut } from 'react-icons/fi';
import type { Variation } from '@/types/catalog';
import { api } from '@/services/api';

// Set up PDF.js worker
pdfjsLib.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version}/pdf.worker.min.js`;

interface PDFViewerProps {
  variation: Variation;
  onClose: () => void;
}

export function PDFViewer({ variation, onClose }: PDFViewerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [scale, setScale] = useState(1.5);
  const [numPages, setNumPages] = useState(0);

  useEffect(() => {
    let isMounted = true;

    async function loadPDF() {
      try {
        setLoading(true);
        setError(null);

        // Fetch PDF blob from API
        const blob = await api.getPDF(variation.filename);
        const url = URL.createObjectURL(blob);

        // Load PDF document
        const loadingTask = pdfjsLib.getDocument(url);
        const pdf = await loadingTask.promise;

        if (!isMounted) {
          URL.revokeObjectURL(url);
          return;
        }

        setNumPages(pdf.numPages);

        // Clear container
        if (containerRef.current) {
          containerRef.current.innerHTML = '';
        }

        // Render all pages
        for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
          const page = await pdf.getPage(pageNum);

          const viewport = page.getViewport({ scale });

          // Create canvas element
          const canvas = document.createElement('canvas');
          canvas.className = 'pdf-page-canvas mx-auto mb-4 shadow-2xl';
          const context = canvas.getContext('2d');

          if (!context) continue;

          canvas.height = viewport.height;
          canvas.width = viewport.width;

          // Render PDF page into canvas
          const renderContext = {
            canvasContext: context,
            viewport: viewport,
          };

          await page.render(renderContext as any).promise;

          if (containerRef.current && isMounted) {
            containerRef.current.appendChild(canvas);
          }
        }

        setLoading(false);
        URL.revokeObjectURL(url);
      } catch (err) {
        console.error('Error loading PDF:', err);
        if (isMounted) {
          setError(err instanceof Error ? err.message : 'Failed to load PDF');
          setLoading(false);
        }
      }
    }

    loadPDF();

    return () => {
      isMounted = false;
    };
  }, [variation.filename, scale]);

  const handleZoomIn = () => setScale((prev) => Math.min(prev + 0.25, 3));
  const handleZoomOut = () => setScale((prev) => Math.max(prev - 0.25, 0.5));

  return (
    <div className="fixed inset-0 bg-black/95 z-50 flex flex-col">
      {/* Header */}
      <div className="bg-white/10 backdrop-blur-lg px-4 py-3 flex items-center justify-between border-b border-white/10">
        <div className="flex-1">
          <h2 className="text-lg font-semibold text-white truncate">
            {variation.display_name}
          </h2>
          {numPages > 0 && (
            <p className="text-sm text-gray-400">{numPages} page{numPages !== 1 ? 's' : ''}</p>
          )}
        </div>

        {/* Zoom Controls */}
        <div className="flex items-center gap-2 mx-4">
          <button
            onClick={handleZoomOut}
            className="p-2 bg-white/10 hover:bg-white/20 rounded-lg transition-colors"
            aria-label="Zoom out"
          >
            <FiZoomOut className="text-white text-xl" />
          </button>
          <span className="text-white text-sm min-w-[4rem] text-center">
            {Math.round(scale * 100)}%
          </span>
          <button
            onClick={handleZoomIn}
            className="p-2 bg-white/10 hover:bg-white/20 rounded-lg transition-colors"
            aria-label="Zoom in"
          >
            <FiZoomIn className="text-white text-xl" />
          </button>
        </div>

        {/* Close Button */}
        <button
          onClick={onClose}
          className="px-4 py-2 bg-blue-500 hover:bg-blue-600 rounded-lg text-white font-medium transition-colors flex items-center gap-2"
        >
          <FiX className="text-xl" />
          <span className="hidden sm:inline">Close</span>
        </button>
      </div>

      {/* PDF Content */}
      <div className="flex-1 overflow-auto p-4 md:p-8 scrollbar-thin">
        {loading && (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400 mx-auto mb-4"></div>
              <p className="text-gray-400 text-lg">Loading PDF...</p>
              <p className="text-gray-500 text-sm mt-2">This may take 10-20 seconds</p>
            </div>
          </div>
        )}

        {error && (
          <div className="flex items-center justify-center h-full">
            <div className="text-center max-w-md">
              <p className="text-red-400 text-lg font-semibold mb-2">⚠️ Error</p>
              <p className="text-gray-300">{error}</p>
              <button
                onClick={onClose}
                className="mt-4 px-6 py-2 bg-blue-500 hover:bg-blue-600 rounded-lg text-white transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        )}

        {!loading && !error && (
          <div ref={containerRef} className="max-w-5xl mx-auto" />
        )}
      </div>
    </div>
  );
}
