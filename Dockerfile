FROM elixir:1.15

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    inotify-tools \
    sqlite3 \
    glibc-source \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

