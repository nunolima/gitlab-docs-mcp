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
