import logging
import sqlite3
import sys
from mcp.server.fastmcp import FastMCP

# Set up logging to stderr (never use print() in STDIO servers)
logging.basicConfig(level=logging.INFO, stream=sys.stderr)
logger = logging.getLogger(__name__)

DB_PATH = "data/docs.db"

mcp = FastMCP("gitlab-docs-mcp")


def get_db():
    return sqlite3.connect(DB_PATH)


@mcp.tool()
def search_docs(query: str, limit: int = 10) -> str:
    """
    Search GitLab documentation.
    
    Args:
        query: Search query string
        limit: Maximum number of results to return (default: 10)
    
    Returns:
        Formatted search results with paths, titles, and repositories
    """
    logger.info(f"Searching docs with query: {query}, limit: {limit}")
    conn = get_db()

    cur = conn.execute("""
    SELECT path, title, repo
    FROM docs
    WHERE docs MATCH ?
    LIMIT ?
    """, (query, limit))

    rows = cur.fetchall()
    conn.close()

    if not rows:
        return "No documents found matching your query."

    # Format results as readable text for LLM
    results = [f"Found {len(rows)} result(s):\n"]
    for i, (path, title, repo) in enumerate(rows, 1):
        results.append(f"{i}. {title}")
        results.append(f"   Repository: {repo}")
        results.append(f"   Path: {path}\n")
    
    return "\n".join(results)


@mcp.tool()
def get_doc(path: str) -> str:
    """
    Get full document content by path.
    
    Args:
        path: Full path to the document file
    
    Returns:
        The full markdown content of the document
    """
    logger.info(f"Fetching document: {path}")
    conn = get_db()

    cur = conn.execute("""
    SELECT content, title, repo
    FROM docs
    WHERE path = ?
    """, (path,))

    row = cur.fetchone()
    conn.close()

    if not row:
        return f"Document not found: {path}"

    content, title, repo = row
    return f"# {title}\n\nRepository: {repo}\nPath: {path}\n\n{content}"


def main():
    """Main entry point for the MCP server."""
    logger.info("Starting GitLab Docs MCP server")
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()

