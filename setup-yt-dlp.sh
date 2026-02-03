#!/bin/bash

# Installation script for yt-dlp and ffmpeg

echo "Checking if yt-dlp is installed..."

if command -v yt-dlp &> /dev/null
then
    echo "yt-dlp is already installed"
    yt-dlp --version
else
    echo "yt-dlp is not installed. Installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "Installing via Homebrew..."
            brew install yt-dlp
        else
            echo "Installing via pip..."
            pip3 install yt-dlp
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "Installing via pip..."
        pip3 install yt-dlp
    else
        echo "Please install yt-dlp manually from: https://github.com/yt-dlp/yt-dlp"
        exit 1
    fi
    
    echo "yt-dlp installed successfully!"
    yt-dlp --version
fi

echo ""
echo "Checking if ffmpeg is installed..."

if command -v ffmpeg &> /dev/null
then
    echo "ffmpeg is already installed"
    ffmpeg -version | head -n 1
else
    echo "ffmpeg is not installed. Installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "Installing via Homebrew..."
            brew install ffmpeg
        else
            echo "Please install Homebrew first or install ffmpeg manually"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "Installing via apt..."
        sudo apt-get update
        sudo apt-get install -y ffmpeg
    else
        echo "Please install ffmpeg manually from: https://ffmpeg.org"
        exit 1
    fi
    
    echo "ffmpeg installed successfully!"
    ffmpeg -version | head -n 1
fi

# Create downloads directory
mkdir -p storage/app/downloads
echo "Downloads directory created"

echo ""
echo "Setup complete! You can now use the YouTube downloader."
