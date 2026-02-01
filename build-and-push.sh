#!/bin/bash
set -e

# Build and push GitLab Documentation MCP Server Docker images
# Usage: ./build-and-push.sh [GITLAB_VERSION]
# Example: ./build-and-push.sh 18.7.2

GITLAB_VERSION=${1:-"latest"}
DOCKER_HUB_USERNAME="nunolima"
IMAGE_NAME="gitlab-docs-mcp"

echo "========================================"
echo "Building GitLab Docs MCP Server"
echo "GitLab Version: $GITLAB_VERSION"
echo "Docker Hub: $DOCKER_HUB_USERNAME/$IMAGE_NAME"
echo "Platforms: linux/amd64, linux/arm64"
echo "========================================"
echo ""

# Create/use buildx builder for multi-platform builds
echo "🔧 Setting up Docker buildx for multi-platform builds..."
docker buildx create --name mcp-builder --use 2>/dev/null || docker buildx use mcp-builder || docker buildx use default
docker buildx inspect --bootstrap

# Build the image for multiple platforms
if [ "$GITLAB_VERSION" = "latest" ]; then
    echo "📦 Building latest version for linux/amd64 and linux/arm64..."
    docker buildx build -f docker/Dockerfile \
        --platform linux/amd64,linux/arm64 \
        --push \
        -t $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest .
else
    # Extract major.minor version (e.g., 18.7 from 18.7.2)
    GITLAB_MINOR=$(echo $GITLAB_VERSION | cut -d. -f1,2)
    
    echo "📦 Building version $GITLAB_VERSION (tags: $GITLAB_VERSION, $GITLAB_MINOR) for linux/amd64 and linux/arm64..."
    docker buildx build -f docker/Dockerfile \
        --platform linux/amd64,linux/arm64 \
        --build-arg GITLAB_VERSION=$GITLAB_VERSION \
        --push \
        -t $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_VERSION \
        -t $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_MINOR .
fi

echo ""
echo "✅ Build and push complete!"
echo ""

# Test the image (pull and test, since buildx builds directly to registry)
echo "🧪 Testing image initialization..."
docker pull $DOCKER_HUB_USERNAME/$IMAGE_NAME:${GITLAB_VERSION} >/dev/null 2>&1
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  docker run -i --rm $DOCKER_HUB_USERNAME/$IMAGE_NAME:${GITLAB_VERSION} 2>/dev/null | grep -q "gitlab-docs-mcp" && echo "✅ Test passed!" || echo "❌ Test failed!"

echo ""
echo "🎉 Successfully published!"
echo ""
echo "📝 Your images are available at:"
echo "   https://hub.docker.com/r/$DOCKER_HUB_USERNAME/$IMAGE_NAME"
echo ""
echo "💡 Users can now run:"
if [ "$GITLAB_VERSION" = "latest" ]; then
    echo "   docker run -i --rm $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest"
else
    echo "   docker run -i --rm $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_VERSION"
    echo "   docker run -i --rm $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_MINOR"
fi
echo ""

# Logout from Docker Hub
echo "🔐 Logging out from Docker Hub..."
docker logout
echo "✅ Logged out successfully!"
echo ""

# Ask if user wants to publish to MCP registry
read -p "📢 Publish to MCP registry? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping MCP registry publication. Done!"
    exit 0
fi

echo "📢 Publishing to MCP registry..."
echo "Note: Make sure you've run 'mcp-publisher login github' first"
echo ""

# Publish to MCP registry
if mcp-publisher publish; then
    echo ""
    echo "✅ Successfully published to MCP registry!"
    echo ""
    
    # Verify publication
    echo "🔍 Verifying publication..."
    sleep 2  # Give the registry a moment to update
    curl -s "https://registry.modelcontextprotocol.io/v0/servers?search=io.github.nunolima/gitlab-docs-mcp" | grep -q "gitlab-docs-mcp" && \
        echo "✅ Verification successful! Server is live in the MCP registry." || \
        echo "⚠️  Verification failed. Check manually at: https://registry.modelcontextprotocol.io/v0/servers?search=io.github.nunolima/gitlab-docs-mcp"
else
    echo ""
    echo "❌ MCP registry publication failed. You may need to:"
    echo "   1. Run 'mcp-publisher login github' to authenticate"
    echo "   2. Bump the version in server.json if publishing a duplicate version"
    echo "   3. Check that server.json is valid"
fi
