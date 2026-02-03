#!/bin/bash

echo "=== yt-dlp Diagnostic Script ==="
echo ""

echo "1. Checking yt-dlp installation paths:"
echo "--------------------------------------"
which yt-dlp
ls -la ~/.local/bin/yt-dlp 2>/dev/null || echo "Not found in ~/.local/bin/"
ls -la /usr/local/bin/yt-dlp 2>/dev/null || echo "Not found in /usr/local/bin/"
ls -la /usr/bin/yt-dlp 2>/dev/null || echo "Not found in /usr/bin/"

echo ""
echo "2. Testing yt-dlp directly:"
echo "---------------------------"
yt-dlp --version 2>&1

echo ""
echo "3. Testing with full path:"
echo "--------------------------"
~/.local/bin/yt-dlp --version 2>&1 || echo "Failed with ~/.local/bin/yt-dlp"

echo ""
echo "4. Checking Python environment:"
echo "-------------------------------"
which python3
python3 --version
which pip3
pip3 --version

echo ""
echo "5. Checking if yt-dlp Python module is installed:"
echo "-------------------------------------------------"
python3 -m pip show yt-dlp 2>&1 || echo "yt-dlp not found in pip"

echo ""
echo "6. Testing yt-dlp with a test URL:"
echo "----------------------------------"
TEST_URL="https://www.youtube.com/watch?v=jNQXAC9IVRw"
echo "Testing URL: $TEST_URL"
~/.local/bin/yt-dlp --dump-json --no-playlist "$TEST_URL" 2>&1 | head -n 20

echo ""
echo "7. Checking PATH variable:"
echo "-------------------------"
echo "PATH=$PATH"

echo ""
echo "8. Testing as web server might run it:"
echo "--------------------------------------"
/usr/bin/env -i HOME="$HOME" ~/.local/bin/yt-dlp --version 2>&1

echo ""
echo "9. Checking file permissions:"
echo "-----------------------------"
ls -la ~/.local/bin/ 2>/dev/null | grep yt-dlp

echo ""
echo "10. Checking Python dependencies:"
echo "---------------------------------"
python3 -c "import brotli; print('brotli: OK')" 2>&1 || echo "brotli: MISSING"
python3 -c "import certifi; print('certifi: OK')" 2>&1 || echo "certifi: MISSING"
python3 -c "import websockets; print('websockets: OK')" 2>&1 || echo "websockets: MISSING"

echo ""
echo "=== Diagnostic Complete ==="
