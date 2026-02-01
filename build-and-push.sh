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
echo "========================================"
echo ""

# Build the image
if [ "$GITLAB_VERSION" = "latest" ]; then
    echo "📦 Building latest version..."
    docker build -f docker/Dockerfile \
        -t $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest \
        -t $IMAGE_NAME:latest .
else
    # Extract major.minor version (e.g., 18.7 from 18.7.2)
    GITLAB_MINOR=$(echo $GITLAB_VERSION | cut -d. -f1,2)
    
    echo "📦 Building version $GITLAB_VERSION (tags: $GITLAB_VERSION, $GITLAB_MINOR)..."
    docker build -f docker/Dockerfile --build-arg GITLAB_VERSION=$GITLAB_VERSION \
        -t $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_VERSION \
        -t $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_MINOR \
        -t $IMAGE_NAME:$GITLAB_VERSION \
        -t $IMAGE_NAME:$GITLAB_MINOR .
fi

echo ""
echo "✅ Build complete!"
echo ""

# Show created images
echo "📋 Created images:"
docker images | grep $IMAGE_NAME | head -10
echo ""

# Test the image
echo "🧪 Testing image initialization..."
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  docker run -i --rm $DOCKER_HUB_USERNAME/$IMAGE_NAME:${GITLAB_VERSION} 2>/dev/null | grep -q "gitlab-docs-mcp" && echo "✅ Test passed!" || echo "❌ Test failed!"
echo ""

# Ask for push confirmation
read -p "🚀 Push images to Docker Hub? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping push. Done!"
    exit 0
fi

# Login to Docker Hub
echo "🔐 Logging into Docker Hub..."
docker login

echo ""
echo "📤 Pushing images to Docker Hub..."

if [ "$GITLAB_VERSION" = "latest" ]; then
    docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest
else
    docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_VERSION
    docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:$GITLAB_MINOR
fi

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
