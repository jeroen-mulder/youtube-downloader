import { useState } from 'react'
import { router } from '@inertiajs/react'
import axios from 'axios'

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

export function YouTubeDownloaderWidget() {
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
            const response = await axios.post('/api/youtube/info', { url })

            setVideoInfo(response.data)
        } catch (err: any) {
            setError(err.response?.data?.error || 'An error occurred while fetching video information')
        } finally {
            setLoading(false)
        }
    }

    const downloadVideo = async (formatId?: string) => {
        setDownloading(true)
        setError('')

        try {
            const response = await axios.post('/api/youtube/download', {
                url,
                format_id: formatId,
            }, {
                responseType: 'blob'
            })

            // Create a blob from the response and download it
            const blob = new Blob([response.data], { type: 'video/mp4' })
            const downloadUrl = window.URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = downloadUrl
            
            // Extract filename from Content-Disposition header
            const contentDisposition = response.headers['content-disposition']
            let fileName = 'video.mp4'
            if (contentDisposition) {
                const matches = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/.exec(contentDisposition)
                if (matches != null && matches[1]) {
                    fileName = matches[1].replace(/['"]/g, '')
                }
            }
            
            a.download = fileName
            document.body.appendChild(a)
            a.click()
            window.URL.revokeObjectURL(downloadUrl)
            document.body.removeChild(a)
        } catch (err: any) {
            setError(err.response?.data?.error || 'An error occurred while downloading the video')
        } finally {
            setDownloading(false)
        }
    }

    const formatFileSize = (bytes: number | null) => {
        if (!bytes) return 'Unknown'
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
        <div className="space-y-4">
            <div>
                <h2 className="text-2xl font-bold text-foreground mb-4">YouTube Video Downloader</h2>

                <form onSubmit={fetchVideoInfo} className="mb-4">
                    <div className="flex gap-2">
                        <input
                            type="text"
                            value={url}
                            onChange={(e) => setUrl(e.target.value)}
                            placeholder="Enter YouTube URL..."
                            className="flex-1 rounded-md border border-input bg-background px-4 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                            required
                        />
                        <button
                            type="submit"
                            disabled={loading}
                            className="rounded-md bg-primary px-6 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                        >
                            {loading ? 'Loading...' : 'Get Video'}
                        </button>
                    </div>
                </form>

                {error && (
                    <div className="mb-4 rounded-md bg-destructive/15 p-4">
                        <p className="text-sm text-destructive">{error}</p>
                    </div>
                )}
            </div>

            {videoInfo && (
                <div className="space-y-4">
                    <div className="rounded-lg border border-border bg-card p-4">
                        <div className="flex gap-4">
                            {videoInfo.thumbnail && (
                                <img
                                    src={videoInfo.thumbnail}
                                    alt={videoInfo.title}
                                    className="h-24 w-40 rounded object-cover"
                                />
                            )}
                            <div className="flex-1 min-w-0">
                                <h3 className="mb-1 text-lg font-semibold text-card-foreground truncate">
                                    {videoInfo.title}
                                </h3>
                                <p className="text-sm text-muted-foreground">
                                    {videoInfo.uploader}
                                </p>
                                <p className="text-sm text-muted-foreground">
                                    Duration: {formatDuration(videoInfo.duration)}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div>
                        <h3 className="mb-3 text-sm font-semibold text-foreground">
                            Available Formats
                        </h3>
                        <div className="space-y-2 max-h-60 overflow-y-auto">
                            {videoInfo.formats.map((format) => (
                                <div
                                    key={format.format_id}
                                    className="flex items-center justify-between rounded-lg border border-border bg-card p-3"
                                >
                                    <div className="text-sm">
                                        <span className="font-semibold text-card-foreground">
                                            {format.resolution}
                                        </span>
                                        <span className="ml-3 text-muted-foreground">
                                            {format.ext.toUpperCase()}
                                        </span>
                                        {format.fps && (
                                            <span className="ml-3 text-muted-foreground">
                                                {format.fps} FPS
                                            </span>
                                        )}
                                        <span className="ml-3 text-muted-foreground">
                                            {formatFileSize(format.filesize)}
                                        </span>
                                    </div>
                                    <button
                                        onClick={() => downloadVideo(format.format_id)}
                                        disabled={downloading}
                                        className="rounded-md bg-primary px-3 py-1 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                                    >
                                        {downloading ? 'Downloading...' : 'Download'}
                                    </button>
                                </div>
                            ))}
                        </div>
                    </div>

                    <button
                        onClick={() => downloadVideo()}
                        disabled={downloading}
                        className="w-full rounded-md bg-primary px-6 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                    >
                        {downloading ? 'Downloading...' : 'Download Best Quality'}
                    </button>
                </div>
            )}
        </div>
    )
}
