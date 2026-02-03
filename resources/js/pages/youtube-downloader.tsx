import { useState } from 'react'
import { Head } from '@inertiajs/react'
import AppLayout from '@/layouts/app-layout'

interface VideoFormat {
  format_id: string
  resolution: string
  ext: string
  filesize: number | null
  fps: number | null
}

interface VideoInfo {
  title: string
  thumbnail: string | null
  duration: number | null
  uploader: string
  formats: VideoFormat[]
}

export default function YouTubeDownloader() {
  const [url, setUrl] = useState('')
  const [loading, setLoading] = useState(false)
  const [videoInfo, setVideoInfo] = useState<VideoInfo | null>(null)
  const [error, setError] = useState('')
  const [downloading, setDownloading] = useState(false)

  const fetchVideoInfo = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setVideoInfo(null)
    setLoading(true)

    try {
      const response = await fetch('/api/youtube/info', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': document
            .querySelector('meta[name="csrf-token"]')
            ?.getAttribute('content') || '',
        },
        body: JSON.stringify({ url }),
      })

      const data = await response.json()

      if (!response.ok) {
        setError(data.error || 'Failed to fetch video information')
        return
      }

      setVideoInfo(data)
    } catch (err) {
      setError('An error occurred while fetching video information')
    } finally {
      setLoading(false)
    }
  }

  const downloadVideo = async (formatId?: string) => {
    setDownloading(true)
    setError('')

    try {
      const response = await fetch('/api/youtube/download', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': document
            .querySelector('meta[name="csrf-token"]')
            ?.getAttribute('content') || '',
        },
        body: JSON.stringify({
          url,
          format_id: formatId,
        }),
      })

      if (!response.ok) {
        const data = await response.json()
        setError(data.error || 'Failed to download video')
        return
      }

      // Create a blob from the response and download it
      const blob = await response.blob()
      const downloadUrl = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = downloadUrl
      a.download = response.headers
        .get('content-disposition')
        ?.split('filename=')[1]
        ?.replace(/"/g, '') || 'video.mp4'
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(downloadUrl)
      document.body.removeChild(a)
    } catch (err) {
      setError('An error occurred while downloading the video')
    } finally {
      setDownloading(false)
    }
  }

  const formatFileSize = (bytes: number | null) => {
    if (!bytes) return 'Unknown size'
    const mb = bytes / (1024 * 1024)
    return `${mb.toFixed(2)} MB`
  }

  const formatDuration = (seconds: number | null) => {
    if (!seconds) return 'Unknown'
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  return (
    <AppLayout>
      <Head title="YouTube Downloader" />

      <div className="py-12">
        <div className="mx-auto max-w-4xl sm:px-6 lg:px-8">
          <div className="overflow-hidden bg-white shadow-sm sm:rounded-lg">
            <div className="p-6">
              <h1 className="mb-6 text-3xl font-bold text-gray-900">
                YouTube Video Downloader
              </h1>

              <form onSubmit={fetchVideoInfo} className="mb-6">
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={url}
                    onChange={(e) => setUrl(e.target.value)}
                    placeholder="Enter YouTube URL..."
                    className="flex-1 rounded-md border border-gray-300 px-4 py-2 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                    required
                  />
                  <button
                    type="submit"
                    disabled={loading}
                    className="rounded-md bg-indigo-600 px-6 py-2 text-white hover:bg-indigo-700 disabled:opacity-50"
                  >
                    {loading ? 'Loading...' : 'Get Video'}
                  </button>
                </div>
              </form>

              {error && (
                <div className="mb-4 rounded-md bg-red-50 p-4">
                  <p className="text-sm text-red-800">{error}</p>
                </div>
              )}

              {videoInfo && (
                <div className="space-y-6">
                  <div className="rounded-lg border border-gray-200 p-4">
                    <div className="flex gap-4">
                      {videoInfo.thumbnail && (
                        <img
                          src={videoInfo.thumbnail}
                          alt={videoInfo.title}
                          className="h-32 w-48 rounded object-cover"
                        />
                      )}
                      <div className="flex-1">
                        <h2 className="mb-2 text-xl font-semibold text-gray-900">
                          {videoInfo.title}
                        </h2>
                        <p className="text-sm text-gray-600">
                          Uploader: {videoInfo.uploader}
                        </p>
                        <p className="text-sm text-gray-600">
                          Duration: {formatDuration(videoInfo.duration)}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div>
                    <h3 className="mb-3 text-lg font-semibold text-gray-900">
                      Available Formats
                    </h3>
                    <div className="space-y-2">
                      {videoInfo.formats.map((format) => (
                        <div
                          key={format.format_id}
                          className="flex items-center justify-between rounded-lg border border-gray-200 p-4"
                        >
                          <div>
                            <span className="font-semibold text-gray-900">
                              {format.resolution}
                            </span>
                            <span className="ml-3 text-sm text-gray-600">
                              {format.ext.toUpperCase()}
                            </span>
                            {format.fps && (
                              <span className="ml-3 text-sm text-gray-600">
                                {format.fps} FPS
                              </span>
                            )}
                            <span className="ml-3 text-sm text-gray-600">
                              {formatFileSize(format.filesize)}
                            </span>
                          </div>
                          <button
                            onClick={() => downloadVideo(format.format_id)}
                            disabled={downloading}
                            className="rounded-md bg-green-600 px-4 py-2 text-sm text-white hover:bg-green-700 disabled:opacity-50"
                          >
                            {downloading ? 'Downloading...' : 'Download'}
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="pt-4">
                    <button
                      onClick={() => downloadVideo()}
                      disabled={downloading}
                      className="w-full rounded-md bg-indigo-600 px-6 py-3 text-white hover:bg-indigo-700 disabled:opacity-50"
                    >
                      {downloading
                        ? 'Downloading...'
                        : 'Download Best Quality'}
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  )
}
