FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

# Install dependencies
RUN apt-get update && apt-get install -y wget jq curl debian-keyring debian-archive-keyring apt-transport-https

# Install Ollama using the provided script
RUN curl -fsSL https://ollama.com/install.sh | sh



# Download and install the latest Caddy
RUN LATEST_CADDY_URL=$(wget -qO- "https://api.github.com/repos/caddyserver/caddy/releases/latest" | jq -r '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")).browser_download_url') \
    && wget --no-check-certificate "$LATEST_CADDY_URL" -O caddy.tar.gz \
    && tar -xvf caddy.tar.gz -C /usr/bin caddy \
    && chown root:root /usr/bin/caddy \
    && chmod 755 /usr/bin/caddy

# Copy the Caddyfile and .env to the container
COPY Caddyfile /etc/caddy/Caddyfile
# COPY .env /etc/caddy/.env

# # Load environment variables from the .env file
# RUN echo "source /etc/caddy/.env" >> /root/.bashrc

# Set the environment variable for the Ollama host
ENV OLLAMA_HOST=0.0.0.0



# Expose the port that Caddy will listen on
EXPOSE 8081

# Copy a script to start both Ollama and Caddy
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entrypoint to the script
ENTRYPOINT ["/start.sh"]
