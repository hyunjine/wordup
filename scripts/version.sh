#!/usr/bin/env bash
# 앱 버전 이름 (MARKETING_VERSION) · 빌드 번호를 읽고 쓴다. 버전 파일의 위치 · 형식은 이 스크립트만 안다 —
# 다른 스크립트 · 워크플로는 이 스크립트를 부른다. 자세한 흐름은 docs/release.md.
#
#   scripts/version.sh get [<ref>]       버전 이름 X.Y.Z 를 출력 (ref 를 주면 그 커밋의 파일에서 읽는다)
#   scripts/version.sh set X.Y.Z         파일 안의 MARKETING_VERSION 을 모두 X.Y.Z 로 바꾼다 (커밋하지 않는다)
#   scripts/version.sh build-number [<ref>]
#                                        빌드 번호 = ref (기본 HEAD) 의 first-parent 커밋 수.
#                                        prod 는 승격 PR 의 merge commit 으로만 늘어나므로 출시마다 정확히 1 씩 커진다.
#
# 읽는 형식 (한 파일 안의 모든 MARKETING_VERSION 이 같은 값이어야 한다):
#   xcconfig  MARKETING_VERSION = 1.2.3
#   pbxproj   MARKETING_VERSION = 1.2.3;
#   XcodeGen  MARKETING_VERSION: "1.2.3"
#   Tuist     "MARKETING_VERSION": "1.2.3"
set -euo pipefail

VERSION_FILE="Configuration/Config.xcconfig"

KEY_RE='MARKETING_VERSION"?[[:space:]]*[=:][[:space:]]*"?'
NUM_RE='[0-9]+(\.[0-9]+)*'

die() { echo "error: $*" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel)"

# stdin 의 MARKETING_VERSION 값들을 중복 없이 출력한다.
values() { { grep -oE "${KEY_RE}${NUM_RE}" || true; } | grep -oE "${NUM_RE}\$" | sort -u; }

case "${1:-}" in
  get)
    if [ -n "${2:-}" ]; then
      SRC=$(git show "$2:$VERSION_FILE" 2> /dev/null) || die "$2 에 $VERSION_FILE 가 없다"
    else
      [ -f "$VERSION_FILE" ] || die "$VERSION_FILE 가 없다"
      SRC=$(cat "$VERSION_FILE")
    fi
    V=$(printf '%s\n' "$SRC" | values)
    [ -n "$V" ] || die "$VERSION_FILE 에 MARKETING_VERSION 이 없다"
    [ "$(printf '%s\n' "$V" | wc -l | tr -d ' ')" = 1 ] ||
      die "$VERSION_FILE 의 MARKETING_VERSION 이 여러 값이다: $(tr "\n" " " <<< "$V") — 하나로 맞춘다"
    echo "$V"
    ;;
  set)
    NEW="${2:-}"
    NEW="${NEW#v}"
    [[ "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "버전은 X.Y.Z 형식이어야 한다 (받은 값: '$NEW')"
    [ -f "$VERSION_FILE" ] || die "$VERSION_FILE 가 없다"
    [ -n "$(values < "$VERSION_FILE")" ] || die "$VERSION_FILE 에 MARKETING_VERSION 이 없다"
    tmp=$(mktemp)
    sed -E "s/(${KEY_RE})${NUM_RE}/\\1${NEW}/g" "$VERSION_FILE" > "$tmp"
    cat "$tmp" > "$VERSION_FILE"   # 권한 · 링크를 그대로 두려고 mv 대신 덮어쓴다
    rm -f "$tmp"
    [ "$(values < "$VERSION_FILE")" = "$NEW" ] || die "$VERSION_FILE 를 $NEW 로 바꾸지 못했다 — git diff 로 확인한다"
    ;;
  build-number)
    git rev-list --first-parent --count "${2:-HEAD}"
    ;;
  *)
    sed -n '2,18p' "$0"
    exit 1
    ;;
esac
