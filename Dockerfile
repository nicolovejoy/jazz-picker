# Jazz Picker - LilyPond Server
FROM ubuntu:22.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    guile-3.0 \
    fonts-dejavu \
    fonts-freefont-ttf \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# Install LilyPond 2.25 (development version)
# Note: This installs from source or uses a PPA for dev version
# For now, using stable 2.24 as placeholder - will need to upgrade to 2.25
RUN apt-get update && apt-get install -y lilypond \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create cache directory
RUN mkdir -p /app/cache/pdfs

# Expose Flask port
EXPOSE 5001

# Run the application
CMD ["python3", "app.py"]
