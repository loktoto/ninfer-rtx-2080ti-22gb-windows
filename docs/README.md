# Documentation

Start with the [project README](../README.md) for the RTX 2080 Ti 22GB target, branch map, build commands and current limitations. This fork is developed and maintained by [loktoto](https://github.com/loktoto), building on [NInfer by Neroued](https://github.com/Neroued/ninfer).

## SM75 and native Windows

| Reference | Use it for |
|---|---|
| [Project status](PROJECT-STATUS.md) | Development map and release acceptance requirements |
| [Recorded Windows GPU tests](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/docs/WINDOWS-SM75-LOCAL-VALIDATION.md) | October 12–13 installation/Base passes, failed retrieval/tool/MTP gates and follow-up numerical investigation |
| [Windows installation](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/docs/INSTALL-WINDOWS-SM75.md) | Installer, launchers, local API and repair on the native branch |
| [Windows build and acceptance](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/docs/windows-sm75.md) | Pinned developer toolchain, packaging and physical GPU qualification |
| [SM75 RK4V4E8 profile](sm75-rk4v4-e8-qwen3_8_27b.md) | Opt-in compressed KV implementation and source-baseline tuning tools |
| [SM75 physical validation](sm75-2080ti-validation-runbook.md) | Capacity, performance and long-context quality checks |

The native Windows files live on `windows-native-sm75`; `master` carries the SM75 source baseline. The recorded Windows package did not pass production acceptance. Read the test report before interpreting a feature, context size or benchmark as qualified.

## User guides

| Document | Purpose |
|---|---|
| [CLI](cli.md) | text, chat-history, image/video input, output streams, sampling, MTP, and common runtime options |
| [HTTP serving](serving.md) | OpenAI Responses/Chat Completions, Anthropic Messages, state, streaming, token counting, authentication, and tool calls |
| [Performance](performance.md) | Upstream RTX 5090 single-request and concurrent-decode results, MTP/DFlash measurements, and reproduction commands |
| [CLI examples](../examples/cli/) | committed text, multimodal, thinking, long-decode, and long-context inputs |

The executable `--help` output is the exact source for command-line option spelling and defaults.

## Model artifacts

These are inherited NInfer artifact references. Availability here does not establish SM75 or Windows compatibility. The native Windows channel uses its own [pinned container-v2 artifact lock](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/config/windows-sm75-artifacts.json); do not substitute a newer download from the table.

| Model | Weights | Download | Versioned model card source |
|---|---|---|---|
| Qwen3.6-27B | `groupwise-int` | [Hugging Face](https://huggingface.co/neroued/Qwen3.6-27B-NInfer) | [model card](../model-cards/Qwen3.6-27B-NInfer/README.md) |
| Qwen3.6-27B | `nvfp4` | [Hugging Face](https://huggingface.co/neroued/Qwen3.6-27B-nvfp4-NInfer) | [model card](../model-cards/Qwen3.6-27B-nvfp4-NInfer/README.md) |
| Qwen3.8-27B | `groupwise-int` | [Hugging Face](https://huggingface.co/neroued/Qwen3.8-27B-NInfer) | [model card](../model-cards/Qwen3.8-27B-NInfer/README.md) |
| Qwen3.8-27B | `nvfp4` | [Hugging Face](https://huggingface.co/neroued/Qwen3.8-27B-nvfp4-NInfer) | [model card](../model-cards/Qwen3.8-27B-nvfp4-NInfer/README.md) |
| Qwen3.6-35B-A3B | `groupwise-int` | [Hugging Face](https://huggingface.co/neroued/Qwen3.6-35B-A3B-NInfer) | [model card](../model-cards/Qwen3.6-35B-A3B-NInfer/README.md) |

## Repository-local guides

- [Benchmarks](../bench/README.md)
- [Tests](../tests/README.md)
- [Maintainer tools](../tools/README.md)
- [Capability evaluation](../eval/README.md)

## Maintainer references

The active references under [`maintainer/`](maintainer/) record current architecture, model,
artifact, and maintenance contracts. These files are not additional user workflows or installed
API documentation.

Runtime and Op references:

- [Small-scale concurrent inference architecture](maintainer/concurrent-inference-architecture.md)
- [Paged KV context storage, ownership, and capacity model](maintainer/paged-kv-cache.md)
- [Op admission, contracts, ownership, qualification, and performance rules](maintainer/op-development.md)
- [ReplaySSM GDN technical reference](maintainer/replayssm-gdn.md)
- [Linear benchmark contract and registered suites](maintainer/linear-benchmark.md)

Artifact and model references:

- [NInfer artifact container](maintainer/artifact-container.md)
- [Persistent tensor numeric formats](maintainer/tensor-formats.md)
- [Persistent storage layouts](maintainer/storage-layouts.md)
- [Qwen3.6-27B model semantics](maintainer/qwen3.6-27b-model.md)
- [Qwen3.6-27B artifact contracts, including NVFP4](maintainer/qwen3.6-27b-artifact.md)
- [Qwen3.8-27B artifact contracts, including the NVFP4 target](maintainer/qwen3.8-27b-artifact.md)
- [Qwen3.6-35B-A3B model semantics](maintainer/qwen3.6-35b-a3b-model.md)
- [Qwen3.6-35B-A3B artifact contracts](maintainer/qwen3.6-35b-a3b-artifact.md)

Pending implementation work:

- [Softmax Attention organization and migration](maintainer/softmax-attention.md) describes the
  single target state for an unfinished source and public-contract cutover; it is not the current
  implementation map.
