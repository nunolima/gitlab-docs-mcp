                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        docker #!/bin/sh
set -e

GITLAB_VERSION=$1
MAX_RETRIES=5
BASE_DELAY=5

download_docs() {
    project_encoded=$1
    dest_dir=$2
    doc_path=$3
    ref=$4
    required=${5:-true}

    url="https://gitlab.com/api/v4/projects/${project_encoded}/repository/archive.tar.gz?path=${doc_path}"
    if [ -n "$ref" ]; then
        encoded_ref=$(echo "$ref" | sed 's/+/%2B/g')
        url="${url}&sha=${encoded_ref}"
    fi

    mkdir -p "$dest_dir"
    tmpfile=$(mktemp)

    attempt=1
    delay=$BASE_DELAY
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "  [${attempt}/${MAX_RETRIES}] ${dest_dir}/${doc_path} ..."

        # Capture HTTP status separately (don't use -f so we can inspect the code)
        http_code=$(curl -sSL --retry 3 --retry-delay 2 \
            -o "$tmpfile" -w '%{http_code}' "$url" 2>/dev/null) || http_code="000"

        file_size=$(wc -c < "$tmpfile" 2>/dev/null | tr -d ' ')

        # 404 = tag or path doesn't exist -- no point retrying
        if [ "$http_code" = "404" ]; then
            rm -f "$tmpfile"
            if [ "$required" = "true" ]; then
                echo "  FAILED: HTTP 404 - ref or path not found (${url})"
                return 1
            else
                echo "  SKIP: HTTP 404 - ref or path not found (optional repo)"
                return 0
            fi
        fi

        # Validate: HTTP 200, non-trivial size, valid gzip+tar
        if [ "$http_code" = "200" ] && [ "${file_size:-0}" -gt 100 ] \
           && tar xzf "$tmpfile" --strip-components=1 -C "$dest_dir" 2>/dev/null; then
            rm -f "$tmpfile"
            echo "  OK: ${dest_dir}/${doc_path} (${file_size}B)"
            return 0
        fi

        echo "  RETRY: HTTP ${http_code}, size=${file_size}B, waiting ${delay}s..."
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done

    rm -f "$tmpfile"
    if [ "$required" = "true" ]; then
        echo "  FAILED: ${dest_dir} after ${MAX_RETRIES} attempts (HTTP ${http_code}, ${file_size}B)"
        return 1
    else
        echo "  SKIP: ${dest_dir} after ${MAX_RETRIES} attempts (optional repo)"
        return 0
    fi
}

echo "=== Downloading GitLab documentation (version: ${GITLAB_VERSION}) ==="
echo "    Using GitLab Archive API with retry (max ${MAX_RETRIES} attempts per repo)"

if [ "$GITLAB_VERSION" = "latest" ]; then
    download_docs "gitlab-org%2Fgitlab"                             "repos/gitlab"         "doc"  ""
    download_docs "gitlab-org%2Fgitlab-runner"                      "repos/gitlab-runner"  "docs" ""
    download_docs "gitlab-org%2Fomnibus-gitlab"                     "repos/omnibus-gitlab" "doc"  ""
    download_docs "gitlab-org%2Fgitaly"                             "repos/gitaly"         "doc"  ""
    download_docs "gitlab-org%2Fgitlab-pages"                       "repos/gitlab-pages"   "docs" ""
    download_docs "gitlab-org%2Fcluster-integration%2Fgitlab-agent" "repos/gitlab-agent"   "doc"  ""
else
    GITLAB_MINOR=$(echo "$GITLAB_VERSION" | cut -d. -f1,2)
    #                                                                                                               required?
    download_docs "gitlab-org%2Fgitlab"                             "repos/gitlab"         "doc"  "v${GITLAB_VERSION}-ee"  true
    download_docs "gitlab-org%2Fgitlab-runner"                      "repos/gitlab-runner"  "docs" "v${GITLAB_MINOR}.0"     true
    download_docs "gitlab-org%2Fomnibus-gitlab"                     "repos/omnibus-gitlab" "doc"  "${GITLAB_VERSION}+ee.0" true
    download_docs "gitlab-org%2Fgitaly"                             "repos/gitaly"         "doc"  "v${GITLAB_MINOR}.0"     false
    download_docs "gitlab-org%2Fgitlab-pages"                       "repos/gitlab-pages"   "docs" "v${GITLAB_MINOR}.0"     false
    download_docs "gitlab-org%2Fcluster-integration%2Fgitlab-agent" "repos/gitlab-agent"   "doc"  "v${GITLAB_MINOR}.0"     false
fi

echo "=== All documentation downloaded successfully ==="
