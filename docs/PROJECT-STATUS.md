# Project status · NInfer SM75 by loktoto

> Repository evidence reviewed **2026-10-26**. The latest tracked native Windows
> physical-card report covers **2026-10-12/13 (Asia/Hong_Kong)**. This is a source
> and evidence snapshot, not a live GitHub Actions or release inventory.

Native Windows installation and short Base-mode inference passed on one RTX 2080
Ti 22GB. **Production qualification failed**: the tested 8K semantic retrieval,
required tool call and greedy MTP0/MTP3 parity did not pass. A subsequent SM75 MMA
fragment correction passed four standalone matrix-oracle cases, but the tracked
report leaves the replacement runtime, full GQA regression and model acceptance
pending. No qualified Windows performance or long-context ceiling follows from it.

## Product and repository

- Maintainer: [loktoto](https://github.com/loktoto); Apache-2.0 lineage:
  [NInfer by Neroued](https://github.com/Neroued/ninfer).
- Current repository: [ninfer-rtx-2080ti-22gb-windows](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows).
- Intended target: Windows 10/11 x64, modified RTX 2080 Ti with **22GB VRAM**,
  compute capability **7.5**, locally served Qwen3.8-27B `groupwise-int` using the
  pinned **v2** artifact. Stock 11GB cards are outside this Windows package target.
- Intended delivery: verified ZIP, installer and loopback API, followed by
  independently qualified MTP, Vision and optional compressed KV.

The imported `master` history and `windows-native-sm75` history have different
contents. Native build/install tooling, the local validation report and the MMA
correction are recorded on the latter; a report about its earlier package does
not qualify either current branch. Use the Windows build instructions belonging
to the source being built.

## What was actually tested

The [tracked Windows report](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/d9a76506546d77d71ed5d7b72dd0ee4b1148b08a/docs/WINDOWS-SM75-LOCAL-VALIDATION.md)
is the historical source for these results. The test machine ran Windows 11 Pro
10.0.26200, RTX 2080 Ti **22,528 MiB**, driver **616.56**, CUDA compiler **13.1.80**,
MSVC toolset **14.44.35207**, and an INT8-KV Base server at context 8192,
concurrency one.

| Evidence | Recorded outcome |
| --- | --- |
| Native build, packaging, extracted dependency audit, clean installation | Passed for the historical package |
| Physical W8 LinearPair conformance and artifact-free frontend checks | Passed |
| Installed API smoke, arithmetic, SSE and authentication checks | Passed; short inference only |
| 8K-capacity short CLI smoke | Passed with exact `SM75 OK`; does not demonstrate 8K retrieval |
| Retrieval at 7,936 input tokens | Failed; 32-token output limit reached without the needle |
| Required tool call | Failed on INT8 KV |
| Greedy MTP0/MTP3 parity | Failed; first divergent token at position 11 |
| Follow-up INT8 GQA regression | 33 cases failed; no BF16 case failed |
| BF16 diagnostic controls | Original deterministic MTP parity and fresh-server tool request passed; 7,936-token retrieval timed out |
| Corrected SM75 FP16/INT8 MMA | Four standalone dense-oracle cases passed on the physical card; full corrected GQA/model acceptance remained pending |

The tested source was `94c0484de2e41dc3683ee60234c49e66dc08476d`:

```text
package  ninfer-windows-sm75-94c0484de2e4.zip
sha256   95384bf59708a405bc8dc33731ccfe65e39eb6233f6680ec5e9a86322c25790b
model    qwen3_8_27b.ninfer, 18,210,531,328 bytes
sha256   eec39564993d6e9c7d5e383382a760f093465c9d163ec9a1bd6b80199514bf3e
```

These identifiers distinguish the observed package from later fixes. The
[correction commit](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/commit/d9a76506546d77d71ed5d7b72dd0ee4b1148b08a)
repairs swapped middle A fragments in the SM75 FP16 and signed INT8 MMA
decompositions and adds standalone MMA/GQA gates. It does not record a passing
replacement package. Disabling CUDA Graph did not remove the original INT8
parity failure; similar-looking generated text is insufficient evidence of parity.

## Next concrete work

1. Build the native Windows source with the corrected MMA implementation and run
   `-RunAttentionRegression`, `-RunW8Regression` and `-RunFrontendRegression`.
   MMA and the complete BF16/INT8 GQA oracle must pass on the physical SM75 card;
   a GPU skip or hosted executable build is not a numerical pass.
2. Produce and verify a new ZIP, then rerun the failed INT8 8K retrieval,
   required-tool and exact greedy MTP parity cases against its extracted binaries.
   Preserve failures, token IDs and full tool responses; do not change the
   original acceptance budget to relabel a historical failure.
3. After the baseline passes, complete 32K/64K retrieval and collect repeated
   request-phase timing, committed decode throughput, MTP acceptance and VRAM.
   Qualify Vision and RK4V4E8 separately before advertising them.

See the [physical validation runbook](sm75-2080ti-validation-runbook.md) for the
ordered gates. The BF16 controls narrow the investigation; they do not establish
a production workaround or prove the corrected model now passes.

## Acceptance and release contract

1. Complete native Windows build against the exact source SHA; confirm both
   applications and their non-system dependencies load.
2. Verify the ZIP, checksum manifest, SBOM, pinned artifact/toolchain locks and
   PowerShell 5.1 installation path using a clean extraction.
3. Run the numerical gates and the package's binaries on the physical **RTX 2080
   Ti 22GB / SM75** with the pinned model: short 8K smoke, semantic retrieval near
   8K/32K/64K, required tool call, exact MTP0/MTP3 token-ID parity and memory checks.
4. Bind machine-verifiable acceptance to that source commit, model and exact ZIP
   SHA-256. Performance, quality and capacity claims require their own evidence.
5. Publish only the exact package that passed the physical acceptance workflow;
   release verification must recheck its package and evidence, without rebuilding.

**128K remains experimental.** 192K/256K are optional probe targets, not supported
Windows context ceilings. An allocation success or plausible short output does
not establish long-context quality. Hosted CI establishes build/contract facts,
not physical GPU correctness or throughput.

## Historical tuning and PR provenance

The September [SM75 KVarN performance reference](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/bfd7ef2751c6e821ddd96cdf055928639f577705/docs/performance.md)
records Linux/GCC/CUDA 12.8 measurements at 250 W, KVarN and MTP3. Those are
historical measurements from a different runtime profile, not results for the
native Windows INT8/RK4V4E8 package. The current [performance reference](performance.md)
contains RTX 5090 campaigns and also cannot qualify this Windows target.

PR numbers in imported commits belong to the former
[`loktoto/ninfer-2080ti-22g`](https://github.com/loktoto/ninfer-2080ti-22g) repository.
For example, [native Windows #2](https://github.com/loktoto/ninfer-2080ti-22g/pull/2),
[RK4V4E8 #14](https://github.com/loktoto/ninfer-2080ti-22g/pull/14) and
[local validation #59](https://github.com/loktoto/ninfer-2080ti-22g/pull/59) are
historical provenance, not live status links for this repository.

- [Repository home](../README.md)
- [Windows source/build guide](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/docs/windows-sm75.md)
- [Windows installation guide](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/docs/INSTALL-WINDOWS-SM75.md)
- [Current repository Actions](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/actions)
- [Current repository pull requests](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/pulls)
- [Current repository releases](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/releases)
