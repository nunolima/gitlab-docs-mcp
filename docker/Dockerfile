FROM python:3.12-slim

# GitLab version to clone (e.g., 18.7.2, latest for main branch)
ARG GITLAB_VERSION=latest

# Install git
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Set default git user/email and safe directory
RUN git config --global user.name "Docker Build" && \
    git config --global user.email "docker@example.com" && \
    git config --global advice.detachedHead false && \
    git config --global init.defaultBranch main

# Clone GitLab documentation sources for specified version (sparse checkout - docs only)
# Extract major.minor version (e.g., 18.7 from 18.7.2) for projects that don't match patch versions
RUN if [ "$GITLAB_VERSION" = "latest" ]; then \
      # GitLab main repo - doc/ folder only \
      git clone --depth=1 --filter=blob:limit=1m --sparse https://gitlab.com/gitlab-org/gitlab.git repos/gitlab && \
      cd repos/gitlab && git sparse-checkout set doc && cd ../.. && \
      # GitLab Runner - docs/ folder only \
      git clone --depth=1 --filter=blob:limit=1m --sparse https://gitlab.com/gitlab-org/gitlab-runner.git repos/gitlab-runner && \
      cd repos/gitlab-runner && git sparse-checkout set docs && cd ../.. && \
      # Omnibus GitLab - doc/ folder only \
      git clone --depth=1 --filter=blob:limit=1m --sparse https://gitlab.com/gitlab-org/omnibus-gitlab.git repos/omnibus-gitlab && \
      cd repos/omnibus-gitlab && git sparse-checkout set doc && cd ../.. && \
      # Gitaly - doc/ folder only \
      git clone --depth=1 --filter=blob:limit=1m --sparse https://gitlab.com/gitlab-org/gitaly.git repos/gitaly && \
      cd repos/gitaly && git sparse-checkout set doc && cd ../.. && \
      # GitLab Pages - doc/ folder only \
      git clone --depth=1 --filter=blob:limit=1m --sparse https://gitlab.com/gitlab-org/gitlab-pages.git repos/gitlab-pages && \
      cd repos/gitlab-pages && git sparse-checkout set doc && cd ../.. && \
      # GitLab Agent - doc/ folder only \
      git clone --depth=1 --filter=blob:limit=1m --sparse https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent.git repos/gitlab-agent && \
      cd repos/gitlab-agent && git sparse-checkout set doc && cd ../..; \
    else \
      # Extract major.minor version (e.g., 18.7 from 18.7.2) \
      GITLAB_MINOR=$(echo "$GITLAB_VERSION" | cut -d. -f1,2) && \
      # GitLab main repo - use full version with -ee suffix \
      git clone --depth=1 --filter=blob:limit=1m --sparse --branch v${GITLAB_VERSION}-ee https://gitlab.com/gitlab-org/gitlab.git repos/gitlab && \
      cd repos/gitlab && git sparse-checkout set doc && cd ../.. && \
      # Other repos - use major.minor.0 version (use .0 patch as default) \
      git clone --depth=1 --filter=blob:limit=1m --sparse --branch v${GITLAB_MINOR}.0 https://gitlab.com/gitlab-org/gitlab-runner.git repos/gitlab-runner && \
      cd repos/gitlab-runner && git sparse-checkout set docs && cd ../.. && \
      git clone --depth=1 --filter=blob:limit=1m --sparse --branch ${GITLAB_VERSION}+ee.0 https://gitlab.com/gitlab-org/omnibus-gitlab.git repos/omnibus-gitlab && \
      cd repos/omnibus-gitlab && git sparse-checkout set doc && cd ../.. && \
      git clone --depth=1 --filter=blob:limit=1m --sparse --branch v${GITLAB_MINOR}.0 https://gitlab.com/gitlab-org/gitaly.git repos/gitaly && \
      cd repos/gitaly && git sparse-checkout set doc && cd ../.. && \
      git clone --depth=1 --filter=blob:limit=1m --sparse --branch v${GITLAB_MINOR}.0 https://gitlab.com/gitlab-org/gitlab-pages.git repos/gitlab-pages && \
      cd repos/gitlab-pages && git sparse-checkout set doc && cd ../.. && \
      git clone --depth=1 --filter=blob:limit=1m --sparse --branch v${GITLAB_MINOR}.0 https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent.git repos/gitlab-agent && \
      cd repos/gitlab-agent && git sparse-checkout set doc && cd ../..; \
    fi

# Remove non-markdown files to save space (images, videos, etc.)
RUN find repos -type f ! -name "*.md" ! -path "*/.git/*" -delete && \
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

