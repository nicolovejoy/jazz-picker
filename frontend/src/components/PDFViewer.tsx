import { useState, useEffect, useRef } from 'react';
import { Document, Page, pdfjs } from 'react-pdf';
import { FiX, FiZoomIn, FiZoomOut, FiMaximize, FiMinimize, FiChevronLeft, FiChevronRight, FiDownload, FiFilePlus, FiChevronsUp, FiMoreVertical, FiPlus, FiCheck } from 'react-icons/fi';
import type { PdfMetadata, SetlistNavigation } from '../App';
import type { Instrument } from '@/types/catalog';
import { TransposeModal } from './TransposeModal';
import { useSetlists } from '@/contexts/SetlistContext';

// Set up worker - use local import for Vite
pdfjs.GlobalWorkerOptions.workerSrc = new URL(
  'pdfjs-dist/build/pdf.worker.min.mjs',
  import.meta.url,
).toString();

interface PDFViewerProps {
  pdfUrl: string;
  metadata?: PdfMetadata | null;
  setlistNav?: SetlistNavigation | null;
  isTransitioning?: boolean;
  onClose: () => void;
  instrument?: Instrument;
  onKeyChange?: (url: string, newKey: string) => void;
}

export function PDFViewer({ pdfUrl, metadata, setlistNav, isTransitioning, onClose, instrument, onKeyChange }: PDFViewerProps) {
  const [numPages, setNumPages] = useState<number>(0);
  const [scale, setScale] = useState(1.5);
  const [showTransposeModal, setShowTransposeModal] = useState(false);
  const [showOverflowMenu, setShowOverflowMenu] = useState(false);
  const [showAddToSetlistMenu, setShowAddToSetlistMenu] = useState(false);
  const [addingToSetlistId, setAddingToSetlistId] = useState<string | null>(null);
  const [addedToSetlistId, setAddedToSetlistId] = useState<string | null>(null);

  const { setlists, addItem } = useSetlists();
  const [error, setError] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [isLandscape, setIsLandscape] = useState(
    window.innerWidth > window.innerHeight
  );
  const [touchStart, setTouchStart] = useState<number | null>(null);
  const [touchEnd, setTouchEnd] = useState<number | null>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [swipeDirection, setSwipeDirection] = useState<'left' | 'right' | null>(null);
  const [showNav, setShowNav] = useState(true); // Nav visibility state
  const [lastPinchDistance, setLastPinchDistance] = useState<number | null>(null);
  
  const containerRef = useRef<HTMLDivElement>(null);
  const inactivityTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Calculate optimal scale based on viewport height and width
  const calculateOptimalScale = () => {
    const isLandscapeNow = window.innerWidth > window.innerHeight;

    // Standard letter size PDF page: 8.5" x 11" at 72 DPI = 612 x 792 pixels
    const standardPageWidth = 612;
    const standardPageHeight = 792;

    // Account for minimal header space
    const availableHeight = window.innerHeight - 60;
    const availableWidth = window.innerWidth; // Use full width, no padding

    // Calculate scale based on height
    const heightScale = availableHeight / standardPageHeight;

    // In landscape mode, consider width for 2 pages side-by-side
    if (isLandscapeNow) {
      const widthScale = availableWidth / (standardPageWidth * 2); // 2 pages, no gap
      // Add 4% boost to default size
      return Math.min(Math.max(Math.min(heightScale, widthScale) * 1.04, 0.8), 3.0);
    } else {
      // Portrait mode: just use height scale, add 4% boost
      return Math.min(Math.max(heightScale * 1.04, 0.8), 3.0);
    }
  };

  // Reset state when PDF changes
  useEffect(() => {
    setCurrentPage(1);
    setNumPages(0);
    setError(null);
  }, [pdfUrl]);

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

  // Wake Lock
  useEffect(() => {
    let wakeLock: WakeLockSentinel | null = null;

    const requestWakeLock = async () => {
      try {
        if ('wakeLock' in navigator) {
          wakeLock = await navigator.wakeLock.request('screen');
          console.log('[PDFViewer] Wake Lock active');
        }
      } catch (err) {
        console.error('[PDFViewer] Wake Lock failed:', err);
      }
    };

    requestWakeLock();

    // Re-request wake lock when visibility changes (e.g. switching tabs)
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        requestWakeLock();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      if (wakeLock) {
        wakeLock.release().catch(console.error);
        console.log('[PDFViewer] Wake Lock released');
      }
      document.removeEventListener('visibilitychange', handleVisibilityChange);
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
            // Go to previous page
            setSwipeDirection('right');
            setCurrentPage((prev) => Math.max(prev - pagesPerView, 1));
            setTimeout(() => setSwipeDirection(null), 200);
          } else if (setlistNav && setlistNav.currentIndex > 0) {
            // At first page - go to previous song in setlist
            setlistNav.onPrevSong();
          }
          resetInactivityTimer();
          break;
        case 'ArrowRight':
          e.preventDefault();
          if (currentPage + pagesPerView <= numPages) {
            // Go to next page
            setSwipeDirection('left');
            setCurrentPage((prev) => Math.min(prev + pagesPerView, numPages - pagesPerView + 1));
            setTimeout(() => setSwipeDirection(null), 200);
          } else if (setlistNav && setlistNav.currentIndex < setlistNav.totalSongs - 1) {
            // At last page - go to next song in setlist
            setlistNav.onNextSong();
          }
          resetInactivityTimer();
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
  }, [currentPage, numPages, isLandscape, isFullscreen, onClose, setlistNav]);

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

  const handleDownload = async () => {
    try {
      // Generate filename from metadata or fallback
      const filename = metadata
        ? `${metadata.songTitle} - ${metadata.key.toUpperCase()}.pdf`
        : 'lead-sheet.pdf';

      // If it's a blob URL, we can use it directly
      if (pdfUrl.startsWith('blob:')) {
        const a = document.createElement('a');
        a.href = pdfUrl;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
      } else {
        // For S3 presigned URLs, fetch and create blob
        const response = await fetch(pdfUrl);
        const blob = await response.blob();
        const blobUrl = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = blobUrl;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(blobUrl);
      }
    } catch (err) {
      console.error('Download error:', err);
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
    const canSwipePages = isLandscape ? numPages > 2 : numPages > 1;
    const isAtFirstPage = currentPage === 1;
    const isAtLastPage = currentPage + pagesPerView > numPages;

    // Handle setlist navigation when at boundaries
    if (setlistNav) {
      if (isRightSwipe && isAtFirstPage) {
        // Swipe right at first page -> previous song
        setlistNav.onPrevSong();
        return;
      }
      if (isLeftSwipe && isAtLastPage) {
        // Swipe left at last page -> next song
        setlistNav.onNextSong();
        return;
      }
    }

    if (!canSwipePages) return;

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

  // Slider change handler
  const handleSliderChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newPage = parseInt(e.target.value);
    setCurrentPage(newPage);
  };

  const pagesPerView = isLandscape ? 2 : 1;
  const canNavigate = isLandscape ? numPages > 2 : numPages > 1;

  return (
    <div ref={containerRef} className="fixed inset-0 bg-white z-50 flex flex-col">
      {/* Safe area spacer */}
      <div className="flex-shrink-0 bg-white" style={{ height: 'env(safe-area-inset-top, 0px)' }} />

      {/* Floating Controls */}
      <div
        className={`absolute top-4 right-4 flex items-center gap-2 transition-opacity duration-300 z-50 ${
          showNav ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        style={{ top: 'calc(env(safe-area-inset-top, 0px) + 1rem)' }}
      >
        {/* Primary Actions */}
        <div className="flex items-center bg-black/60 backdrop-blur-md rounded-full p-1 border border-white/10">
          {instrument && onKeyChange && metadata && (
            <button
              onClick={() => setShowTransposeModal(true)}
              className="p-2 hover:bg-white/20 rounded-full transition-colors"
              aria-label="Transpose"
              title="Transpose"
            >
              <FiChevronsUp className="text-white text-lg" />
            </button>
          )}

          {metadata && (
            <div
              className="relative"
              onMouseEnter={() => setShowAddToSetlistMenu(true)}
              onMouseLeave={() => {
                setShowAddToSetlistMenu(false);
                setAddedToSetlistId(null);
              }}
            >
              <button
                className="p-2 hover:bg-white/20 rounded-full transition-colors"
                aria-label="Add to Setlist"
              >
                <FiFilePlus className="text-white text-lg" />
              </button>

              {showAddToSetlistMenu && (
                <div className="absolute top-full right-0 mt-1 bg-gray-900 border border-white/20 rounded-lg shadow-xl overflow-hidden min-w-[200px] max-h-[300px] overflow-y-auto">
                  <div className="px-3 py-2 border-b border-white/10 text-xs text-gray-400 uppercase tracking-wide">
                    Add to Setlist
                  </div>
                  {setlists.length === 0 ? (
                    <div className="px-3 py-4 text-gray-500 text-sm text-center">
                      No setlists yet
                    </div>
                  ) : (
                    setlists.map(setlist => (
                      <button
                        key={setlist.id}
                        onClick={async () => {
                          if (addedToSetlistId === setlist.id) return;
                          setAddingToSetlistId(setlist.id);
                          try {
                            await addItem(setlist.id, {
                              songTitle: metadata.songTitle,
                              concertKey: metadata.key,
                            });
                            setAddedToSetlistId(setlist.id);
                            setTimeout(() => {
                              setShowAddToSetlistMenu(false);
                              setAddedToSetlistId(null);
                            }, 600);
                          } catch (err) {
                            console.error('Failed to add to setlist:', err);
                          } finally {
                            setAddingToSetlistId(null);
                          }
                        }}
                        disabled={addingToSetlistId === setlist.id}
                        className="w-full flex items-center justify-between gap-3 px-3 py-2.5 text-white hover:bg-white/10 transition-colors text-left"
                      >
                        <span className="text-sm truncate">{setlist.name}</span>
                        {addingToSetlistId === setlist.id ? (
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-400 flex-shrink-0"></div>
                        ) : addedToSetlistId === setlist.id ? (
                          <FiCheck className="text-green-400 flex-shrink-0" />
                        ) : (
                          <FiPlus className="text-gray-400 flex-shrink-0" />
                        )}
                      </button>
                    ))
                  )}
                </div>
              )}
            </div>
          )}

          {/* Overflow Menu */}
          <div
            className="relative"
            onMouseEnter={() => setShowOverflowMenu(true)}
            onMouseLeave={() => setShowOverflowMenu(false)}
          >
            <button
              className="p-2 hover:bg-white/20 rounded-full transition-colors"
              aria-label="More options"
            >
              <FiMoreVertical className="text-white text-lg" />
            </button>

            {showOverflowMenu && (
              <div className="absolute top-full right-0 mt-1 bg-gray-900 border border-white/20 rounded-lg shadow-xl overflow-hidden min-w-[160px]">
                {/* Zoom Controls */}
                <div className="flex items-center justify-between px-3 py-2 border-b border-white/10">
                  <button
                    onClick={handleZoomOut}
                    className="p-1.5 hover:bg-white/10 rounded transition-colors"
                    aria-label="Zoom out"
                    title="Zoom out"
                  >
                    <FiZoomOut className="text-white" />
                  </button>
                  <span className="text-white text-sm font-medium">
                    {Math.round(scale * 100)}%
                  </span>
                  <button
                    onClick={handleZoomIn}
                    className="p-1.5 hover:bg-white/10 rounded transition-colors"
                    aria-label="Zoom in"
                    title="Zoom in"
                  >
                    <FiZoomIn className="text-white" />
                  </button>
                </div>

                <button
                  onClick={() => {
                    toggleFullscreen();
                    setShowOverflowMenu(false);
                  }}
                  className="w-full flex items-center gap-3 px-3 py-2.5 text-white hover:bg-white/10 transition-colors"
                >
                  {isFullscreen ? <FiMinimize /> : <FiMaximize />}
                  <span className="text-sm">{isFullscreen ? 'Exit Fullscreen' : 'Fullscreen'}</span>
                </button>

                <button
                  onClick={() => {
                    handleDownload();
                    setShowOverflowMenu(false);
                  }}
                  className="w-full flex items-center gap-3 px-3 py-2.5 text-white hover:bg-white/10 transition-colors"
                >
                  <FiDownload />
                  <span className="text-sm">Download</span>
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Close Button */}
        <button
          onClick={onClose}
          className="p-3 bg-blue-600 hover:bg-blue-500 rounded-full text-white shadow-lg transition-colors"
          aria-label="Close"
          title="Close"
        >
          <FiX className="text-xl" />
        </button>
      </div>

      {/* Page Count Badge (Top Left) */}
      <div
        className={`absolute top-4 left-4 transition-opacity duration-300 z-50 ${
          showNav && numPages > 0 ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        style={{ top: 'calc(env(safe-area-inset-top, 0px) + 1rem)' }}
      >
        <div className="px-3 py-1.5 bg-black/60 backdrop-blur-md rounded-full border border-white/10">
          <p className="text-xs font-medium text-gray-200">
            {numPages} page{numPages !== 1 ? 's' : ''}
          </p>
        </div>
      </div>

      {/* PDF Content */}
      <div
        className="flex-1 overflow-hidden flex items-center justify-center"
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
      >
        {error ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center max-w-md">
              <p className="text-red-400 text-lg font-semibold mb-2">Error</p>
              <p className="text-gray-300">{error}</p>
              <button
                onClick={onClose}
                className="mt-4 px-6 py-2 bg-blue-500 hover:bg-blue-600 rounded-mcm text-white transition-colors"
              >
                Close
              </button>
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
                key={pdfUrl}
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
                  className={`flex ${isLandscape ? 'flex-row' : 'flex-col'} items-center justify-center transition-all duration-200 ${
                    swipeDirection === 'left' ? 'animate-slide-left' : swipeDirection === 'right' ? 'animate-slide-right' : ''
                  }`}
                >
                  <Page
                    key={`page_${currentPage}`}
                    pageNumber={currentPage}
                    scale={scale}
                    renderTextLayer={false}
                    renderAnnotationLayer={false}
                  />

                  {isLandscape && currentPage + 1 <= numPages && (
                    <Page
                      key={`page_${currentPage + 1}`}
                      pageNumber={currentPage + 1}
                      scale={scale}
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


      {/* Setlist Position Indicator */}
      {setlistNav && (
        <div className="absolute bottom-4 right-4 z-20">
          <div className="px-4 py-2 bg-black/60 backdrop-blur-lg rounded-lg border border-blue-500/30">
            <span className="text-blue-400 font-medium">
              {setlistNav.currentIndex + 1}
            </span>
            <span className="text-gray-400 mx-1">/</span>
            <span className="text-gray-300">{setlistNav.totalSongs}</span>
          </div>
        </div>
      )}

      {/* Transition Loading Overlay */}
      {isTransitioning && (
        <div className="absolute inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400 mx-auto mb-4"></div>
            <p className="text-gray-400">Loading next song...</p>
          </div>
        </div>
      )}

      {/* Transpose Modal */}
      {showTransposeModal && instrument && metadata && onKeyChange && (
        <TransposeModal
          songTitle={metadata.songTitle}
          defaultConcertKey={metadata.key}
          instrument={instrument}
          songRange={metadata.songRange}
          onClose={() => setShowTransposeModal(false)}
          onTransposed={(url, newKey) => {
            setShowTransposeModal(false);
            onKeyChange(url, newKey);
          }}
        />
      )}
    </div>
  );
}
