# YouTube Video Downloader

A Laravel-based YouTube video downloader with a modern React interface.

## ⚠️ Important Note

This application is for **personal use only**. Downloading copyrighted content without permission may violate YouTube's Terms of Service and local laws.

## Features

- Download YouTube videos in various quality options
- Modern, responsive UI built with React and Tailwind CSS
- View video information before downloading
- Support for different formats and resolutions

## Requirements

- PHP 8.2+
- Node.js 18+
- yt-dlp
- ffmpeg
- Composer

## Local Development Setup

1. Clone the repository and install dependencies:

```bash
composer install
npm install
```

2. Copy the environment file and generate app key:

```bash
cp .env.example .env
php artisan key:generate
```

3. Run migrations:

```bash
php artisan migrate
```

4. Install yt-dlp and ffmpeg:

```bash
bash setup-yt-dlp.sh
```

5. Start the development server:

```bash
php artisan serve
npm run dev
```

Visit `http://localhost:8000`

## Production Deployment

### Laravel Forge

For detailed Forge deployment instructions, see [FORGE_DEPLOYMENT.md](FORGE_DEPLOYMENT.md)

Quick steps:
1. SSH into your Forge server
2. Run `bash setup-yt-dlp.sh` to install dependencies
3. Update your deployment script to include `export PATH="$HOME/.local/bin:$PATH"`
4. Deploy!

### General Production Setup

1. Ensure yt-dlp and ffmpeg are installed on your server
2. Set environment variables (see .env.example)
3. Run migrations and build assets
4. Ensure storage directories are writable

## Troubleshooting

### "Failed to fetch video information"
- yt-dlp is not installed or not in PATH
- Run `which yt-dlp` to verify installation

### "The file does not exist" error
- Download failed before file was created
- Check Laravel logs at `storage/logs/laravel.log`
- Verify ffmpeg is installed

### "Bad Request" error
- CSRF or session configuration issue
- Ensure `APP_URL` and `SESSION_SECURE_COOKIE` are set correctly

For more troubleshooting, see [FORGE_DEPLOYMENT.md](FORGE_DEPLOYMENT.md)

## Updating yt-dlp

YouTube frequently changes, so yt-dlp needs regular updates:

```bash
pip3 install --user --upgrade yt-dlp
```

## License

This project is open-sourced software for educational and personal use only.
 