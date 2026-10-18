#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Copyright (c) 2026 Xebia. All rights reserved.
#
# PROPRIETARY AND CONFIDENTIAL.
# This software, associated workflows, and configuration assets are the
# proprietary property of Xebia. Possession or use of this software is
# authorized strictly during an active professional services engagement with
# Xebia and subject to the terms of the governing engagement agreement.
#
# Unauthorized copying, reverse engineering, redistribution, or continued use
# after engagement termination is strictly prohibited.
#
# DISCLAIMER OF WARRANTY & LIMITATION OF LIABILITY:
# THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. IN NO EVENT SHALL
# XEBIA OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE OF OR INABILITY TO USE THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# USAGE IS ENTIRELY AT YOUR OWN RISK.
# -----------------------------------------------------------------------------
#
# Install the `amp` CLI locally from the private distribution repo.
#
# Downloads the Cython-compiled release wheel for your platform and pip-installs
# it. No readable source lands on your machine; when the engagement ends the
# read token is revoked (new installs stop) and the weekly-refreshed build
# expires (an already-installed copy stops within the expiry window).
#
# You still need gh + git + git-lfs and the gh migration extensions installed
# locally for migrations (see README); this script only installs the amp CLI.
#
# Requirements: gh CLI (authenticated, or a token), python3 with pip.
#
# Usage:
#   AMP_VERSION=0.1.0 scripts/install-amp.sh
#   AMP_VERSION=0.1.0 AMP_DIST_REPO=xebia/amp-dist AMP_DIST_TOKEN=ghp_xxx scripts/install-amp.sh
set -euo pipefail

AMP_VERSION="${AMP_VERSION:?set AMP_VERSION, e.g. AMP_VERSION=0.1.0}"
AMP_DIST_REPO="${AMP_DIST_REPO:-xebia/amp-dist}"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Install it: https://cli.github.com" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo ">> Downloading amp $AMP_VERSION wheels from $AMP_DIST_REPO"
# A release holds one wheel per platform/Python; download them all and let pip
# pick the match below. Use AMP_DIST_TOKEN if provided, else the gh auth session.
GH_TOKEN="${AMP_DIST_TOKEN:-${GH_TOKEN:-}}" gh release download "v${AMP_VERSION}" \
  --repo "$AMP_DIST_REPO" --pattern '*.whl' --dir "$tmp" --clobber

echo ">> Installing (pip selects the wheel matching this platform + Python)"
# --find-links + a pinned spec makes pip resolve the one compatible amp wheel
# from the downloaded set (not every platform's), while still pulling amp's
# dependencies from PyPI. (Do NOT add --no-index — that would block the deps.)
python3 -m pip install --upgrade --find-links "$tmp" "amp==${AMP_VERSION}"

echo ">> Installed:"
amp --help | head -n1
