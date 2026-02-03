<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Process;
use Inertia\Inertia;

class YouTubeDownloaderController extends Controller
{
    private function getYtDlpPath(): string
    {
        // Check for custom path in .env first (most reliable for production)
        $customPath = env('YT_DLP_PATH');
        if ($customPath && file_exists($customPath)) {
            return $customPath;
        }

        // Try common paths for yt-dlp
        $paths = [
            '/usr/local/bin/yt-dlp',         // Standalone binary (Linux/macOS)
            '/usr/bin/yt-dlp',               // Linux system package
            '/opt/homebrew/bin/yt-dlp',      // macOS Homebrew (Apple Silicon)
            '/home/forge/.local/bin/yt-dlp', // Forge user pip install (legacy)
            getenv('HOME') . '/.local/bin/yt-dlp', // Current user pip install (legacy)
            'yt-dlp',                        // Fallback to PATH
        ];

        foreach ($paths as $path) {
            if ($path === 'yt-dlp' || file_exists($path)) {
                return $path;
            }
        }

        return 'yt-dlp'; // Fallback
    }

    private function getFfmpegPath(): string
    {
        // Check for custom path in .env first
        $customPath = env('FFMPEG_PATH');
        if ($customPath && file_exists($customPath)) {
            return $customPath;
        }

        // Try common paths for ffmpeg
        $paths = [
            '/usr/bin/ffmpeg',               // Linux system (most common on Forge)
            '/opt/homebrew/bin/ffmpeg',      // macOS Homebrew (Apple Silicon)
            '/usr/local/bin/ffmpeg',         // macOS Homebrew (Intel) / Linux
            'ffmpeg',                        // Fallback to PATH
        ];

        foreach ($paths as $path) {
            if ($path === 'ffmpeg' || file_exists($path)) {
                return $path;
            }
        }

        return 'ffmpeg'; // Fallback
    }

    public function index()
    {
        return Inertia::render('youtube-downloader');
    }

    public function getVideoInfo(Request $request)
    {
        $request->validate([
            'url' => 'required|url',
        ]);

        try {
            $ytDlpPath = $this->getYtDlpPath();
            
            \Log::info('Fetching YouTube video info', [
                'url' => $request->url,
                'yt_dlp_path' => $ytDlpPath,
                'path_exists' => file_exists($ytDlpPath) ? 'yes' : 'no',
                'is_executable' => is_executable($ytDlpPath) ? 'yes' : 'no'
            ]);
            
            // Use yt-dlp to get video information and available formats
            $result = Process::run([
                $ytDlpPath,
                '--dump-json',
                '--no-playlist',
                $request->url
            ]);

            if (!$result->successful()) {
                \Log::error('Failed to fetch YouTube video info', [
                    'url' => $request->url,
                    'yt_dlp_path' => $ytDlpPath,
                    'exit_code' => $result->exitCode(),
                    'error_output' => $result->errorOutput(),
                    'standard_output' => $result->output()
                ]);
                
                return response()->json([
                    'error' => 'Failed to fetch video information. Please check the URL.',
                    'details' => config('app.debug') ? $result->errorOutput() : null
                ], 400);
            }

            $videoData = json_decode($result->output(), true);
            
            if (!$videoData) {
                \Log::error('Failed to parse YouTube video data', [
                    'url' => $request->url,
                    'output' => substr($result->output(), 0, 500)
                ]);
                
                return response()->json([
                    'error' => 'Failed to parse video information.'
                ], 500);
            }

            // Extract relevant formats (video with audio)
            $formats = collect($videoData['formats'] ?? [])
                ->filter(function ($format) {
                    return isset($format['height']) && isset($format['vcodec']) && $format['vcodec'] !== 'none';
                })
                ->map(function ($format) use ($videoData) {
                    // Try to get filesize from the format itself, or estimate it
                    $filesize = $format['filesize'] ?? $format['filesize_approx'] ?? null;
                    
                    // If no filesize, try to estimate from bitrate and duration
                    if (!$filesize && isset($format['tbr']) && isset($videoData['duration'])) {
                        // tbr is in kbit/s, duration is in seconds
                        // filesize in bytes = (tbr * 1000 / 8) * duration
                        $filesize = (int)(($format['tbr'] * 1000 / 8) * $videoData['duration']);
                    }
                    
                    return [
                        'format_id' => $format['format_id'],
                        'resolution' => $format['height'] . 'p',
                        'ext' => $format['ext'] ?? 'mp4',
                        'filesize' => $filesize,
                        'fps' => $format['fps'] ?? null,
                    ];
                })
                ->unique('resolution')
                ->sortByDesc('resolution')
                ->values()
                ->toArray();

            \Log::info('Successfully fetched YouTube video info', [
                'url' => $request->url,
                'title' => $videoData['title'] ?? 'Unknown',
                'formats_count' => count($formats)
            ]);

            return response()->json([
                'title' => $videoData['title'] ?? 'Unknown',
                'thumbnail' => $videoData['thumbnail'] ?? null,
                'duration' => $videoData['duration'] ?? null,
                'uploader' => $videoData['uploader'] ?? 'Unknown',
                'formats' => $formats,
            ]);
        } catch (\Exception $e) {
            \Log::error('Exception while fetching YouTube video info', [
                'url' => $request->url ?? 'unknown',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'error' => 'An error occurred: ' . $e->getMessage()
            ], 500);
        }
    }

    public function download(Request $request)
    {
        $request->validate([
            'url' => 'required|url',
            'format_id' => 'nullable|string',
            'resolution' => 'nullable|string',
        ]);

        try {
            // Create a unique temporary file
            $tempDir = rtrim(sys_get_temp_dir(), '/\\');
            $uniqueId = uniqid('yt_', true);
            $tempFile = $tempDir . '/' . $uniqueId . '.mp4';

            // Build the yt-dlp command to download to temp file
            $command = [$this->getYtDlpPath()];
            
            // Set ffmpeg location
            $command[] = '--ffmpeg-location';
            $command[] = $this->getFfmpegPath();
            
            $command[] = '--no-playlist';
            $command[] = '--no-warnings';

            // If a specific format is selected
            if ($request->format_id) {
                $command[] = '-f';
                $command[] = $request->format_id . '+bestaudio/best';
            } else {
                // Default to best quality with mp4 preference and audio
                $command[] = '-f';
                $command[] = 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best';
            }

            $command[] = '--merge-output-format';
            $command[] = 'mp4';
            $command[] = '-o';
            $command[] = $tempFile;
            $command[] = $request->url;

            \Log::info('Starting YouTube download to temp file', [
                'url' => $request->url,
                'format_id' => $request->format_id,
                'temp_file' => $tempFile,
                'command' => implode(' ', array_map(function($arg) {
                    return strpos($arg, ' ') !== false ? '"' . $arg . '"' : $arg;
                }, $command))
            ]);

            $startTime = microtime(true);
            
            // Execute the download
            $result = Process::timeout(600)->run($command);

            if (!$result->successful()) {
                \Log::error('YouTube download failed', [
                    'url' => $request->url,
                    'error' => $result->errorOutput()
                ]);
                
                // Clean up temp file if it exists
                if (file_exists($tempFile)) {
                    unlink($tempFile);
                }
                
                return response()->json([
                    'error' => 'Failed to download video.'
                ], 400);
            }

            $duration = round(microtime(true) - $startTime, 2);
            $fileSize = file_exists($tempFile) ? filesize($tempFile) : 0;
            $sizeMB = round($fileSize / 1024 / 1024, 2);

            \Log::info('YouTube download completed successfully', [
                'url' => $request->url,
                'duration_seconds' => $duration,
                'size_mb' => $sizeMB,
                'temp_file' => $tempFile
            ]);

            // Get the filename from the video title
            $infoResult = Process::run([
                $this->getYtDlpPath(),
                '--get-title',
                '--no-playlist',
                $request->url
            ]);

            $fileName = $infoResult->successful() 
                ? preg_replace('/[^A-Za-z0-9_\-\s]/', '_', trim($infoResult->output())) . '.mp4'
                : 'video.mp4';

            // Return the file and delete after sending
            return response()->download($tempFile, $fileName, [
                'Content-Type' => 'video/mp4',
            ])->deleteFileAfterSend(true);

        } catch (\Exception $e) {
            \Log::error('YouTube download exception', [
                'url' => $request->url ?? 'unknown',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'error' => 'An error occurred: ' . $e->getMessage()
            ], 500);
        }
    }
}
