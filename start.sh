#!/bin/bash
# Simply eBay - Quick Start Script

echo "🚀 Simply eBay - Quick Start"
echo "==============================="

# Check if we're in the right directory
if [ ! -f "index.html" ]; then
    echo "❌ Error: Please run this script from the project directory (where index.html is located)"
    exit 1
fi

echo "📋 Checking requirements..."

# Check for Python
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Python not found. Please install Python to run a local server."
    echo "   Or open index.html directly in your browser (some features may be limited)"
    exit 1
fi

echo "✅ Python found: $PYTHON_CMD"

# Check for llama-server
if ! command -v llama-server &> /dev/null; then
    echo "🤖 Setting up your personal AI assistant (this keeps you safe!)"
    echo "📥 Installing llama.cpp automatically..."
    echo "🔒 This protects your privacy - everything stays on your device"
    echo "⏱️  One-time setup takes 2-3 minutes, then it's instant forever"
    echo ""
    
    # Auto-install llama.cpp
    if command -v brew &> /dev/null; then
        echo "🍺 Installing via Homebrew..."
        brew install llama.cpp
        if [ $? -eq 0 ]; then
            echo "✅ llama.cpp installed successfully!"
            AI_SERVER=true
        else
            echo "❌ Installation failed. Please try manual installation."
            AI_SERVER=false
        fi
    else
        echo "❌ Homebrew not found. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        AI_SERVER=false
    fi
else
    echo "✅ llama-server found"
    AI_SERVER=true
fi

# Check if ports are available
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 8000 is already in use. Trying port 8001..."
    WEB_PORT=8001
else
    WEB_PORT=8000
fi

if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 8080 is already in use. AI server may conflict."
    AI_PORT=8081
else
    AI_PORT=8080
fi

# Function to cleanup background processes
cleanup() {
    echo ""
    echo "🛑 Shutting down servers..."
    if [ ! -z "$WEB_PID" ]; then
        kill $WEB_PID 2>/dev/null
    fi
    if [ ! -z "$AI_PID" ]; then
        kill $AI_PID 2>/dev/null
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo "🌐 Starting web server on port $WEB_PORT..."
$PYTHON_CMD -m http.server $WEB_PORT &
WEB_PID=$!

if [ "$AI_SERVER" = true ]; then
    echo "🤖 Preparing AI server..."
    
    # Check if model exists in ~/.cache/huggingface/hub/
    MODEL_PATH="$HOME/.cache/huggingface/hub/models--ggml-org--SmolVLM-500M-Instruct-GGUF/snapshots"
    if [ ! -d "$MODEL_PATH" ]; then
        echo "📥 Downloading SmolVLM model (this may take a few minutes)..."
        echo "   Model will be cached for future use"
        echo ""
        echo "⏳ Progress:"
        echo "   ⬜ Connecting to Hugging Face"
        echo "   ⬜ Downloading model files"
        echo "   ⬜ Verifying download"
        echo ""
        
        # Download and start the model (mmproj downloads automatically)
        llama-server -hf ggml-org/SmolVLM-500M-Instruct-GGUF -ngl 99 --port $AI_PORT --host 0.0.0.0 &
        
        # Wait for model download to complete or fail
        while true; do
            if [ -d "$MODEL_PATH" ]; then
                echo "✅ Model downloaded successfully!"
                break
            fi
            
            if ! ps -p $! > /dev/null; then
                echo "❌ Model download failed. Please check your internet connection and try again."
                exit 1
            fi
            
            sleep 1
        done
        
        # Kill the initial server instance
        kill $! 2>/dev/null
    else
        echo "✅ SmolVLM model found in cache"
    fi
    
    echo ""
    echo "🚀 Starting AI server on port $AI_PORT..."
    
    # Start the server with the downloaded model
    llama-server -hf ggml-org/SmolVLM-500M-Instruct-GGUF -ngl 99 --port $AI_PORT --host 0.0.0.0 &
    AI_PID=$!
    
    echo "⏳ Waiting for AI server to initialize..."
    echo "   This may take a few seconds..."
    
    # Wait for server to be ready
    MAX_RETRIES=30
    RETRY_COUNT=0
    while ! curl -s "http://localhost:$AI_PORT/health" > /dev/null; do
        sleep 1
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo "❌ AI server failed to start. Please check the logs and try again."
            cleanup
            exit 1
        fi
        echo -n "."
    done
    echo ""
    echo "✅ AI server ready!"
fi

echo ""
echo "🎉 Servers started successfully!"
echo "📱 Open your browser and go to:"
echo "   👉 http://localhost:$WEB_PORT"
echo ""
if [ "$AI_SERVER" = true ]; then
    echo "🤖 AI Server: http://localhost:$AI_PORT"
    echo "   Status: http://localhost:$AI_PORT/health"
else
echo "🤖 AI Server: Setting up your personal AI model (this keeps you safe!)"
echo "   📥 Your local model will be downloaded automatically on first use"
echo "   🔒 This protects your privacy - everything stays on your device"
echo "   ⏱️  One-time setup takes 2-3 minutes, then it's instant forever"
fi
echo ""
echo "🎯 Next steps:"
echo "   1. Allow camera permissions"
echo "   2. Start scanning items with AI!"
echo "   3. Click 'Setup eBay API' for real pricing"
echo ""
echo "🛑 Press Ctrl+C to stop all servers"
echo ""

# Wait for background processes
wait
