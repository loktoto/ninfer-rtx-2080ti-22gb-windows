# RTX 2080 Ti 22GB / Qwen3.8-27B physical validation runbook

Native Windows INT8 Base correctness is the first gate. RK4V4E8 capacity and
performance qualification follow only after that baseline passes. Build success
alone establishes neither GPU correctness nor a context ceiling, throughput or
long-context quality.

## Evidence and immediate blocker

The latest tracked physical Windows report covers **2026-10-12/13**, using package
source `94c0484de2e41dc3683ee60234c49e66dc08476d`. Its short 8K-capacity smoke
passed; retrieval at 7,936 input tokens, required tool calling and exact greedy
MTP0/MTP3 parity failed. Follow-up testing found 33 failing INT8 GQA cases and an
SM75 MMA fragment-order defect. Four standalone matrix-oracle cases passed after
the correction; full corrected GQA/model acceptance remained pending.

See [project status](PROJECT-STATUS.md#what-was-actually-tested) and the immutable
[historical Windows report](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/d9a76506546d77d71ed5d7b72dd0ee4b1148b08a/docs/WINDOWS-SM75-LOCAL-VALIDATION.md).
The following commands are a reproduction/acceptance procedure, **not a record
that a replacement package has passed**. BF16 parity/tool controls passed in the
investigation, but BF16 retrieval timed out; neither result qualifies INT8 or RK4V4E8.

## Native Windows baseline and package gate

Use the native Windows source containing the MMA correction, the pinned
[toolchain and provisioning instructions](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/docs/windows-sm75.md)
and the exact `qwen3_8_27b.ninfer` selected by its
[artifact lock](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/config/windows-sm75-artifacts.json).
The imported `master` snapshot does not contain all native build/package files;
do not run another branch's commands against it or substitute an unpinned model.

On the physical Windows RTX 2080 Ti 22GB, after provisioning:

```powershell
.\scripts\build-windows-sm75.ps1 -WholeProgramCuda -RunW8Regression -RunFrontendRegression -RunAttentionRegression
.\scripts\verify-windows-sm75.ps1 -RequireDependencyAudit
.\scripts\package-windows-sm75.ps1
.\scripts\verify-package-windows-sm75.ps1
```

The numerical gate runs `ninfer_sm75_mma_test` and `ninfer_gqa_attention_test`
against independent dense-matrix/attention oracles. Require both to pass, with
W8 and frontend checks, before interpreting model output. Exit 77 or another
GPU skip fails physical qualification. Hosted compilation of these executables
is not a numerical pass. The physical acceptance workflow must execute the same
regressions before it produces a candidate package.

Run acceptance on the binaries extracted from that exact ZIP. In a source
checkout with a newly produced package and no existing `qualified-runtime` tree:

```powershell
$SourceSha = (& git.exe rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve source commit.' }
$PackageName = 'ninfer-windows-sm75-' + $SourceSha.Substring(0,12)
$Zip = (Resolve-Path (Join-Path '.\dist' ($PackageName + '.zip'))).Path
if (Test-Path '.\qualified-runtime') { throw 'Choose a fresh extraction directory.' }
Expand-Archive -Path $Zip -DestinationPath '.\qualified-runtime'
.\scripts\acceptance-windows-sm75.ps1 `
  -Model 'D:\AI\models\qwen\qwen3_8_27b.ninfer' `
  -PackagePath $Zip `
  -InstallDir (Join-Path 'qualified-runtime' $PackageName)
```

Use all default acceptance gates: exact 8K smoke, token-calibrated semantic
retrieval near 8K/32K/64K, `get_weather` with `city=Paris`, and exact greedy
MTP0/MTP3 generated-token IDs. A partial run with skip switches is diagnostic,
not release evidence. Preserve failing requests, token IDs and full tool
responses. A larger output budget or timeout is a new test profile and cannot
turn the original failure into a pass.

On success, use the exact evidence path printed by the harness:

```powershell
.\scripts\verify-acceptance-evidence.ps1 `
  -EvidencePath '.\acceptance\windows-sm75-<timestamp>.json' `
  -ExpectedGitSha $SourceSha `
  -PackagePath $Zip `
  -LockPath '.\config\windows-sm75-artifacts.json'
```

The evidence must bind the physical GPU, pinned model, source commit and ZIP
SHA-256. If acceptance aborts, retain its logs as failure evidence; an absent
success JSON is not a pass. For installation, extract the ZIP again: acceptance
logs added to an extraction must not be included in the checksummed install tree.
Only the exact physically qualified ZIP can be published.

## Optional RK4V4E8 qualification

The Bash harnesses below are developer tools for a separate compressed-KV
profile. They do not replace native Windows package acceptance, and results from
a Linux build do not qualify a Windows ZIP. Their 64K–256K ladders describe test
candidates; no such capacity or speed is established by this runbook.

### 0. Freeze the environment

Record before measuring:

```bash
nvidia-smi --query-gpu=name,driver_version,memory.total,power.limit,clocks.max.sm,clocks.max.memory --format=csv
nvcc --version
sha256sum MODEL.ninfer
```

Keep the same artifact, driver/toolkit, power limit, clocks, display load and thermal state while comparing KV modes. Do not compare one run taken at a different power/clock policy as if only the software changed.

### 1. Build the SM75 runtime and benchmark

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_ARCHITECTURES=75 \
  -DNINFER_BUILD_APPS=ON \
  -DNINFER_BUILD_BENCHMARKS=ON
cmake --build build -j --target ninfer ninfer-serve ninfer_bench
```

This builds the developer runtime and benchmark for the Bash harnesses. It is
separate from the pinned native Windows package build above.

### 2. Capacity gate — prove what actually fits

```bash
chmod +x bench/targets/qwen3_6_27b/sm75_rk4v4e8_probe.sh
./bench/targets/qwen3_6_27b/sm75_rk4v4e8_probe.sh MODEL.ninfer
```

Default ladder: 64K, 128K, 192K, 256K.

A row is a capacity PASS only when the probe uses `--max-context N --kv-capacity N`, the model loads, and one token is generated. This one-token allocation probe does not ingest an N-token prompt. `--kv-capacity auto` is intentionally not accepted as proof because automatic sizing may resolve below the requested maximum context.

The probe reports two independent ceilings. It first resolves the highest eager explicit-capacity rung with CUDA Graph disabled. It then starts from that rung and walks downward as needed until it finds the highest explicit-capacity profile that also fits MTP + CUDA Graph. Eager fit and MTP/graph fit are different results.

Do not publish a 192K or 256K ceiling unless that exact row passed on the physical 22GB card in the runtime mode being claimed.

### 3. Performance gate — compare identical workloads

```bash
chmod +x bench/targets/qwen3_6_27b/sm75_autotune.sh
./bench/targets/qwen3_6_27b/sm75_autotune.sh MODEL.ninfer
```

The default matrix compares:

- KV: `int8`, `rk4v4-e8`
- prefill chunk: 512, 1024
- speculative draft: MTP0, 2, 3, 4, 5
- repeated greedy decode

Use `ninfer_bench` rather than the CLI fallback when publishing results. It reports prefill throughput, decode mean/stddev and MTP acceptance while loading the model once per profile.

Do not choose a daily profile from decode throughput alone. The harness reports:

- fastest decode profile;
- fastest prefill profile;
- balanced profile: at least 97% of best decode throughput, then highest prefill throughput.

For long-prompt workloads, repeat the winning candidates with larger `BENCH_PROMPT` values, for example:

```bash
BENCH_PROMPT=32768 REPS=3 ./bench/targets/qwen3_6_27b/sm75_autotune.sh MODEL.ninfer
BENCH_PROMPT=65536 REPS=3 ./bench/targets/qwen3_6_27b/sm75_autotune.sh MODEL.ninfer
```

A short-prompt prefill result must not be extrapolated to 64K+ ingestion.

### 4. Quality gate — token-calibrated long-context retrieval

When testing the default MTP path, set `MAX_CONTEXT` no higher than the MTP + CUDA Graph ceiling from section 2. For an MTP0 control, an eager-fit rung may be used instead.

```bash
chmod +x bench/targets/qwen3_6_27b/sm75_long_context_quality.sh
MAX_CONTEXT=131072 \
  ./bench/targets/qwen3_6_27b/sm75_long_context_quality.sh MODEL.ninfer
```

The harness loads `ninfer-serve` once, uses `/v1/messages/count_tokens` to calibrate each prompt to an observed token depth, places a unique retrieval needle at early/middle/late positions, and requires exact-code recall.

To validate a higher proven capacity:

```bash
MAX_CONTEXT=262144 \
QUALITY_CONTEXTS="32768 65536 131072 196608 262144" \
  ./bench/targets/qwen3_6_27b/sm75_long_context_quality.sh MODEL.ninfer
```

If an RK4V4E8 + MTP run fails, do not immediately attribute the failure to 4-bit KV. Run the same test without speculative decoding:

```bash
MAX_CONTEXT=262144 MTP_DRAFT=0 \
QUALITY_CONTEXTS="32768 65536 131072 196608 262144" \
  ./bench/targets/qwen3_6_27b/sm75_long_context_quality.sh MODEL.ninfer
```

Interpretation:

- RK4V4E8 MTP PASS + MTP0 PASS: long-context retrieval gate passes.
- RK4V4E8 MTP FAIL + MTP0 PASS: investigate speculative/MTP path before blaming KV compression.
- RK4V4E8 MTP0 FAIL + INT8 MTP0 PASS: compressed-KV quality/correctness is the leading suspect.
- both INT8 and RK4V4E8 fail at the same depth: investigate model/context/prompt or shared attention path first.

For an INT8 control, run the same harness with `KV_DTYPE=int8` at a capacity that INT8 actually fits. Require the corrected INT8 MMA/GQA baseline first; a known-failing INT8 route is not a valid quality control.

### 5. Vision headroom gate

Vision has fixed and request-time allocations. A text-only context fit is not a Vision fit. Start from 64K or 128K and measure memory summary plus representative image/video requests before increasing context.

Do not claim `Vision + 256K + MTP3` from a text-only capacity result.

### 6. Release decision

A compressed-KV profile can be called validated on RTX 2080 Ti 22GB only when the native baseline and all applicable gates below are recorded from the same physical card and software build:

- exact artifact hash and software/driver environment recorded;
- explicit capacity rung passes in the runtime mode being claimed;
- benchmark has repeated measurements and no unexplained outlier selected as winner;
- MTP acceptance is recorded alongside output tok/s;
- long-context retrieval passes at the intended depth, with MTP0 control available for failures;
- Vision headroom is measured separately when Vision is part of the advertised profile.

Until those physical-card results exist, repository CI establishes build/contract correctness only; it does not establish the final 2080 Ti performance number or maximum usable context.
