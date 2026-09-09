#!/usr/bin/env bash
# Download and unpack a Linux Isabelle distribution into $ISABELLE_HOME
# (default: $HOME/isabelle-dist). Prefer durable HTTPS mirrors; the official
# isabelle.in.tum.de endpoint redirects to dist.isabelle.cit.tum.de, which is
# frequently unreachable from CI runners.
#
# The full ~1.1 GiB tarball is intentionally NOT vendored in git. GitHub
# Actions caches ~/isabelle-dist between runs so cold downloads happen once
# per cache key. Optional: set ISABELLE_TARBALL to a pre-downloaded archive.
set -euo pipefail

ISABELLE_VERSION="${ISABELLE_VERSION:-Isabelle2025-2}"
ISABELLE_HOME="${ISABELLE_HOME:-$HOME/isabelle-dist}"
# Official Isabelle2025-2_linux.tar.gz (sha256 from mirror.clarkson.edu).
ISABELLE_SHA256="${ISABELLE_SHA256:-a20a507bc7c1270d8be96a9f3fbec06345387789d2dc2c4d3df6260d47bfb33c}"
EXPECTED_MIN_BYTES="${EXPECTED_MIN_BYTES:-1000000000}"
TARBALL="${ISABELLE_TARBALL:-/tmp/${ISABELLE_VERSION}_linux.tar.gz}"

if [ -x "$ISABELLE_HOME/bin/isabelle" ]; then
  echo "Isabelle already installed at $ISABELLE_HOME"
  if [ -n "${GITHUB_PATH:-}" ]; then
    echo "$ISABELLE_HOME/bin" >> "$GITHUB_PATH"
  fi
  echo "$ISABELLE_HOME/bin"
  exit 0
fi

mkdir -p "$ISABELLE_HOME"

download_ok=0
if [ -f "$TARBALL" ] && [ "$(stat -c%s "$TARBALL" 2>/dev/null || echo 0)" -ge "$EXPECTED_MIN_BYTES" ]; then
  echo "Using existing tarball $TARBALL"
  download_ok=1
else
  rm -f "$TARBALL"
  for url in \
    "https://mirror.clarkson.edu/isabelle/dist/${ISABELLE_VERSION}_linux.tar.gz" \
    "https://www.cl.cam.ac.uk/research/hvg/Isabelle/dist/${ISABELLE_VERSION}_linux.tar.gz" \
    "https://isabelle.in.tum.de/dist/${ISABELLE_VERSION}_linux.tar.gz" \
    "http://dist.isabelle.cit.tum.de/dist/${ISABELLE_VERSION}_linux.tar.gz"
  do
    echo "Trying $url"
    if curl -fL --retry 5 --retry-all-errors --connect-timeout 30 --max-time 1800 \
         "$url" -o "$TARBALL" \
       && [ "$(stat -c%s "$TARBALL" 2>/dev/null || echo 0)" -ge "$EXPECTED_MIN_BYTES" ]; then
      echo "Downloaded from $url ($(stat -c%s "$TARBALL") bytes)"
      download_ok=1
      break
    fi
    rm -f "$TARBALL"
  done
fi

if [ "$download_ok" -ne 1 ]; then
  echo "error: failed to obtain ${ISABELLE_VERSION}_linux.tar.gz from any mirror" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  echo "${ISABELLE_SHA256}  ${TARBALL}" | sha256sum -c -
elif command -v shasum >/dev/null 2>&1; then
  echo "${ISABELLE_SHA256}  ${TARBALL}" | shasum -a 256 -c -
else
  echo "warning: no sha256 tool found; skipping checksum verification" >&2
fi

tar -xzf "$TARBALL" -C "$ISABELLE_HOME" --strip-components=1
# Keep caller-supplied tarballs; only delete the default /tmp download.
if [ "$TARBALL" = "/tmp/${ISABELLE_VERSION}_linux.tar.gz" ] && [ -z "${ISABELLE_TARBALL:-}" ]; then
  rm -f "$TARBALL"
fi

test -x "$ISABELLE_HOME/bin/isabelle"
echo "Installed $ISABELLE_VERSION into $ISABELLE_HOME"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$ISABELLE_HOME/bin" >> "$GITHUB_PATH"
fi
echo "$ISABELLE_HOME/bin"
