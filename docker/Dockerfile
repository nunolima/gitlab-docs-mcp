FROM python:3.12-slim

# GitLab version to clone (e.g., 18.7.2, latest for main branch)
ARG GITLAB_VERSION=latest

# Add MCP registry label for package validation
LABEL io.modelcontextprotocol.server.name="io.github.nunolima/gitlab-docs-mcp"

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download documentation via GitLab Archive API (retry with exponential backoff)
COPY docker/clone-docs.sh /tmp/clone-docs.sh
RUN chmod +x /tmp/clone-docs.sh && \
    /tmp/clone-docs.sh "$GITLAB_VERSION" && \
    rm /tmp/clone-docs.sh

# Remove non-markdown files to save space (images, videos, etc.)
RUN find repos -type f ! -name "*.md" -delete && \
    find repos -type d -empty -delete

# Copy dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# Build search index at image build time
RUN python indexer/build_index.py

# Run MCP server
CMD ["python", "-m", "server.main"]
