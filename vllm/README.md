# vLLM Formula

Installs [vLLM](https://docs.vllm.ai/) — a high-throughput inference and serving
engine for LLMs, exposing an OpenAI-compatible API.

The formula supports three mutually exclusive delivery modes, selected by
`vllm.service.mode`. Exactly one mode is active at a time; switching modes tears
the previous one down on the next highstate.

## Modes

| Mode | How vLLM runs | Engine | GPU |
|------|---------------|--------|-----|
| `native` | `pip install vllm` on the host; you run `vllm serve` yourself | pip | via host CUDA (flavor `gpu`) |
| `docker` | `vllm/vllm-openai` image as a systemd-managed container serving the OpenAI API | Docker | `--gpus` (see prerequisites) |
| `kata`   | same image via `nerdctl` in a Kata Containers (Cloud Hypervisor) micro-VM | containerd + Kata | **CPU-only for now** |

The `native` mode preserves the historical behaviour, with `vllm.flavor`
(`gpu` / `cpu` / `tpu`) selecting the torch build. When `vllm.enabled` is true
but `vllm.service.enabled` is false, the formula falls back to the native pip
install.

## States

| State | Purpose |
|-------|---------|
| `init.sls` | Entry point — routes to the active mode and tears the others down |
| `install.sls` / `teardown.sls` | Native pip install / removal (keyed on `vllm.flavor`) |
| `docker/service.sls` / `docker/teardown.sls` | Docker-mode systemd service and cleanup |
| `kata/service.sls` / `kata/teardown.sls` | Kata-mode systemd service, CNI network, socket proxy, and cleanup |

## Dependencies

| Mode | Requires |
|------|----------|
| `docker` | `docker` formula; `nvidia.container-toolkit` + `docker.nvidia_runtime: true` when `vllm.docker.gpus` is set |
| `kata` | `kata-containers.kata-containers` and `containerd.nerdctl` |

Container modes require `vllm.<mode>.model` to be set to a HuggingFace model
repo; the state fails with a clear message otherwise.

## GPU prerequisites (docker mode)

1. **NVIDIA driver** — the host must already have a working NVIDIA kernel driver.
   Installing it is **out of scope** for this formula (host/kernel-specific).
2. **NVIDIA Container Toolkit** — enable `nvidia.container_toolkit` so containers
   can reach the GPU.
3. **Docker `nvidia` runtime** — set `docker.nvidia_runtime: true` so it is
   registered declaratively in `/etc/docker/daemon.json`.

> **userns-remap caveat:** the docker formula ships `"userns-remap": "default"`
> in `daemon.json`, which can conflict with GPU device injection in some
> docker + nvidia setups. If GPU containers fail to start under userns-remap,
> disabling it may be required (host-specific; not changed automatically).

## VFIO / GPU-in-Kata (future work)

Kata mode is CPU-only today. GPU passthrough into a Kata micro-VM needs VFIO
device passthrough and a GPU-enabled Kata configuration. As groundwork, the
`common` formula can load the VFIO modules via `common.vfio.enabled`, but:

- IOMMU must be enabled on the kernel cmdline (`intel_iommu=on` / `amd_iommu=on`).
- The target GPU must be bound to `vfio-pci`.

Those bootloader/host concerns are **out of scope**, and nothing in this formula
consumes VFIO yet.
