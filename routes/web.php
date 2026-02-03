<?php

use App\Http\Controllers\YouTubeDownloaderController;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('welcome');
})->name('home');

// Protected Routes - Require Authentication
Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');

    // YouTube Downloader Routes
    Route::get('/youtube-downloader', [YouTubeDownloaderController::class, 'index'])->name('youtube.index');
    Route::post('/api/youtube/info', [YouTubeDownloaderController::class, 'getVideoInfo'])->name('youtube.info');
    Route::post('/api/youtube/download', [YouTubeDownloaderController::class, 'download'])->name('youtube.download');
    Route::get('/api/youtube/progress', [YouTubeDownloaderController::class, 'progress'])->name('youtube.progress');
});

require __DIR__.'/settings.php';
