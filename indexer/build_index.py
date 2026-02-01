import sqlite3
from pathlib import Path
import frontmatter


DB_PATH = "data/docs.db"

DOC_ROOTS = {
    "gitlab": "repos/gitlab/doc",
    "runner": "repos/gitlab-runner/docs",
    "omnibus": "repos/omnibus-gitlab/doc",
    "gitaly": "repos/gitaly/doc",
    "pages": "repos/gitlab-pages/doc",
    "agent": "repos/gitlab-agent/doc",
}


def init_db(conn):
    conn.execute("""
    CREATE VIRTUAL TABLE IF NOT EXISTS docs USING fts5(
        path,
        repo,
        category,
        title,
        content
    )
    """)
    conn.commit()


def iter_markdown():
    for repo, root in DOC_ROOTS.items():
        base = Path(root)
        if not base.exists():
            continue

        for path in base.rglob("*.md"):
            yield repo, path


def main():
    Path("data").mkdir(exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    init_db(conn)

    cur = conn.cursor()
    cur.execute("DELETE FROM docs")

    count = 0

    for repo, path in iter_markdown():
        post = frontmatter.load(path)

        title = post.metadata.get("title", path.stem)
        content = post.content

        parts = path.parts
        category = parts[2] if len(parts) > 2 else "general"

        cur.execute("""
        INSERT INTO docs
        VALUES (?, ?, ?, ?, ?)
        """, (
            str(path),
            repo,
            category,
            title,
            content,
        ))

        count += 1

    conn.commit()
    conn.close()

    print(f"Indexed {count} documents")


if __name__ == "__main__":
    main()

