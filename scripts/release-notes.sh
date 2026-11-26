#!/usr/bin/env bash
# CHANGELOG.md 의 `## [X.Y.Z]` 섹션 본문 (다음 `## [` 제목 전까지, 앞뒤 빈 줄 제외) 을 출력한다.
# 섹션이 없거나 목록 항목 (`- ...`) 이 하나도 없으면 실패한다.
#
#   scripts/release-notes.sh X.Y.Z
#
# Release Check (승격 PR 검사) 와 Release (GitHub Release 생성) 가 같은 규칙으로 읽도록 둘 다 이 스크립트를 쓴다.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

V="${1:-}"
V="${V#v}"
[[ "$V" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "버전은 X.Y.Z 형식이어야 한다 (받은 값: '$V')"

cd "$(git rev-parse --show-toplevel)"
[ -f CHANGELOG.md ] || die "CHANGELOG.md 가 없다"

# `## [X.Y.Z]` 로 시작하는 줄만 머리로 본다 — `## [X.Y.Z · 메모]` 나 `## [X.Y.Z0]` 는 아니다.
NOTES=$(tr -d '\r' < CHANGELOG.md | awk -v h="## [$V]" '
  index($0, h) == 1 { f = 1; next }
  f && /^## \[/     { exit }
  f {
    if (NF) { printf "%s", buf; buf = ""; print; seen = 1 }
    else if (seen) { buf = buf $0 "\n" }
  }
')

[ -n "$NOTES" ] || die "CHANGELOG.md 에 '## [$V] - YYYY-MM-DD' 섹션이 없거나 비었다"
printf '%s\n' "$NOTES" | grep -qE '^[[:space:]]*[-*] ' ||
  die "CHANGELOG.md 의 [$V] 섹션에 목록 항목 (- ...) 이 하나도 없다"
printf '%s\n' "$NOTES"
