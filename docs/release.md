# 릴리즈 가이드

브랜치 · 버전 · 릴리즈 흐름. `scripts/version.sh` · `scripts/release-notes.sh` · `scripts/create-dev-branch.sh` ·
`.github/workflows/release-check.yml` · `release.yml` · 버전 파일 (`Configuration/Config.xcconfig`) 을 고치기 전에 읽는다.

스토어 · TestFlight 업로드는 하지 않는다. prod 머지로 **태그 · 버전 이름 · 빌드 번호 · 릴리즈 노트를 GitHub Release 에 남기는 것**까지가 자동이다.

## 한눈에 보기

```
feat/#12-login ──┐
fix/#15-crash ───┼─PR─▶ develop/vX.Y.Z ──승격 PR─▶ prod ──(자동)──▶ 태그 vX.Y.Z + GitHub Release "vX.Y.Z (빌드)"
setting/#20-ci ──┘        (default branch)
```

| 단계 | 트리거 | 하는 일 | 사람이 할 일 |
|---|---|---|---|
| 버전 시작 | Admin 이 `scripts/create-dev-branch.sh X.Y.Z` (Claude 에서는 `/create-dev-branch X.Y.Z`) | `prod` 에서 `develop/vX.Y.Z` 생성 · 버전 이름 `X.Y.Z` 커밋 · default branch 변경 | 새 base 브랜치 알리기 |
| 개발 | 작업 브랜치 → `develop/vX.Y.Z` PR | 머지되면 작업 브랜치 자동 삭제 | 리뷰 · 머지 |
| 릴리즈 노트 | `develop/vX.Y.Z` 에 일반 PR | — | `CHANGELOG.md` 에 `## [X.Y.Z] - 날짜` 섹션 쓰기 |
| 승격 PR | `develop/vX.Y.Z → prod` PR 열기 | Release Check 가 브랜치 이름 · 버전 · 태그 · 노트 확인 | Summary 의 노트 미리보기 확인 |
| 릴리즈 | 승격 PR 머지 (merge commit) | Release 가 태그 `vX.Y.Z` · GitHub Release `vX.Y.Z (빌드)` 생성 | Summary 확인 · 필요하면 prod 에서 아카이브 |

CI 는 **브랜치에 커밋하지 않는다.** 버전 이름은 브랜치를 만들 때 `scripts/create-dev-branch.sh` 가 커밋하고, 빌드 번호는 저장하지 않고 계산한다.

## 브랜치

| 브랜치 | 역할 | PR 대상 |
|---|---|---|
| `<type>/#<이슈번호>-<slug>` | 작업 브랜치. 이슈 하나 = 브랜치 하나. type: `feat` `fix` `refactor` `setting` `chore` `docs` `test` … | 현재 `develop/vX.Y.Z` |
| `develop/vX.Y.Z` | 다음 출시 버전의 개발 통합. 레포 **default branch** — PR 의 기본 base | `prod` |
| `prod` | 출시된 코드. 머지될 때마다 릴리즈가 만들어진다 | — |

- 새 `develop/vX.Y.Z` 는 `prod` 에서 갈라진다. 이전 개발 브랜치에 출시 뒤 머지된 커밋은 새 브랜치에 안 들어간다 —
  스크립트가 개수 · 목록을 보여 주고 진행할지 묻는다. 가져가려면 `--source <이전 개발 브랜치>`.
- 다 쓴 개발 브랜치는 승격이 끝나면 지운다.
- 버전 규칙 (SemVer): major — 호환 안 되는 큰 변화 · minor — 새 기능 · patch — 버그 수정만.

### 급한 수정 (hotfix)

`prod` 로는 `develop/vX.Y.Z` 만 PR 할 수 있으므로 같은 흐름을 따른다.

1. `scripts/create-dev-branch.sh X.Y.(Z+1)` — `prod` 에서 갈라진다 (default branch 도 옮겨진다)
2. `fix/#N-...` → `develop/vX.Y.(Z+1)` PR · 머지, CHANGELOG 섹션 추가
3. `develop/vX.Y.(Z+1) → prod` 승격 → 자동 릴리즈
4. 진행 중이던 다음 버전 개발 브랜치에 `prod` 를 머지해 수정을 반영하고, default branch 를 그 브랜치로 되돌린다 (`gh repo edit --default-branch develop/vA.B.C`)

## 버전

| 값 | 어디에 | 누가 정하나 |
|---|---|---|
| 버전 이름 `X.Y.Z` (`CFBundleShortVersionString`) | `Configuration/Config.xcconfig` 의 `MARKETING_VERSION` | `develop/vX.Y.Z` 를 만들 때 `scripts/create-dev-branch.sh`. 손으로 바꾸면 승격 PR 의 Release Check 가 브랜치 이름과 비교해 막는다 |
| 빌드 번호 (`CFBundleVersion`) | 저장하지 않는다 — `scripts/version.sh build-number origin/prod` | `prod` 의 first-parent 커밋 수. 승격 PR 의 merge commit 마다 1 씩 늘어 출시마다 + 1 이 된다. Release 제목 `vX.Y.Z (빌드)` 에 남는다 |
| 로컬 빌드 번호 | `CURRENT_PROJECT_VERSION` | 고정. 올리지 않는다 |

- 릴리즈마다 올리는 버전 bump PR 은 없다.
- 출시 빌드를 직접 아카이브할 때는 prod 머지 뒤 `prod` 에서, 빌드 번호를 넘겨 Release 와 맞춘다:
  ```bash
  git fetch origin && git switch prod && git pull
  xcodebuild archive -scheme <Scheme> -archivePath build/App.xcarchive \
    CURRENT_PROJECT_VERSION="$(scripts/version.sh build-number HEAD)"
  ```
- `prod` 에 squash · rebase 머지나 직접 push 가 들어가면 빌드 번호 규칙이 깨진다 — ruleset 이 merge commit 만 허용한다.

## 릴리즈 노트

승격 PR 을 열기 전에 개발 브랜치에서 `CHANGELOG.md` 맨 위 (설명 아래) 에 섹션을 일반 PR 로 넣는다.

```markdown
## [1.2.0] - 2026-12-01

### 신규 기능
- 위젯에서 오늘 일정을 바로 볼 수 있어요.

### 개선
- 앱을 켤 때 더 빨리 넘어가요.

### 버그 수정
- 알림을 눌러도 화면이 열리지 않던 문제 해결.
```

- 머리는 정확히 `## [X.Y.Z]` 로 시작한다. 다음 `## [` 제목 전까지가 노트다. 목록 항목 (`- `) 이 하나 이상 있어야 한다.
- 개발 용어 대신 사용자가 체감하는 변화를 `~해요` 체로 쓴다.
- GitHub Release 본문 = `> 버전 X.Y.Z · 빌드 N` + 이 섹션 + `## 개발자 노트` (직전 릴리즈 이후 머지된 PR, 라벨별 분류 — `.github/release.yml`).
  PR 에 라벨 (`💻 Feat` · `🛠️ Fix` · `🔥 Bug` · `🪄 Refactor` · `⚙️ Setting`) 을 붙여야 분류된다. 승격 PR 자신은 빠진다.
- 확인: `scripts/release-notes.sh X.Y.Z` 가 CI 와 같은 규칙으로 섹션을 출력한다.

## CI

| 워크플로 | 트리거 | 하는 일 |
|---|---|---|
| `release-check.yml` · `Release Check` | `prod` 대상 PR | head 가 `develop/vX.Y.Z` · 버전 이름 = X.Y.Z · `vX.Y.Z` 태그 없음 · CHANGELOG 섹션 있음. prod 의 required check |
| `release.yml` · `Release` | `prod` push | 태그 `vX.Y.Z` · GitHub Release `vX.Y.Z (빌드)` 생성. 태그가 이미 있으면 건너뛴다 — 실패하면 Re-run 해도 된다 |
| `delete-merged-branch.yml` | `develop/**` 로 머지된 PR | 작업 브랜치 삭제 (장기 브랜치 · 다른 열린 PR 이 쓰는 브랜치는 남긴다) |

secret 은 필요 없다 (`GITHUB_TOKEN` 만 쓴다).

## 저장소 설정 (관리자)

| 대상 | 규칙 |
|---|---|
| ruleset 「prod 보호」 (`prod`) | PR 로만 · merge commit 만 · `Release Check` 통과 필수 · 삭제 · force push 금지. bypass 없음 |
| ruleset 「develop 보호」 (`develop/**`) | PR 로만 · force push 금지. Admin bypass (`create-dev-branch.sh` 의 버전 커밋 push). 삭제는 막지 않는다 |
| 「Automatically delete head branches」 | 끈다 — `delete-merged-branch.yml` 이 대신한다 |
| 「Allow merge commits」 | 켠다 — 승격 PR 은 merge commit 으로만 머지한다 |
