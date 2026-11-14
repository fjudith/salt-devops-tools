# Highstate fix report (iteration 1)

Branch: `fix/highstate-issues`. `review.json` was not present, so this pass fixed the baseline failures from run 1.

## Fixes

| # | State ID | Root cause | Fix | Commit |
|---|----------|------------|-----|--------|
| 1 | `google-cloud-cli` (`google/cloud/cli/install.sls`) | `defaults.yaml` pinned `405.0.1`, which the Google apt repo no longer has. The renovate source `GoogleCloudPlatform/cloud-sdk-docker` github-tags stopped at 427.0.0, so the version was never bumped. | Set `version: 591.0.0` (`apt-cache policy` candidate is 591.0.0-0). Moved renovate to `datasource=docker depName=gcr.io/google.com/cloudsdktool/google-cloud-cli versioning=docker`; that registry publishes plain tags `591.0.0`, `590.0.1`, and so on. | `cf4ed67`, plus `a20d046` (EOF newline from the pre-commit hook) |
| 2 | `argocd-binary` (`argo/cd/cli/install.sls`) | `source_hash` pointed at `argocd-<ver>-checksums.txt`, which returns 404. The release publishes `cli_checksums.txt` (HTTP 200, and it lists `argocd-linux-amd64`/`arm64`). | `source_hash` now uses `.../v{{ version }}/cli_checksums.txt`. | `09d68ff` |
| 3 | `crossplane-binary` (`crossplane/cli/install.sls`) | Since v2.3.0 the CLI is released from `crossplane/cli` to `cli.crossplane.io` under the binary name `crossplane`. The old `releases.crossplane.io/.../crank` path 404s for 2.4.2. Also, `releases.crossplane.io/.../crossplane` is the controller binary, not the CLI. No CLI release v2.4.2 exists: the `crossplane/cli` releases are v2.5.0, v2.4.1, v2.3.4. | `source` is now `https://cli.crossplane.io/stable/v{{ version }}/bin/linux_<arch>/crossplane`. `defaults.yaml` is set to `version: 2.5.0` with renovate `depName=crossplane/cli`. Checked HTTP 200 for amd64 and arm64. `crossplane version --client` prints `v2.5.0`. | `a7d6e65`, plus `4cae60f` (EOF newline) |
| 4 | `crossplane-completion` | A knock-on failure from #3: the symlink pointed at a missing binary, and the state only required the symlink. | Fixed by #3. Also added `require: file: crossplane-binary`. The CLI's `completions` subcommand works (`complete -C /usr/local/crossplane/2.5.0/crossplane crossplane`). | `a7d6e65` |
| - | `pillar.sls.example` typo | `hubble: enabled: fasle` | Changed to `enabled: false`. | `8bdf446` |

Host cleanup: while testing, an earlier attempt downloaded the controller binary into `/usr/local/crossplane/2.4.2`. I removed that directory. The `unless: ls <dir>` guard would otherwise have hidden a wrong binary at that version (it no longer matters, since the version is now 2.5.0).

## Highstate counts

| Run | Log | Succeeded | Failed | Changed | Exit |
|-----|-----|-----------|--------|---------|------|
| 1 (baseline) | `/tmp/highstate-run-1.log` | 281 | 4 | 75 | 2 |
| 2 (after fixes) | `/tmp/highstate-run-2.log` | 285 | 0 | 30 | 0 |
| 3 (idempotency) | `/tmp/highstate-run-3.log` | 285 | 0 | 30 | 0 |

## Idempotency

In run 3, `google-cloud-cli`, `argocd-binary`, `argocd`, `crossplane-binary` and `crossplane` report no changes. The 30 changes left are unguarded `cmd.run` states that run on every highstate: `*-completion`, `*-repo` key fetches, `kirocli-*`, `go`, `mssql`, `kata-containers-kvm-check`. Every one of these IDs also reported changes in run 1, so none are new. That includes `crossplane-completion`, which follows the same unguarded pattern as the other completion states. They are outside the scope of this fix.

## Environmental failures

None.

## Pillar issues

None found in `/srv/pillar` for the failing states. The only typo was in `pillar.sls.example` (fixed above).

## Commands run

- `curl -fsSLI -o /dev/null -w '%{http_code}'`:
  - argo-cd v2.14.21 `cli_checksums.txt`: 200
  - `argocd-linux-amd64`: 200
  - `cli.crossplane.io/stable/v2.5.0` and `v2.4.1` `bin/linux_{amd64,arm64}/crossplane`: 200
  - `releases.crossplane.io/stable/v2.4.2/bin/linux_amd64/crank`: 404
  - `cli.crossplane.io/stable/v2.4.2/...`: 404
- GitHub API:
  - `crossplane/cli` releases: v2.5.0 (not a prerelease), v2.4.1, v2.3.4
  - `cloud-sdk-docker` tags: latest 427.0.0
- `gcr.io/v2/google.com/cloudsdktool/google-cloud-cli/tags/list`: has 591.0.0 and 590.0.1
- `apt-cache policy google-cloud-cli`: installed 589.0.0-0, candidate 591.0.0-0
- `state.show_sls` and `state.apply --retcode-passthrough` for each state:
  - `google.cloud.cli`: 3 succeeded, 0 failed; package upgraded to 591.0.0-0
  - `argo.cd.cli`: 2 succeeded, 0 failed
  - `crossplane.cli`: 3 succeeded, 0 failed (after the second fix)
- Full highstate runs 2 and 3: see the table above
- pre-commit hooks from `.pre-commit-config.yaml`, run through a temporary venv because they are not installed in `.git/hooks`:
  - trailing-whitespace, check-yaml, large-files: pass
  - end-of-file-fixer: fixed two files, committed separately
  - conventional-pre-commit: passes for all 6 commit messages
