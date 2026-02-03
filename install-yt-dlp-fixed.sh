#!/bin/bash

# Improved installation script for yt-dlp with all dependencies

echo "=== Improved yt-dlp Installation for Production Servers ==="
echo ""

# Ensure we're using the correct user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"
echo ""

# Step 1: Ensure pip3 is installed
echo "1. Checking Python and pip installation..."
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y python3
fi

if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Installing..."
    sudo apt-get install -y python3-pip
fi

python3 --version
pip3 --version

echo ""
echo "2. Installing/Upgrading yt-dlp..."

# Uninstall any old versions first
pip3 uninstall -y yt-dlp youtube-dl 2>/dev/null

# Install yt-dlp with all recommended dependencies
pip3 install --user --upgrade yt-dlp[default]

# Also ensure common dependencies are installed
pip3 install --user --upgrade brotli certifi websockets mutagen pycryptodomex

echo ""
echo "3. Setting up PATH..."

# Ensure .local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    export PATH="$HOME/.local/bin:$PATH"
    
    # Add to .bashrc if not already there
    if ! grep -q '.local/bin' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo "Added .local/bin to PATH in ~/.bashrc"
    fi
    
    # Also add to .profile for non-interactive shells
    if ! grep -q '.local/bin' ~/.profile 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
        echo "Added .local/bin to PATH in ~/.profile"
    fi
fi

echo ""
echo "4. Verifying yt-dlp installation..."

# Find where yt-dlp was installed
YT_DLP_PATH=$(which yt-dlp)
if [ -z "$YT_DLP_PATH" ]; then
    YT_DLP_PATH="$HOME/.local/bin/yt-dlp"
fi

if [ -f "$YT_DLP_PATH" ]; then
    echo "✓ yt-dlp found at: $YT_DLP_PATH"
    chmod +x "$YT_DLP_PATH"
    ls -la "$YT_DLP_PATH"
    
    echo ""
    echo "Testing yt-dlp..."
    "$YT_DLP_PATH" --version
    
    echo ""
    echo "Testing with a YouTube video..."
    "$YT_DLP_PATH" --dump-json --no-playlist "https://www.youtube.com/watch?v=jNQXAC9IVRw" | head -n 5
    
    if [ $? -eq 0 ]; then
        echo "✓ yt-dlp is working correctly!"
    else
        echo "✗ yt-dlp test failed. Check the error above."
    fi
else
    echo "✗ yt-dlp not found after installation!"
    echo "Tried: $YT_DLP_PATH"
    exit 1
fi

echo ""
echo "5. Checking ffmpeg..."

if command -v ffmpeg &> /dev/null; then
    echo "✓ ffmpeg is already installed"
    ffmpeg -version | head -n 1
else
    echo "Installing ffmpeg..."
    sudo apt-get update
    sudo apt-get install -y ffmpeg
    
    if command -v ffmpeg &> /dev/null; then
        echo "✓ ffmpeg installed successfully"
        ffmpeg -version | head -n 1
    else
        echo "✗ ffmpeg installation failed"
    fi
fi

echo ""
echo "6. Installation Summary"
echo "======================="
echo "yt-dlp path: $YT_DLP_PATH"
echo "Python: $(python3 --version)"
echo "pip: $(pip3 --version)"

if command -v ffmpeg &> /dev/null; then
    echo "ffmpeg: $(which ffmpeg)"
fi

echo ""
echo "7. Next Steps for Laravel Application"
echo "======================================"
echo "Add this to your .env file:"
echo ""
echo "YT_DLP_PATH=$YT_DLP_PATH"

if command -v ffmpeg &> /dev/null; then
    echo "FFMPEG_PATH=$(which ffmpeg)"
fi

echo ""
echo "Then restart your Laravel application:"
echo "  php artisan config:clear"
echo "  php artisan cache:clear"
echo ""
echo "If using Laravel Forge, also restart PHP-FPM:"
echo "  sudo service php8.3-fpm restart"
echo ""
echo "=== Installation Complete ==="
