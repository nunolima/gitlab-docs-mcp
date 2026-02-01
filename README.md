# GitLab Documentation MCP Server

A Model Context Protocol (MCP) server that provides searchable access to GitLab's official documentation. This server indexes markdown documentation from multiple GitLab OSS repositories and makes it available for AI assistants and other MCP clients.

## Features

- **Full-text search** across GitLab documentation using SQLite FTS5
- **Version-specific docs** - Build for any GitLab version (e.g., 18.7.2) or latest
- **Multiple repositories** indexed:
  - GitLab CE/EE (main application)
  - GitLab Runner (CI/CD runner)
  - Omnibus GitLab (installation packages)
  - Gitaly (Git RPC service)
  - GitLab Pages (static sites)
  - GitLab Agent (Kubernetes integration, includes KAS)
- **Optimized Docker image** - Uses sparse checkout and filters to minimize size

## Building the Docker Image

### Find the GitLab Version

Look for the latest patch version for your desired GitLab release:
- [GitLab 18.7.x tags](https://gitlab.com/gitlab-org/gitlab/-/tags?sort=updated_desc&search=v18.7.)
- [GitLab 18.6.x tags](https://gitlab.com/gitlab-org/gitlab/-/tags?sort=updated_desc&search=v18.6.)
- [All GitLab tags](https://gitlab.com/gitlab-org/gitlab/-/tags?sort=updated_desc)

### Build for Specific Version

```bash
# Set the GitLab version you want (use full patch version)
GITLAB_VERSION=18.7.2

# Build the image
GITLAB_MINOR=$(echo $GITLAB_VERSION | cut -d. -f1,2)
docker build -f docker/Dockerfile --build-arg GITLAB_VERSION=$GITLAB_VERSION \
    -t gitlab-docs-mcp:$GITLAB_VERSION \
    -t mcp/gitlab-docs-mcp:$GITLAB_VERSION \
    -t gitlab-docs-mcp:$GITLAB_MINOR \
    -t mcp/gitlab-docs-mcp:$GITLAB_MINOR .

# Verify the images were created
echo "\nCreated images:"
docker images | grep gitlab-docs-mcp

# Test the image - initialize and list tools
echo "\nTesting MCP server initialization:"
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  docker run -i --rm mcp/gitlab-docs-mcp:$GITLAB_VERSION | jq .

echo "\nListing available tools:"
(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'; \
 echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}') | \
  docker run -i --rm mcp/gitlab-docs-mcp:$GITLAB_VERSION 2>/dev/null | tail -1 | jq .
```

### Build for Latest (Main Branch)

```bash
docker build -f docker/Dockerfile \
    -t gitlab-docs-mcp:latest \
    -t mcp/gitlab-docs-mcp:latest .

# Verify the images were created
echo "\nCreated images:"
docker images | grep gitlab-docs-mcp

# Test the image - initialize and list tools
echo "\nTesting MCP server initialization:"
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  docker run -i --rm mcp/gitlab-docs-mcp:latest | head -20
echo "\nListing available tools:"
(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'; \
 echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}') | \
  docker run -i --rm mcp/gitlab-docs-mcp:latest 2>/dev/null | tail -1 | jq .```

## Usage

### With Claude Desktop

Add to your Claude Desktop MCP settings (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "gitlab-docs": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "mcp/gitlab-docs-mcp:18.7.2"]
    }
  }
}
```

### With Cline/Cursor

Add to your MCP server settings:

```json
{
  "mcpServers": {
    "gitlab-docs": {
      "type": "stdio",
      "command": "docker",
      "args": ["run", "-i", "--rm", "mcp/gitlab-docs-mcp:18.7"]
    }
  }
}
```

### With MCP CLI

```bash
# Search documentation
mcp search "How to configure GitLab Runner"

# Run directly
docker run -i --rm mcp/gitlab-docs-mcp:18.7.2
```

## How It Works

1. **Build time**: Clones doc folders from GitLab repositories using sparse checkout
2. **Indexing**: Parses markdown files and builds an SQLite FTS5 search index
3. **Runtime**: MCP server provides search tools to query the indexed documentation

## Versioning Strategy

- **Main GitLab repo**: Uses full version tag (e.g., `v18.7.2-ee`)
- **Omnibus GitLab**: Uses full version with +ee suffix (e.g., `18.7.2+ee.0`)
- **Other repositories**: Use major.minor.0 version (e.g., `v18.7.0`)
  - This uses the first stable release (.0) for each major.minor version
  - Example: Building GitLab 18.7.2 will use Runner/Gitaly/Pages/Agent v18.7.0

## Development

### Project Structure

```
python/gitlab-docs-mcp/
├── docker/
│   └── Dockerfile         # Main Dockerfile with version support
├── indexer/
│   └── build_index.py     # Builds search index from markdown files
├── server/
│   └── main.py           # MCP server implementation
├── data/
│   └── docs.db           # SQLite FTS5 database (generated)
└── repos/                # Cloned documentation (generated)
```

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Clone repos manually for testing
# (or let Docker handle it)

# Build index
python indexer/build_index.py

# Run server
python -m server.main
```

## License

MIT License - Copyright (c) 2026 Nuno Lima

This project indexes documentation from GitLab's open source repositories. See individual repository licenses for details.

