import { useState, useEffect, useRef } from 'react';
import { Document, Page, pdfjs } from 'react-pdf';
import { FiX, FiZoomIn, FiZoomOut, FiMaximize, FiMinimize, FiChevronLeft, FiChevronRight } from 'react-icons/fi';
import type { Variation } from '@/types/catalog';
import { api } from '@/services/api';

// Set up worker - use unpkg CDN
pdfjs.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${pdfjs.version}/build/pdf.worker.min.mjs`;

interface ExtendedVariation extends Variation {
  directUrl?: string;
}

interface PDFViewerProps {
  variation: ExtendedVariation;
  onClose: () => void;
}

export function PDFViewer({ variation, onClose }: PDFViewerProps) {
  const [numPages, setNumPages] = useState<number>(0);
  const [scale, setScale] = useState(1.5);
  const [error, setError] = useState<string | null>(null);
  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [isLandscape, setIsLandscape] = useState(
    window.innerWidth > window.innerHeight
  );
  const [touchStart, setTouchStart] = useState<number | null>(null);
  const [touchEnd, setTouchEnd] = useState<number | null>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [swipeDirection, setSwipeDirection] = useState<'left' | 'right' | null>(null);
  const [showNav, setShowNav] = useState(true); // Nav visibility state
  const [headerTouchStart, setHeaderTouchStart] = useState<number | null>(null);
  const [lastPinchDistance, setLastPinchDistance] = useState<number | null>(null);
  
  const containerRef = useRef<HTMLDivElement>(null);
  const inactivityTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Fetch PDF URL when component mounts or variation changes
  useEffect(() => {
    let mounted = true;

    async function loadPDF() {
      try {
        setLoading(true);
        setError(null);

        // If directUrl is provided (generated PDF), use it directly
        if (variation.directUrl) {
          if (mounted) {
            setPdfUrl(variation.directUrl);
            setLoading(false);
          }
          return;
        }

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
      if (pdfUrl && pdfUrl.startsWith('blob:')) {
        URL.revokeObjectURL(pdfUrl);
      }
    };
  }, [variation.filename]);

  // Calculate optimal scale based on viewport height and width
  const calculateOptimalScale = () => {
    const isLandscapeNow = window.innerWidth > window.innerHeight;
    
    // Standard letter size PDF page: 8.5" x 11" at 72 DPI = 612 x 792 pixels
    const standardPageWidth = 612;
    const standardPageHeight = 792;
    
    // Account for header and padding
    const availableHeight = window.innerHeight - 140;
    const availableWidth = window.innerWidth; // Use full width, no padding
    
    // Calculate scale based on height
    const heightScale = availableHeight / standardPageHeight;
    
    // In landscape mode, consider width for 2 pages side-by-side
    if (isLandscapeNow) {
      const widthScale = availableWidth / (standardPageWidth * 2 + 4); // 2 pages + small gap
      // Use the smaller of the two scales, with slight boost to fill screen
      return Math.min(Math.max(Math.min(heightScale, widthScale) * 1.05, 0.8), 3.0);
    } else {
      // Portrait mode: just use height scale
      return Math.min(Math.max(heightScale * 1.05, 0.8), 3.0);
    }
  };

  // Update scale on orientation change
  useEffect(() => {
    const handleResize = () => {
      const wasLandscape = isLandscape;
      const nowLandscape = window.innerWidth > window.innerHeight;
      setIsLandscape(nowLandscape);
      
      // Recalculate scale when orientation changes
      if (wasLandscape !== nowLandscape) {
        const newScale = calculateOptimalScale();
        setScale(newScale);
        console.log('[PDFViewer] Orientation changed, new scale:', newScale);
      }
    };

    window.addEventListener('resize', handleResize);
    window.addEventListener('orientationchange', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('orientationchange', handleResize);
    };
  }, [isLandscape]);

  // Fullscreen change listener
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };

    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
    };
  }, []);

  // Auto-hide navigation after 2 seconds of inactivity
  const resetInactivityTimer = () => {
    // Show nav on any interaction
    setShowNav(true);

    // Clear existing timer
    if (inactivityTimerRef.current) {
      clearTimeout(inactivityTimerRef.current);
    }

    // Set new timer to hide after 2 seconds
    inactivityTimerRef.current = setTimeout(() => {
      setShowNav(false);
    }, 2000);
  };

  // Track user interaction to show/hide nav
  useEffect(() => {
    const handleInteraction = () => {
      resetInactivityTimer();
    };

    // Listen for mouse movement, touch, and clicks
    window.addEventListener('mousemove', handleInteraction);
    window.addEventListener('touchstart', handleInteraction);
    window.addEventListener('click', handleInteraction);

    // Start the initial timer
    resetInactivityTimer();

    return () => {
      window.removeEventListener('mousemove', handleInteraction);
      window.removeEventListener('touchstart', handleInteraction);
      window.removeEventListener('click', handleInteraction);
      if (inactivityTimerRef.current) {
        clearTimeout(inactivityTimerRef.current);
      }
    };
  }, []);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyPress = (e: KeyboardEvent) => {
      const pagesPerView = isLandscape ? 2 : 1;

      switch (e.key) {
        case 'ArrowLeft':
          e.preventDefault();
          if (currentPage > 1) {
            setSwipeDirection('right');
            setCurrentPage((prev) => Math.max(prev - pagesPerView, 1));
            setTimeout(() => setSwipeDirection(null), 200);
          }
          resetInactivityTimer(); // Show nav briefly when using keyboard
          break;
        case 'ArrowRight':
          e.preventDefault();
          if (currentPage + pagesPerView <= numPages) {
            setSwipeDirection('left');
            setCurrentPage((prev) => Math.min(prev + pagesPerView, numPages - pagesPerView + 1));
            setTimeout(() => setSwipeDirection(null), 200);
          }
          resetInactivityTimer(); // Show nav briefly when using keyboard
          break;
        case 'Escape':
          e.preventDefault();
          if (isFullscreen) {
            exitFullscreen();
          } else {
            onClose();
          }
          break;
        case 'f':
        case 'F':
          e.preventDefault();
          toggleFullscreen();
          break;
      }
    };

    window.addEventListener('keydown', handleKeyPress);
    return () => {
      window.removeEventListener('keydown', handleKeyPress);
    };
  }, [currentPage, numPages, isLandscape, isFullscreen, onClose]);

  function onDocumentLoadSuccess({ numPages }: { numPages: number }) {
    setNumPages(numPages);
    setError(null);
    
    // Calculate and set optimal scale when PDF loads
    const optimalScale = calculateOptimalScale();
    setScale(optimalScale);
    
    console.log('[PDFViewer] PDF loaded successfully, pages:', numPages, 'scale:', optimalScale);
  }

  function onDocumentLoadError(error: Error) {
    console.error('[PDFViewer] Error loading PDF:', error);
    setError(error.message);
  }

  const handleZoomIn = () => setScale((prev) => Math.min(prev + 0.25, 3));
  const handleZoomOut = () => setScale((prev) => Math.max(prev - 0.25, 0.5));

  const toggleFullscreen = async () => {
    try {
      if (!isFullscreen) {
        await containerRef.current?.requestFullscreen();
      } else {
        await document.exitFullscreen();
      }
    } catch (err) {
      console.error('Fullscreen error:', err);
    }
  };

  const exitFullscreen = async () => {
    try {
      if (document.fullscreenElement) {
        await document.exitFullscreen();
      }
    } catch (err) {
      console.error('Exit fullscreen error:', err);
    }
  };

  // Helper function to get distance between two touch points
  const getDistance = (touch1: React.Touch, touch2: React.Touch) => {
    const dx = touch1.clientX - touch2.clientX;
    const dy = touch1.clientY - touch2.clientY;
    return Math.sqrt(dx * dx + dy * dy);
  };

  // Swipe gesture handling with pinch zoom detection
  const minSwipeDistance = 50;

  const onTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 2) {
      // Pinch zoom start
      const distance = getDistance(e.touches[0], e.touches[1]);
      setLastPinchDistance(distance);
    } else if (e.touches.length === 1) {
      // Single touch for swipe
      setTouchEnd(null);
      setTouchStart(e.targetTouches[0].clientX);
    }
  };

  const onTouchMove = (e: React.TouchEvent) => {
    if (e.touches.length === 2) {
      // Continuous pinch zoom
      const distance = getDistance(e.touches[0], e.touches[1]);
      if (lastPinchDistance) {
        const rawScaleChange = distance / lastPinchDistance;
        // Amplify the scale change for better sensitivity
        const amplifiedChange = 1 + (rawScaleChange - 1) * 2.5;
        
        // Update the actual scale directly for continuous zoom
        setScale(prev => {
          const newScale = prev * amplifiedChange;
          // Limit zoom between 0.3x and 5x for wider range
          return Math.min(Math.max(newScale, 0.3), 5.0);
        });
      }
      // Always update last distance for continuous tracking
      setLastPinchDistance(distance);
    } else if (e.touches.length === 1) {
      // Single touch for swipe
      setTouchEnd(e.targetTouches[0].clientX);
    }
  };

  const onTouchEnd = () => {
    // Reset pinch tracking
    setLastPinchDistance(null);
    
    // Handle swipe if it was a single touch
    if (!touchStart || !touchEnd) return;

    const distance = touchStart - touchEnd;
    const isLeftSwipe = distance > minSwipeDistance;
    const isRightSwipe = distance < -minSwipeDistance;

    const pagesPerView = isLandscape ? 2 : 1;
    const canSwipe = isLandscape ? numPages > 2 : numPages > 1;

    if (!canSwipe) return;

    if (isLeftSwipe && currentPage + pagesPerView <= numPages) {
      setSwipeDirection('left');
      setCurrentPage((prev) => Math.min(prev + pagesPerView, numPages - pagesPerView + 1));
      setTimeout(() => setSwipeDirection(null), 200);
    }

    if (isRightSwipe && currentPage > 1) {
      setSwipeDirection('right');
      setCurrentPage((prev) => Math.max(prev - pagesPerView, 1));
      setTimeout(() => setSwipeDirection(null), 200);
    }
  };

  // Handle swipe-up gesture on header to hide nav
  const onHeaderTouchStart = (e: React.TouchEvent) => {
    setHeaderTouchStart(e.targetTouches[0].clientY);
  };

  const onHeaderTouchEnd = (e: React.TouchEvent) => {
    if (!headerTouchStart) return;

    const touchEndY = e.changedTouches[0].clientY;
    const distance = headerTouchStart - touchEndY;

    // Swipe up (distance > 0) to hide nav
    if (distance > 30) {
      setShowNav(false);
      if (inactivityTimerRef.current) {
        clearTimeout(inactivityTimerRef.current);
      }
    }

    setHeaderTouchStart(null);
  };

  // Slider change handler
  const handleSliderChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newPage = parseInt(e.target.value);
    setCurrentPage(newPage);
  };

  const pagesPerView = isLandscape ? 2 : 1;
  const canNavigate = isLandscape ? numPages > 2 : numPages > 1;

  return (
    <div ref={containerRef} className="fixed inset-0 bg-black z-50 flex flex-col">
      {/* Header - slides down when showNav is true */}
      <div
        className={`bg-white/10 backdrop-blur-lg px-2 py-2 flex items-center justify-between border-b border-white/10 transition-transform duration-300 ${
          showNav ? 'translate-y-0' : '-translate-y-full'
        }`}
        onTouchStart={onHeaderTouchStart}
        onTouchEnd={onHeaderTouchEnd}
      >
        <div className="flex-1 min-w-0 mr-2">
          <h2 className="text-base font-semibold text-white leading-tight">
            {variation.display_name}
          </h2>
          {numPages > 0 && (
            <p className="text-xs text-gray-400">{numPages} page{numPages !== 1 ? 's' : ''}</p>
          )}
        </div>

        {/* Controls */}
        <div className="flex items-center gap-3 ml-4">
          {/* Zoom Controls */}
          <div className="hidden sm:flex items-center gap-2">
            <button
              onClick={handleZoomOut}
              className="p-2 bg-white/10 hover:bg-white/20 rounded-mcm transition-colors"
              aria-label="Zoom out"
            >
              <FiZoomOut className="text-white text-lg" />
            </button>
            <span className="text-white text-sm min-w-[3.5rem] text-center">
              {Math.round(scale * 100)}%
            </span>
            <button
              onClick={handleZoomIn}
              className="p-2 bg-white/10 hover:bg-white/20 rounded-mcm transition-colors"
              aria-label="Zoom in"
            >
              <FiZoomIn className="text-white text-lg" />
            </button>
          </div>

          {/* Fullscreen Button */}
          <button
            onClick={toggleFullscreen}
            className="p-2 bg-white/10 hover:bg-white/20 rounded-mcm transition-colors"
            aria-label={isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen'}
          >
            {isFullscreen ? (
              <FiMinimize className="text-white text-lg" />
            ) : (
              <FiMaximize className="text-white text-lg" />
            )}
          </button>

          {/* Close Button */}
          <button
            onClick={onClose}
            className="px-4 py-2 bg-blue-500 hover:bg-blue-600 rounded-mcm text-white font-medium transition-colors flex items-center gap-2"
          >
            <FiX className="text-lg" />
            <span className="hidden sm:inline">Close</span>
          </button>
        </div>
      </div>

      {/* PDF Content */}
      <div
        className="flex-1 overflow-hidden flex items-center justify-center"
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
      >
        {error ?  (
          <div className="flex items-center justify-center h-full">
            <div className="text-center max-w-md">
              <p className="text-red-400 text-lg font-semibold mb-2">⚠️ Error</p>
              <p className="text-gray-300">{error}</p>
              <button
                onClick={onClose}
                className="mt-4 px-6 py-2 bg-blue-500 hover:bg-blue-600 rounded-mcm text-white transition-colors"
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
          <>
            {/* Swipe Indicators */}
            {canNavigate && currentPage > 1 && (
              <div className="absolute left-4 top-1/2 -translate-y-1/2 z-10 pointer-events-none">
                <FiChevronLeft className="text-white/40 text-4xl animate-pulse" />
              </div>
            )}
            {canNavigate && currentPage + pagesPerView <= numPages && (
              <div className="absolute right-4 top-1/2 -translate-y-1/2 z-10 pointer-events-none">
                <FiChevronRight className="text-white/40 text-4xl animate-pulse" />
              </div>
            )}

            <div className="h-full flex flex-col items-center justify-center">
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
                <div
                  className={`flex ${isLandscape ? 'flex-row gap-1' : 'flex-col'} items-center justify-center transition-all duration-200 ${
                    swipeDirection === 'left' ? 'animate-slide-left' : swipeDirection === 'right' ? 'animate-slide-right' : ''
                  }`}
                >
                  <Page
                    key={`page_${currentPage}`}
                    pageNumber={currentPage}
                    scale={scale}
                    className="shadow-2xl"
                    renderTextLayer={false}
                    renderAnnotationLayer={false}
                  />

                  {isLandscape && currentPage + 1 <= numPages && (
                    <Page
                      key={`page_${currentPage + 1}`}
                      pageNumber={currentPage + 1}
                      scale={scale}
                      className="shadow-2xl"
                      renderTextLayer={false}
                      renderAnnotationLayer={false}
                    />
                  )}
                </div>
              </Document>

              {/* Finger Slider + Page Indicator */}
              {canNavigate && (
                <div className="mt-6 w-full max-w-md px-4">
                  <input
                    type="range"
                    min="1"
                    max={numPages - pagesPerView + 1}
                    value={currentPage}
                    onChange={handleSliderChange}
                    className="w-full h-2 bg-white/20 rounded-full appearance-none cursor-pointer slider-thumb"
                    style={{
                      background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${((currentPage - 1) / (numPages - pagesPerView)) * 100}%, rgba(255,255,255,0.2) ${((currentPage - 1) / (numPages - pagesPerView)) * 100}%, rgba(255,255,255,0.2) 100%)`
                    }}
                  />
                  <div className="text-center mt-3">
                    <span className="text-white text-sm">
                      {isLandscape && currentPage + 1 <= numPages
                        ? `Pages ${currentPage}-${currentPage + 1} of ${numPages}`
                        : `Page ${currentPage} of ${numPages}`}
                    </span>
                  </div>
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
