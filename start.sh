#!/bin/bash

# Function to log errors
log_error() {
    echo "ERROR: $1" >&2
}

# Print the environment variables for debugging
echo "OLLAMA_API_KEY: '$OLLAMA_API_KEY'"
echo "OLLAMA_MODEL: '$OLLAMA_MODEL'"

# Ensure required environment variables are set
if [ -z "$OLLAMA_API_KEY" ]; then
    echo "OLLAMA_API_KEY is not set. Exiting."
    exit 1
fi

if [ -z "$OLLAMA_MODEL" ]; then
    echo "OLLAMA_MODEL is not set, using default: llama3.2-vision:11b"
    export OLLAMA_MODEL="llama3.2-vision:11b"
fi

# Wait for GPU to become available
echo "Waiting for GPU to become available..."
while ! nvidia-smi &> /dev/null; do
  echo "GPU not detected. Waiting..."
  sleep 5
done
echo "GPU detected successfully."

# Listing GPU
echo "Listing GPU..."
nvidia-smi -L

# Start ollama in the background
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama server to be ready
echo "Waiting for Ollama server to start..."
while ! curl -s http://localhost:11434/api/tags >/dev/null; do
    sleep 1
done
echo "Ollama server is ready"



# Start caddy in the background
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!

# Function to check process status
check_process() {
    wait $1
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        echo "Process $2 ($1) has exited with status $STATUS"
        exit $STATUS
    fi
}

# Handle shutdown signals
trap "kill $OLLAMA_PID $CADDY_PID; exit 0" SIGTERM SIGINT

# Wait for both services to start and monitor them
while true; do
    if ! ps -p $OLLAMA_PID > /dev/null; then
        echo "Ollama service is not running, checking for exit status"
        check_process $OLLAMA_PID "Ollama"
        # Only restart if check_process hasn't exited the script
        echo "Starting Ollama now"
        ollama serve &
        OLLAMA_PID=$!
    fi
    if ! ps -p $CADDY_PID > /dev/null; then
        echo "Caddy service is not running, checking for exit status"
        check_process $CADDY_PID "Caddy"
        # Only restart if check_process hasn't exited the script
        echo "Starting Caddy now"
        caddy run --config /etc/caddy/Caddyfile &
        CADDY_PID=$!
    fi
    sleep 1
done

Pull the model
echo "Pulling $OLLAMA_MODEL model..."
curl -X POST http://localhost:11434/api/pull -d "{\"name\":\"$OLLAMA_MODEL\"}"