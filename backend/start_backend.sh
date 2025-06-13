#!/bin/bash
# Script to start the backend server with proper environment and Python path

# Ensure GEMINI_API_KEY is set from GOOGLE_API_KEY if not already set
if [ -z "$GEMINI_API_KEY" ] && [ ! -z "$GOOGLE_API_KEY" ]; then
  export GEMINI_API_KEY="$GOOGLE_API_KEY"
fi

# Set PYTHONPATH to include src directory
export PYTHONPATH="$PYTHONPATH:$(pwd)/src"

# Start the backend server
uvicorn agent.app:app --host 0.0.0.0 --port "${PORT:-8080}"
