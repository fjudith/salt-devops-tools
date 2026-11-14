# Fix the four failing highstate states (gcloud, argocd, crossplane)

The branch fixes all four failures from the baseline highstate. The fixes are a stale `google-cloud-cli` apt pin, a wrong ArgoCD checksum asset name, and a Crossplane CLI download that moved hosts and repos in v2.3+, which also caused the `crossplane-completion` failure. Each fix targets the root cause in `defaults.yaml` or `install.sls`. The renovate annotations now point at sources that are still maintained, so the same versions should not go stale again. No tools were disabled, no states were removed, and there are no stubs or pillar workarounds. The fix report shows a clean re-run (285 succeeded, 0 failed) and an idempotency run. I checked both counts against `/tmp/highstate-run-{2,3}.log`.

Watch for: crossplane is still downloaded with `skip_verify: true`, behind an `unless: ls <dir>` guard. Both predate this branch and are not blocking.

**Verdict**: APPROVED

## High-level view

The gcloud pin moves from 405.0.1 to 591.0.0, which matches the apt candidate. Renovate now tracks `gcr.io/google.com/cloudsdktool/google-cloud-cli` with docker versioning, replacing the `cloud-sdk-docker` github-tags source that stopped at 427.0.0. This fixes why the pin went stale in the first place. Docker versioning should also keep renovate off suffixed tags such as `-alpine` (likely).

ArgoCD's `source_hash` now points at `cli_checksums.txt`, the asset the release actually publishes. The coder confirmed it lists the `argocd-linux-*` entries.

For Crossplane, the CLI is now downloaded from `cli.crossplane.io`, and renovate tracks `crossplane/cli` instead of `crossplane/crossplane`. The version moves to 2.5.0 because the CLI repo has no v2.4.2 release. The report also notes that the binary at `releases.crossplane.io/.../crossplane` is the controller, not the CLI. Swapping only the asset name, as the baseline suggested, would have installed the wrong binary. The coder caught this and removed the wrong binary from the host. The completion state now requires `crossplane-binary`, so a failed download no longer surfaces as a misleading exit code 127.

The rest of the branch:

- A typo fix in `pillar.sls.example` (`fasle` changed to `false`).
- EOF-newline commits from the pre-commit hooks.

All commit messages are conventional commits. `.agents/` is untracked and not committed.

<details>
<summary>Issues (0)</summary>

No blocking issues. Not blocking and outside this diff:

- The crossplane download still uses `skip_verify: true` and the `unless: ls <dir>` guard.
- The run 3 changes listed in the report come from unguarded `cmd.run` states (completions, repo keys). They also appeared in run 1.

</details>

<details>
<summary>File map</summary>

- `google/cloud/cli/defaults.yaml`: version 591.0.0, renovate source switched to the gcr docker registry
- `argo/cd/cli/install.sls`: `source_hash` changed to `cli_checksums.txt`
- `crossplane/cli/defaults.yaml`: version 2.5.0, renovate `depName=crossplane/cli`
- `crossplane/cli/install.sls`: CLI source changed to `cli.crossplane.io`, completion now requires the binary
- `pillar.sls.example`: hubble `enabled` typo fixed

Full diff: `git -C /srv/salt diff origin/main...HEAD`

</details>
