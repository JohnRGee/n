#!/usr/bin/env bash

# Index reference:
# https://github.com/nodejs/nodejs-dist-indexer
# An application to create nodejs.org distribution index files: index.json and index.tab

readonly TMP_VERSIONS_DIR="$(mktemp -d)"
# Using insecure so can optionally make use of local caching proxy server
readonly CURL_OPTIONS=( "--silent" "--insecure" )

# First two lines look like:
# version	date	files	npm	v8	uv	zlib	openssl	modules	lts
# v10.9.0	2018-08-15	aix-ppc64,headers,linux-arm64,linux-armv6l,linux-armv7l,linux-ppc64le,linux-s390x,linux-x64,osx-x64-pkg,osx-x64-tar,src,sunos-x64,win-x64-7z,win-x64-exe,win-x64-msi,win-x64-zip,win-x86-7z,win-x86-exe,win-x86-msi,win-x86-zip	6.2.0	6.8.275.24	1.22.0	1.2.11	1.1.0i	64	-
echo "Getting index..."
curl "${CURL_OPTIONS[@]}" https://nodejs.org/dist/index.tab -o "${TMP_VERSIONS_DIR}/index.tab"

# Skip the header line, and reduce to just <version> and <lts>
# version	date	files	npm	v8	uv	zlib	openssl	modules	lts
cut -f 1 -f 10 < "${TMP_VERSIONS_DIR}/index.tab" | tail -n +2 > "${TMP_VERSIONS_DIR}/versions.tab"

# Collapse to single entries for each codename, make subsequent lookups easy.
sort --field-separator=$'\t' --unique -k2 < "${TMP_VERSIONS_DIR}/versions.tab" > "${TMP_VERSIONS_DIR}/lts.tab"
# v10.9.0	-
# v4.9.1	Argon
# v6.14.4	Boron
# v8.11.4	Carbon

readonly LATEST_VERSION=$(head -n 1 < "${TMP_VERSIONS_DIR}/lts.tab" | cut -f 1)
readonly LTS_VERSION=$(tail -n 1 < "${TMP_VERSIONS_DIR}/lts.tab" | cut -f 1)
# Could generalise for codenames, but a few will do.
readonly ARGON_VERSION=$(grep Argon < "${TMP_VERSIONS_DIR}/lts.tab" | cut -f 1)
readonly BORON_VERSION=$(grep Boron < "${TMP_VERSIONS_DIR}/lts.tab" | cut -f 1)
readonly CARBON_VERSION=$(grep Carbon < "${TMP_VERSIONS_DIR}/lts.tab" | cut -f 1)

echo "Getting nightly index..."
curl "${CURL_OPTIONS[@]}" https://nodejs.org/download/nightly/index.tab -o "${TMP_VERSIONS_DIR}/nightly.tab"
readonly NIGHTLY_LATEST_VERSION="$(tail -n +2 < "${TMP_VERSIONS_DIR}/nightly.tab" | head -n 1 | cut -f 1)"

readonly OUTFILE="export_test_versions.bash"
cat << EOF > "${OUTFILE}"
export LATEST_VERSION="${LATEST_VERSION}"
export LTS_VERSION="${LTS_VERSION}"
export ARGON_VERSION="${ARGON_VERSION}"
export BORON_VERSION="${BORON_VERSION}"
export CARBON_VERSION="${CARBON_VERSION}"
export NIGHTLY_LATEST_VERSION="${NIGHTLY_LATEST_VERSION}"
EOF

echo ""
cat "${OUTFILE}"

rm -rf "${TMP_VERSIONS_DIR}"