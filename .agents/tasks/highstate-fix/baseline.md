# Highstate baseline (run 1)

Branch: `fix/highstate-issues` (from `origin/main` @ 1f12c5b)
Command: `sudo salt-call --local state.highstate --file-root=/srv/salt --pillar-root=/srv/pillar --retcode-passthrough -l info --state-output=changes`
Log: `/tmp/highstate-run-1.log` (exit code 2)

## Summary

- Succeeded: 281 (changed=75)
- Failed: 4
- Total states run: 285
- Run time: 212.553 s

## Failed states

### 1. `google-cloud-cli`
- SLS: `google/cloud/cli/install.sls`
- Function: `pkg.installed` (version `{{ gcloud.version }}-0`)
- Comment:
  ```
  Problem encountered installing package(s). Additional info follows:
  errors:
      - W: --force-yes is deprecated, use one of the options starting with --allow instead.
        E: Version '405.0.1-0' for 'google-cloud-cli' was not found
  ```
- Assessment: **repo-fixable**. `google/cloud/cli/defaults.yaml` pins `version: 405.0.1`, which is no longer in the Google apt repo. `apt-cache policy` shows installed 589.0.0-0, candidate 591.0.0-0 (590.0.1-0 also available). The renovate comment tracks `GoogleCloudPlatform/cloud-sdk-docker` github-tags, which appears to have stopped tracking / is stale. Fix: bump the version to an available one (e.g. 591.0.0) and possibly correct the renovate datasource.

### 2. `argocd-binary`
- SLS: `argo/cd/cli/install.sls`
- Function: `file.managed` (name `/usr/local/argocd/2.14.21/argocd`)
- Comment:
  ```
  Unable to manage file: Error: HTTP 404: Not Found reading /argoproj/argo-cd/releases/download/v2.14.21/argocd-2.14.21-checksums.txt
  ```
- Assessment: **repo-fixable**. Bad checksum asset name. The v2.14.21 release publishes `cli_checksums.txt` (HEAD returns 302 → exists). Fix: change `source_hash` to `.../v{{ version }}/cli_checksums.txt`.

### 3. `crossplane-binary`
- SLS: `crossplane/cli/install.sls`
- Function: `file.managed` (name `/usr/local/crossplane/2.4.2/crossplane`)
- Comment:
  ```
  Unable to manage file: Failed to cache https://releases.crossplane.io/stable/v2.4.2/bin/linux_amd64/crank: Error: HTTP 404: Not Found reading /stable/v2.4.2/bin/linux_amd64/crank
  ```
- Assessment: **repo-fixable**. In Crossplane v2 the CLI binary was renamed from `crank` to `crossplane`; `https://releases.crossplane.io/stable/v2.4.2/bin/linux_amd64/crossplane` returns HTTP 200. Fix: change asset name in `source`.

### 4. `crossplane-completion`
- SLS: `crossplane/cli/install.sls`
- Function: `cmd.run` (`/usr/local/bin/crossplane completions > /etc/bash_completion.d/crossplane`)
- Comment:
  ```
  Command "/usr/local/bin/crossplane completions > /etc/bash_completion.d/crossplane" run
  retcode: 127
  stderr: /bin/bash: line 1: /usr/local/bin/crossplane: No such file or directory
  ```
- Assessment: **repo-fixable (cascade)**. Fails only because `crossplane-binary` failed; the symlink was created to a missing target. It only `require`s the symlink, not the binary. Fixing #3 should resolve it; optionally also add `require: file: crossplane-binary` (and verify the v2 CLI still supports `completions`).

## Host-environmental failures

None observed.
