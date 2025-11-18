import { useState, useEffect } from 'react';
import { Document, Page, pdfjs } from 'react-pdf';
import { FiX, FiZoomIn, FiZoomOut } from 'react-icons/fi';
import type { Variation } from '@/types/catalog';
import { api } from '@/services/api';

// Set up worker - use unpkg CDN
pdfjs.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${pdfjs.version}/build/pdf.worker.min.mjs`;

interface PDFViewerProps {
  variation: Variation;
  onClose: () => void;
}

export function PDFViewer({ variation, onClose }: PDFViewerProps) {
  const [numPages, setNumPages] = useState<number>(0);
  const [scale, setScale] = useState(1.5);
  const [error, setError] = useState<string | null>(null);
  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Fetch PDF URL when component mounts or variation changes
  useEffect(() => {
    let mounted = true;

    async function loadPDF() {
      try {
        setLoading(true);
        setError(null);
        console.log('[PDFViewer] Fetching PDF for:', variation.filename);

        const url = await api.getPDF(variation.filename);

        if (mounted) {
          console.log('[PDFViewer] PDF URL received:', url);
          setPdfUrl(url);
          setLoading(false);
        }
      } catch (err) {
        if (mounted) {
          console.error('[PDFViewer] Failed to load PDF:', err);
          setError(err instanceof Error ? err.message : 'Failed to load PDF');
          setLoading(false);
        }
      }
    }

    loadPDF();

    return () => {
      mounted = false;
      // Clean up object URL if it was created
      if (pdfUrl && pdfUrl.startsWith('blob:')) {
        URL.revokeObjectURL(pdfUrl);
      }
    };
  }, [variation.filename]);

  function onDocumentLoadSuccess({ numPages }: { numPages: number }) {
    setNumPages(numPages);
    setError(null);
    console.log('[PDFViewer] PDF loaded successfully, pages:', numPages);
  }

  function onDocumentLoadError(error: Error) {
    console.error('[PDFViewer] Error loading PDF:', error);
    setError(error.message);
  }

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
        {error ? (
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
        ) : loading || !pdfUrl ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400 mx-auto mb-4"></div>
              <p className="text-gray-400 text-lg">Loading PDF...</p>
              <p className="text-gray-500 text-sm mt-2">This may take a few seconds</p>
            </div>
          </div>
        ) : (
          <div className="max-w-5xl mx-auto">
            <Document
              file={pdfUrl}
              onLoadSuccess={onDocumentLoadSuccess}
              onLoadError={onDocumentLoadError}
              loading={
                <div className="flex items-center justify-center h-64">
                  <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400 mx-auto mb-4"></div>
                    <p className="text-gray-400 text-lg">Rendering PDF...</p>
                  </div>
                </div>
              }
            >
              {Array.from(new Array(numPages), (_el, index) => (
                <Page
                  key={`page_${index + 1}`}
                  pageNumber={index + 1}
                  scale={scale}
                  className="mb-4 shadow-2xl mx-auto"
                  renderTextLayer={false}
                  renderAnnotationLayer={false}
                />
              ))}
            </Document>
          </div>
        )}
      </div>
    </div>
  );
}
