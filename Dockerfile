FROM nvidia/cuda:12.5.0-runtime-ubuntu22.04

# Install dependencies
RUN apt-get update && apt-get install -y wget jq curl

# Install Ollama using the provided script
RUN curl -fsSL https://ollama.com/install.sh | sh





# Set the environment variable for the Ollama host
ENV OLLAMA_HOST=0.0.0.0



# Expose the port that Caddy will listen on
EXPOSE 11434

# Copy a script to start both Ollama and Caddy
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entrypoint to the script
ENTRYPOINT ["/start.sh"]
