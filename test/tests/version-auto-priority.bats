#!/usr/bin/env bats

load shared-functions
load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'


# auto

function setup() {
  unset_nvh_env
  tmpdir="${TMPDIR:-/tmp}"
  export MY_DIR="${tmpdir}/nvh/test/version-resolve-auto-priority"
  mkdir -p "${MY_DIR}"
  rm -f "${MY_DIR}/package.json"
  rm -f "${MY_DIR}/.nvh-node-version"
  rm -f "${MY_DIR}/.node-version"
  rm -f "${MY_DIR}/.nvmrc"

  # Need a version of node available for reading package.json
  export NVH_PREFIX="${MY_DIR}"
  export PATH="${MY_DIR}/bin:${PATH}"
  if [[ "${BATS_TEST_NUMBER}" -eq 1 ]] ; then
    # beforeAll
    nvh install lts
  fi
}

function teardown() {
  # afterAll
  if [[ "${#BATS_TEST_NAMES[@]}" -eq "${BATS_TEST_NUMBER}" ]] ; then
    rm -rf "${MY_DIR}"
  fi
}

@test ".nvh-node-version first" {
  cd "${MY_DIR}"
  echo "401.0.1" > .nvh-node-version
  echo "401.0.2" > .node-version
  echo "401.0.3" > .nvmrc
  echo '{ "engines" : { "node" : "v401.0.4" } }' > package.json

  run nvh NVH_TEST_DISPLAY_LATEST_RESOLVED_VERSION auto
  assert_line "v401.0.1"
}

@test ".node-version second" {
  cd "${MY_DIR}"
  echo "401.0.2" > .node-version
  echo "401.0.3" > .nvmrc
  echo '{ "engines" : { "node" : "v401.0.4" } }' > package.json

  run nvh NVH_TEST_DISPLAY_LATEST_RESOLVED_VERSION auto
  assert_line "v401.0.2"
}

@test ".nvmrc third" {
  cd "${MY_DIR}"
  echo "401.0.3" > .nvmrc
  echo '{ "engines" : { "node" : "v401.0.4" } }' > package.json

  run nvh NVH_TEST_DISPLAY_LATEST_RESOLVED_VERSION auto
  assert_line "v401.0.3"
}

@test ".package.json last" {
  cd "${MY_DIR}"
  echo '{ "engines" : { "node" : "v401.0.4" } }' > package.json

  run nvh NVH_TEST_DISPLAY_LATEST_RESOLVED_VERSION auto
  assert_line "v401.0.4"
}

