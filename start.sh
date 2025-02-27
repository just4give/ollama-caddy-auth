#!/bin/bash

# Print the environment variable for debugging
echo "OLLAMA_API_KEY: '$OLLAMA_API_KEY'"

ollama serve &
OLLAMA_PID=$!

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
trap "kill $OLLAMA_PID; exit 0" SIGTERM SIGINT

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
    
    sleep 1
done
