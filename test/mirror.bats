#!/usr/bin/env bats

load test_helper
export NODE_BUILD_SKIP_MIRROR=
export NODE_BUILD_CACHE_PATH=
export NODE_BUILD_MIRROR_URL=http://mirror.example.com


@test "package URL without checksum bypasses mirror" {
  stub sha1 true
  stub curl "-*S* http://example.com/* : cat package-1.0.0.tar.gz"

  install_fixture definitions/without-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package URL with checksum but no SHA1 support bypasses mirror" {
  stub sha1 false
  stub curl "-*S* http://example.com/* : cat package-1.0.0.tar.gz"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package URL with checksum hits mirror first" {
  local checksum="83e6d7725e20166024a1eb74cde80677"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub sha1 true "echo $checksum"
  stub curl "-*I* $mirror_url : true" "-*S* $mirror_url : cat package-1.0.0.tar.gz"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package is fetched from original URL if mirror download fails" {
  local checksum="83e6d7725e20166024a1eb74cde80677"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"
  local original_url="http://example.com/packages/package-1.0.0.tar.gz"

  stub sha1 true "echo $checksum"
  stub curl "-*I* $mirror_url : false" "-*S* $original_url : cat package-1.0.0.tar.gz"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package is fetched from original URL if mirror download checksum is invalid" {
  local checksum="83e6d7725e20166024a1eb74cde80677"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"
  local original_url="http://example.com/packages/package-1.0.0.tar.gz"

  stub sha1 true "echo invalid" "echo $checksum"
  stub curl "-*I* $mirror_url : true" "-*S* $mirror_url : cat package-1.0.0.tar.gz" "-*S* $original_url : cat package-1.0.0.tar.gz"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}