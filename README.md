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

## Installation

This server is published to the [MCP Community Registry](https://registry.modelcontextprotocol.io/v0/servers?search=io.github.nunolima/gitlab-docs-mcp).

### Prerequisites

- Docker installed and running
- MCP-compatible client (Claude Desktop, Cline, Cursor, etc.)

### Setup Instructions

#### Claude Desktop

1. **Locate your config file**:
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
   - Linux: `~/.config/Claude/claude_desktop_config.json`

2. **Add the server configuration**:
   ```json
   {
     "mcpServers": {
       "gitlab-docs": {
         "command": "docker",
         "args": ["run", "-i", "--rm", "nunolima/gitlab-docs-mcp:18.7"]
       }
     }
   }
   ```

3. **Restart Claude Desktop** - The server will appear in the MCP tools menu (🔌 icon)

#### Cline (VS Code Extension)

1. Open Cline settings in VS Code
2. Navigate to **MCP Servers** section
3. Add this configuration:
   ```json
   {
     "mcpServers": {
       "gitlab-docs": {
         "command": "docker",
         "args": ["run", "-i", "--rm", "nunolima/gitlab-docs-mcp:18.7"]
       }
     }
   }
   ```
4. Reload VS Code window

#### Cursor

1. Open Cursor settings
2. Go to **Features** → **Model Context Protocol**
3. Add the server configuration:
   ```json
   {
     "mcpServers": {
       "gitlab-docs": {
         "command": "docker",
         "args": ["run", "-i", "--rm", "nunolima/gitlab-docs-mcp:18.7"]
       }
     }
   }
   ```

### Version Selection

Choose the version that matches your GitLab deployment:

```json
// For GitLab 18.7.x
"args": ["run", "-i", "--rm", "nunolima/gitlab-docs-mcp:18.7"]

// For latest GitLab version
"args": ["run", "-i", "--rm", "nunolima/gitlab-docs-mcp:latest"]
```

### Verification

After setup, verify the server is working:

1. **In Claude Desktop**: Look for the 🔌 icon - you should see "gitlab-docs" listed
2. **Test a query**: Ask Claude to search GitLab documentation, e.g., "Search GitLab docs for CI/CD pipeline configuration"
3. **Check Docker**: Run `docker ps -a` after making a query to see if the container ran

### Troubleshooting

**Server not appearing in client**:
- Ensure Docker is running: `docker info`
- Check config file JSON is valid (no trailing commas, proper quotes)
- Restart your MCP client completely

**"Cannot connect to Docker daemon" error**:
- Start Docker Desktop
- Verify Docker is accessible: `docker ps`

**Old documentation version**:
- Use a different version tag (see Version Selection above)
- Check available tags: https://hub.docker.com/r/nunolima/gitlab-docs-mcp/tags

## Available Tools

Once connected, the server provides these tools to your AI assistant:

- **`search_docs`**: Full-text search across all GitLab documentation
  - Example: "Search for GitLab Runner configuration options"
  
- **`get_doc`**: Retrieve specific documentation by file path
  - Example: "Get the GitLab CI/CD variables documentation"
  
- **`list_repositories`**: List all indexed GitLab repositories
  - Shows: GitLab CE/EE, Runner, Omnibus, Gitaly, Pages, Agent

### Example Queries

Try asking your AI assistant:
- "Search GitLab docs for how to set up GitLab Runner with Docker"
- "Find documentation about GitLab CI/CD pipeline syntax"
- "What does the GitLab documentation say about backup and restore?"
- "Search for GitLab Pages custom domain configuration"

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

