#!/bin/bash

# Installation script for yt-dlp and ffmpeg for Laravel Forge servers

echo "=== yt-dlp and ffmpeg Installation Script for Laravel Forge ==="
echo ""

# Check if running as forge user
if [ "$USER" != "forge" ] && [ "$USER" != "root" ]; then
    echo "⚠️  Warning: This script is designed for Laravel Forge servers (running as 'forge' user)"
    echo "Current user: $USER"
    echo ""
fi

echo "Checking if yt-dlp is installed..."

# Check for snap installation first
if snap list yt-dlp &> /dev/null 2>&1; then
    echo "✓ yt-dlp is installed via snap"
    /snap/bin/yt-dlp --version
    YT_DLP_PATH="/snap/bin/yt-dlp"
elif command -v yt-dlp &> /dev/null; then
    echo "✓ yt-dlp is already installed"
    yt-dlp --version
    YT_DLP_PATH=$(which yt-dlp)
else
    echo "✗ yt-dlp is not installed. Installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "Installing via Homebrew..."
            brew install yt-dlp
        else
            echo "Installing via pip..."
            pip3 install --user yt-dlp
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux (Forge servers) - prefer pip over snap for better web server compatibility
        echo "Installing via pip for forge user (recommended for web servers)..."
        
        # First, ensure pip is installed
        if ! command -v pip3 &> /dev/null; then
            echo "Installing pip3..."
            sudo apt-get update
            sudo apt-get install -y python3-pip
        fi
        
        # Install yt-dlp in user directory
        pip3 install --user yt-dlp
        
        # Add to PATH if not already there
        if ! grep -q '.local/bin' ~/.bashrc; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            export PATH="$HOME/.local/bin:$PATH"
        fi
    else
        echo "Please install yt-dlp manually from: https://github.com/yt-dlp/yt-dlp"
        exit 1
    fi
    
    echo "✓ yt-dlp installed successfully!"
    # Reload PATH
    export PATH="$HOME/.local/bin:$PATH"
    yt-dlp --version
    YT_DLP_PATH=$(which yt-dlp)
fi

echo ""
echo "Checking if ffmpeg is installed..."

# Check for snap installation first
if snap list ffmpeg &> /dev/null 2>&1; then
    echo "✓ ffmpeg is installed via snap"
    /snap/bin/ffmpeg -version | head -n 1
    FFMPEG_PATH="/snap/bin/ffmpeg"
elif command -v ffmpeg &> /dev/null; then
    echo "✓ ffmpeg is already installed"
    ffmpeg -version | head -n 1
    FFMPEG_PATH=$(which ffmpeg)
else
    echo "✗ ffmpeg is not installed. Installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "Installing via Homebrew..."
            brew install ffmpeg
        else
            echo "Please install ffmpeg manually"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux (Forge servers) - prefer apt over snap for better web server compatibility
        echo "Installing via apt (recommended for web servers)..."
        sudo apt-get update
        sudo apt-get install -y ffmpeg
    else
        echo "Please install ffmpeg manually"
        exit 1
    fi
    
    echo "✓ ffmpeg installed successfully!"
    ffmpeg -version | head -n 1
    FFMPEG_PATH=$(which ffmpeg)
fi

# Create downloads directory
mkdir -p storage/app/downloads
echo "Downloads directory created"

echo ""
echo "=== Installation Summary ==="
echo "yt-dlp location: ${YT_DLP_PATH:-$(which yt-dlp)}"
echo "ffmpeg location: ${FFMPEG_PATH:-$(which ffmpeg)}"
echo ""

# Check if snap was used
if [[ "${YT_DLP_PATH}" == "/snap/bin/yt-dlp" ]] || [[ "${FFMPEG_PATH}" == "/snap/bin/ffmpeg" ]]; then
    echo "⚠️  SNAP DETECTED - Important Configuration Required!"
    echo ""
    echo "Add these lines to your .env file on the server:"
    echo "---"
    [[ "${YT_DLP_PATH}" == "/snap/bin/yt-dlp" ]] && echo "YT_DLP_PATH=/snap/bin/yt-dlp"
    [[ "${FFMPEG_PATH}" == "/snap/bin/ffmpeg" ]] && echo "FFMPEG_PATH=/snap/bin/ffmpeg"
    echo "---"
    echo ""
    echo "For Laravel Forge deployment script, add:"
    echo "---"
    echo "export PATH=\"/snap/bin:\$PATH\""
    echo "---"
else
    echo "For Laravel Forge deployment script, add:"
    echo "---"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "---"
fi

echo ""
echo "✓ Setup complete! Your YouTube downloader is ready to use."
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
