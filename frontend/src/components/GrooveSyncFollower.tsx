import { useState, useEffect, useCallback } from 'react';
import { Document, Page, pdfjs } from 'react-pdf';
import { FiX, FiUser } from 'react-icons/fi';
import { useGrooveSync } from '@/contexts/GrooveSyncContext';
import { useUserProfile } from '@/contexts/UserProfileContext';
import { api } from '@/services/api';
import { getInstrumentById } from '@/types/catalog';

// Set up worker
pdfjs.GlobalWorkerOptions.workerSrc = new URL(
  'pdfjs-dist/build/pdf.worker.min.mjs',
  import.meta.url,
).toString();

export function GrooveSyncFollower() {
  const { followingSession, stopFollowing } = useGrooveSync();
  const { profile } = useUserProfile();

  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [numPages, setNumPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [scale, setScale] = useState(1.5);
  const [isLandscape, setIsLandscape] = useState(
    window.innerWidth > window.innerHeight
  );
  const [showControls, setShowControls] = useState(true);
  const [lastSongKey, setLastSongKey] = useState<string | null>(null);

  // Get user's instrument
  const instrument = profile?.instrument ? getInstrumentById(profile.instrument) : null;

  // Calculate optimal scale
  const calculateOptimalScale = useCallback(() => {
    const standardPageWidth = 612;
    const standardPageHeight = 792;
    const availableHeight = window.innerHeight - 80;
    const availableWidth = window.innerWidth;
    const heightScale = availableHeight / standardPageHeight;

    if (window.innerWidth > window.innerHeight) {
      const widthScale = availableWidth / (standardPageWidth * 2);
      return Math.min(Math.max(Math.min(heightScale, widthScale) * 1.04, 0.8), 3.0);
    }
    return Math.min(Math.max(heightScale * 1.04, 0.8), 3.0);
  }, []);

  // Handle orientation changes
  useEffect(() => {
    const handleResize = () => {
      const nowLandscape = window.innerWidth > window.innerHeight;
      if (isLandscape !== nowLandscape) {
        setIsLandscape(nowLandscape);
        setScale(calculateOptimalScale());
      }
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [isLandscape, calculateOptimalScale]);

  // Auto-hide controls after inactivity
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const resetTimer = () => {
      setShowControls(true);
      clearTimeout(timer);
      timer = setTimeout(() => setShowControls(false), 3000);
    };

    window.addEventListener('mousemove', resetTimer);
    window.addEventListener('touchstart', resetTimer);
    resetTimer();

    return () => {
      window.removeEventListener('mousemove', resetTimer);
      window.removeEventListener('touchstart', resetTimer);
      clearTimeout(timer);
    };
  }, []);

  // Load PDF when currentSong changes
  useEffect(() => {
    const currentSong = followingSession?.currentSong;
    if (!currentSong || !instrument) {
      return;
    }

    // Create a unique key for this song+key combination
    const songKey = `${currentSong.title}-${currentSong.concertKey}`;
    if (songKey === lastSongKey) {
      return; // Already loaded this song
    }

    const loadPdf = async () => {
      setIsLoading(true);
      setError(null);
      setCurrentPage(1);

      try {
        console.log('🎵 Loading PDF for follower:', currentSong.title, 'in', currentSong.concertKey);
        const response = await api.generatePDF(
          currentSong.title,
          currentSong.concertKey,
          instrument.transposition,
          instrument.clef,
          instrument.label
        );

        // Fetch the PDF and create a blob URL
        const pdfResponse = await fetch(response.url);
        const blob = await pdfResponse.blob();
        const blobUrl = URL.createObjectURL(blob);

        // Revoke old URL if exists
        if (pdfUrl) {
          URL.revokeObjectURL(pdfUrl);
        }

        setPdfUrl(blobUrl);
        setLastSongKey(songKey);
        setScale(calculateOptimalScale());
        console.log('🎵 PDF loaded for follower');
      } catch (err) {
        console.error('Failed to load PDF:', err);
        setError(err instanceof Error ? err.message : 'Failed to load PDF');
      } finally {
        setIsLoading(false);
      }
    };

    loadPdf();
  }, [followingSession?.currentSong, instrument, lastSongKey, calculateOptimalScale]);

  // Cleanup blob URL on unmount
  useEffect(() => {
    return () => {
      if (pdfUrl) {
        URL.revokeObjectURL(pdfUrl);
      }
    };
  }, []);

  if (!followingSession) {
    return null;
  }

  const currentSong = followingSession.currentSong;
  const pagesPerView = isLandscape ? 2 : 1;

  return (
    <div className="fixed inset-0 bg-white z-50 flex flex-col">
      {/* Header with leader info and stop button */}
      <div
        className={`absolute top-4 left-4 right-4 flex items-center justify-between z-50 transition-opacity duration-300 ${
          showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        style={{ top: 'calc(env(safe-area-inset-top, 0px) + 1rem)' }}
      >
        {/* Leader info */}
        <div className="flex items-center gap-2 px-3 py-2 bg-black/60 backdrop-blur-md rounded-full border border-white/10">
          <FiUser className="text-blue-400" />
          <span className="text-white text-sm">
            Following <span className="font-medium">{followingSession.leaderName}</span>
          </span>
        </div>

        {/* Stop Following button */}
        <button
          onClick={stopFollowing}
          className="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-500 rounded-full text-white shadow-lg transition-colors"
        >
          <FiX />
          <span className="text-sm font-medium">Stop Following</span>
        </button>
      </div>

      {/* Current song info */}
      {currentSong && (
        <div
          className={`absolute bottom-4 left-4 z-50 transition-opacity duration-300 ${
            showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'
          }`}
        >
          <div className="px-4 py-2 bg-black/60 backdrop-blur-md rounded-lg border border-white/10">
            <p className="text-white font-medium">{currentSong.title}</p>
            <p className="text-gray-400 text-sm">
              Concert: {currentSong.concertKey.toUpperCase()}
            </p>
          </div>
        </div>
      )}

      {/* PDF Content */}
      <div className="flex-1 overflow-hidden flex items-center justify-center">
        {isLoading && (
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400 mx-auto mb-4" />
            <p className="text-gray-600">Loading chart...</p>
          </div>
        )}

        {error && (
          <div className="text-center max-w-md">
            <p className="text-red-500 text-lg font-semibold mb-2">Error</p>
            <p className="text-gray-600">{error}</p>
          </div>
        )}

        {!currentSong && !isLoading && (
          <div className="text-center">
            <p className="text-gray-500 text-lg">Waiting for leader to select a song...</p>
          </div>
        )}

        {pdfUrl && !isLoading && (
          <Document
            file={pdfUrl}
            onLoadSuccess={({ numPages }) => setNumPages(numPages)}
            onLoadError={(err) => setError(err.message)}
            loading={null}
          >
            <div className={`flex ${isLandscape ? 'flex-row' : 'flex-col'} items-center justify-center`}>
              <Page
                pageNumber={currentPage}
                scale={scale}
                renderTextLayer={false}
                renderAnnotationLayer={false}
              />
              {isLandscape && currentPage + 1 <= numPages && (
                <Page
                  pageNumber={currentPage + 1}
                  scale={scale}
                  renderTextLayer={false}
                  renderAnnotationLayer={false}
                />
              )}
            </div>
          </Document>
        )}

        {/* Page navigation for multi-page charts */}
        {numPages > pagesPerView && (
          <div className="absolute bottom-4 right-4 flex items-center gap-2">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - pagesPerView))}
              disabled={currentPage === 1}
              className="px-3 py-1 bg-black/60 text-white rounded disabled:opacity-50"
            >
              Prev
            </button>
            <span className="text-gray-600">
              {currentPage} / {numPages}
            </span>
            <button
              onClick={() => setCurrentPage((p) => Math.min(numPages - pagesPerView + 1, p + pagesPerView))}
              disabled={currentPage + pagesPerView > numPages}
              className="px-3 py-1 bg-black/60 text-white rounded disabled:opacity-50"
            >
              Next
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
