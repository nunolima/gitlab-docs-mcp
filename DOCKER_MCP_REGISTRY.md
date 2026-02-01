# Adding GitLab Docs MCP to Docker's Official MCP Registry

## Overview

This guide will help you add your GitLab Docs MCP server to Docker's Official MCP Registry, which makes it available in:
- [Docker Hub MCP Catalog](https://hub.docker.com/mcp)
- Docker Desktop's MCP Toolkit
- Docker Hub (self-provided image at `nunolima/gitlab-docs-mcp`)

## Prerequisites

- Docker Desktop installed
- Go 1.24+
- [Task](https://taskfile.dev/) installed
- GitHub account

## Steps to Submit

### 1. Fork the Docker MCP Registry

Go to https://github.com/docker/mcp-registry and click "Fork"

### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/mcp-registry.git
cd mcp-registry
```

### 3. Create Your Server Entry

Copy the prepared files from `.docker-mcp-registry/` to the registry:

```bash
# From your gitlab-docs-mcp directory
cd /path/to/your/gitlab-docs-mcp

# Copy to the mcp-registry repo
mkdir -p /path/to/mcp-registry/servers/gitlab-docs-mcp
cp .docker-mcp-registry/server.yaml /path/to/mcp-registry/servers/gitlab-docs-mcp/
cp .docker-mcp-registry/tools.json /path/to/mcp-registry/servers/gitlab-docs-mcp/
cp .docker-mcp-registry/readme.md /path/to/mcp-registry/servers/gitlab-docs-mcp/
```

### 4. Validate Your Entry

```bash
cd /path/to/mcp-registry

# Validate the server configuration
task validate -- --name gitlab-docs-mcp

# Build and test (skips tool testing since tools.json is provided)
task build -- --tools gitlab-docs-mcp
```

### 5. Test Locally in Docker Desktop

```bash
# Generate catalog
task catalog -- gitlab-docs-mcp

# Import to Docker Desktop
docker mcp catalog import $PWD/catalogs/gitlab-docs-mcp/catalog.yaml

# Now check Docker Desktop's MCP Toolkit - you should see "GitLab Documentation" listed
# Test it by enabling and using it

# When done testing, reset catalog
docker mcp catalog reset
```

### 6. Commit and Push

```bash
git checkout -b add-gitlab-docs-mcp
git add servers/gitlab-docs-mcp/
git commit -m "Add GitLab Documentation MCP Server

- Searchable access to GitLab official documentation
- Indexes GitLab CE/EE, Runner, Omnibus, Gitaly, Pages, and Agent docs
- Full-text search using SQLite FTS5
- Self-provided image: nunolima/gitlab-docs-mcp:18.7"

git push origin add-gitlab-docs-mcp
```

### 7. Create Pull Request

1. Go to https://github.com/YOUR_USERNAME/mcp-registry
2. Click "Contribute" → "Open pull request"
3. Use this title: `Add GitLab Documentation MCP Server`
4. Use the PR template (`.github/PULL_REQUEST_TEMPLATE.md`) for the description:

```markdown
## MCP Server Addition

### Server Information
- **Name**: GitLab Documentation
- **Category**: documentation
- **Type**: Local (Self-Provided Image)
- **Image**: nunolima/gitlab-docs-mcp:18.7
- **Repository**: https://github.com/nunolima/gitlab-docs-mcp

### Description
Provides searchable access to GitLab's official documentation from multiple repositories using full-text search.

### Testing
- [ ] `task validate -- --name gitlab-docs-mcp` passes
- [ ] `task build -- --tools gitlab-docs-mcp` passes
- [ ] Tested locally in Docker Desktop MCP Toolkit

### Additional Notes
This server indexes documentation from:
- GitLab CE/EE
- GitLab Runner
- Omnibus GitLab
- Gitaly
- GitLab Pages
- GitLab Agent

Currently indexes GitLab 18.7.x documentation.
```

5. Submit the PR

### 8. Share Test Credentials (if needed)

If your server requires credentials to test, fill out: https://forms.gle/6Lw3nsvu2d6nFg8e6

Since GitLab Docs MCP doesn't require credentials, you can skip this.

### 9. Wait for Review

The Docker team will review your PR. Once approved:
- Your server will appear in Docker Hub MCP Catalog within 24 hours
- It will be available in Docker Desktop's MCP Toolkit
- Users can install it directly from Docker's curated catalog

## Files Created

The following files have been prepared in `.docker-mcp-registry/`:

1. **server.yaml** - Server configuration
   - Name, image, category, tags
   - Links to your GitHub repo
   - Icon and description

2. **tools.json** - List of tools your server provides
   - search_docs
   - get_doc
   - list_repositories

3. **readme.md** - Documentation and features

## Expected Timeline

- PR Review: Usually within a few days
- Publication: Within 24 hours of approval
- Your server will then be discoverable in Docker's official MCP catalog

## Benefits

After acceptance:
- ✅ Listed in Docker Hub MCP Catalog
- ✅ Available in Docker Desktop MCP Toolkit UI
- ✅ Discoverable by millions of Docker users
- ✅ Official Docker curation and quality badge
- ✅ Easier installation for users through Docker's UI

## Troubleshooting

**Validation fails**: Check that `server.yaml` follows the correct schema
**Build fails**: Ensure your Docker image is publicly accessible and runs correctly
**Tools not listing**: Provide `tools.json` file (already done for you)

## References

- [Contributing Guide](https://github.com/docker/mcp-registry/blob/main/CONTRIBUTING.md)
- [Example Servers](https://github.com/docker/mcp-registry/tree/main/servers)
- [Docker MCP Catalog](https://hub.docker.com/mcp)
