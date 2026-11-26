---
name: create-dev-branch
description: 다음 버전 개발 브랜치를 연다. `/create-dev-branch X.Y.Z` 로 `scripts/create-dev-branch.sh` 를 실행해 `prod`(지금 출시된 코드)에서 `develop/vX.Y.Z` 를 만들고, 버전 이름(MARKETING_VERSION)을 `X.Y.Z` 로 커밋해 push 한 뒤, 레포 default branch 를 그 브랜치로 바꾼다.
allowed-tools: Bash(scripts/create-dev-branch.sh *), Bash(scripts/version.sh *), Bash(git *), Bash(gh *), Read
---

# create-dev-branch

다음 출시 버전의 개발 통합 브랜치 `develop/vX.Y.Z` 를 연다. 로직은 전부 [`scripts/create-dev-branch.sh`](../../../scripts/create-dev-branch.sh) 에 있고, 이 스킬은 사용자에게 확인을 받아 그 스크립트를 실행한다. 흐름 전체는 [`docs/release.md`](../../../docs/release.md).

## 절차

1. 인자에서 버전 `X.Y.Z` 를 받는다 (`v` 접두사는 떼도 된다). 없거나 형식이 다르면 묻는다.
2. 미리 보여 준다 — 실행 전에 직접 조회해서 사용자에게 알린다:
   - `scripts/version.sh get origin/prod` (지금 출시된 버전) → `X.Y.Z`
   - `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` (지금 default branch)
   - 이전 개발 브랜치에만 있는 커밋 수: `git fetch -q origin && git rev-list --count --no-merges origin/prod..origin/<지금 default>` — 0 이 아니면 목록을 보여 주고 "새 브랜치에 안 들어간다, 가져가려면 `--source <그 브랜치>`" 라고 알린다
3. 사용자가 진행을 확인하면 `scripts/create-dev-branch.sh X.Y.Z --yes` (필요하면 `--source <브랜치>`) 를 실행한다. 확인 없이 `--yes` 를 넘기지 않는다.
4. 스크립트의 마지막 결과 (branch · 버전 이름 · default branch) 를 그대로 보고한다. `error:` 로 멈추면 그 메시지와 안내를 그대로 전한다 — 우회하지 않는다.
