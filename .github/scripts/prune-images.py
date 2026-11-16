#!/usr/bin/env python3
"""Prune stale Patchy image tags from Docker Hub and GHCR.

Keeps the `latest` tag, every tag pointing at the same digest as `latest`
(the current date-sha tag), any extra tags listed in KEEP_TAGS, and the
cosign `sha256-<digest>.sig` signatures for the kept digests.

Set APPLY=true to delete. Anything else performs a dry run.
"""

import json
import os
import sys
import urllib.error
import urllib.request

APPLY = os.environ.get("APPLY", "false").lower() == "true"
KEEP_TAGS = {tag.strip() for tag in os.environ.get("KEEP_TAGS", "").split(",") if tag.strip()}


def http(url, method="GET", token=None, payload=None, accept="application/json"):
    headers = {"User-Agent": "patchy-prune", "Accept": accept}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if payload is not None:
        data = json.dumps(payload).encode()
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request) as response:
            body = response.read()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")
        raise SystemExit(f"{method} {url} failed: {error.code} {detail}") from error


def signature_digest(tag):
    if tag.startswith("sha256-") and tag.endswith(".sig"):
        return "sha256:" + tag[len("sha256-") : -len(".sig")]
    return None


def prune_dockerhub():
    user = os.environ["DOCKERHUB_USER"]
    password = os.environ["DOCKERHUB_TOKEN"]
    repo = os.environ.get("DOCKERHUB_REPO", "starkayc/patchy")

    jwt = http(
        "https://hub.docker.com/v2/users/login/",
        "POST",
        payload={"username": user, "password": password},
    )["token"]

    tags = []
    url = f"https://hub.docker.com/v2/repositories/{repo}/tags/?page_size=100"
    while url:
        page = http(url, token=jwt)
        tags.extend(page.get("results") or [])
        url = page.get("next")

    by_name = {tag["name"]: tag for tag in tags}
    if "latest" not in by_name:
        raise SystemExit("Docker Hub: latest tag not found")

    latest_digest = by_name["latest"].get("digest")
    keep = set(KEEP_TAGS) | {"latest"}
    keep |= {name for name, tag in by_name.items() if tag.get("digest") == latest_digest}
    keep_digests = {by_name[name].get("digest") for name in keep if name in by_name}
    keep |= {name for name in by_name if signature_digest(name) in keep_digests}

    stale = sorted(name for name in by_name if name not in keep)
    print(f"Docker Hub: keeping {', '.join(sorted(keep))}")
    for name in stale:
        if APPLY:
            http(f"https://hub.docker.com/v2/repositories/{repo}/tags/{name}/", "DELETE", token=jwt)
            print(f"Docker Hub: deleted {name}")
        else:
            print(f"Docker Hub: would delete {name}")


def ghcr_versions(package, token):
    versions = []
    page = 1
    while True:
        url = (
            f"https://api.github.com/user/packages/container/{package}/versions"
            f"?per_page=100&page={page}"
        )
        batch = http(url, token=token, accept="application/vnd.github+json")
        if not batch:
            break
        versions.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return versions


def prune_ghcr():
    token = os.environ["GHCR_TOKEN"]
    package = os.environ.get("GHCR_PACKAGE", "patchy")
    versions = ghcr_versions(package, token)

    def tags_of(version):
        return (version.get("metadata") or {}).get("container", {}).get("tags") or []

    latest = next((version for version in versions if "latest" in tags_of(version)), None)
    if latest is None:
        raise SystemExit("GHCR: latest version not found")

    keep_tags = set(KEEP_TAGS) | {"latest"}
    keep_digests = {latest["name"]}
    keep_ids = set()

    for version in versions:
        if set(tags_of(version)) & keep_tags or version["name"] in keep_digests:
            keep_ids.add(version["id"])
            keep_digests.add(version["name"])

    for version in versions:
        if any(signature_digest(tag) in keep_digests for tag in tags_of(version)):
            keep_ids.add(version["id"])

    # Leave untagged versions alone: they may be attestations for kept images.
    stale = [version for version in versions if version["id"] not in keep_ids and tags_of(version)]
    print(f"GHCR: keeping versions {', '.join(str(v) for v in sorted(keep_ids))}")
    for version in stale:
        label = ",".join(tags_of(version)) or version["name"]
        if APPLY:
            http(
                f"https://api.github.com/user/packages/container/{package}/versions/{version['id']}",
                "DELETE",
                token=token,
                accept="application/vnd.github+json",
            )
            print(f"GHCR: deleted {version['id']} ({label})")
        else:
            print(f"GHCR: would delete {version['id']} ({label})")


def main():
    print("mode:", "apply" if APPLY else "dry-run")
    prune_dockerhub()
    prune_ghcr()


if __name__ == "__main__":
    sys.exit(main())
