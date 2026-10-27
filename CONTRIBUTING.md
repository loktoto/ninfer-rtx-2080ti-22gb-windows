# Contributing

I maintain this fork as [loktoto](https://github.com/loktoto), with a focus on the RTX 2080 Ti 22GB and native Windows. Contributions should make that path easier to build, run or verify. Preserve the original NInfer authorship and Apache-2.0 notices.

## Choose the right branch

`master` contains the SM75 source baseline. Native Windows runtime, installer and packaging work lives on [`windows-native-sm75`](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/tree/windows-native-sm75). State the intended branch in your pull request and check the [project status](docs/PROJECT-STATUS.md) before describing a feature as supported.

Read [AGENTS.md](AGENTS.md) for architecture, ownership, numerical correctness and verification requirements. Keep implementation, tests, tools and active documentation consistent when a contract changes. Discuss changes to established architecture, artifact formats or public protocols before implementing them.

## Bring evidence for the change

Review the complete diff, including error paths, state changes and resource ownership. Choose checks that establish the behavior you changed:

- Exact formats and transformations need exact comparisons.
- CUDA math needs an independent mathematical oracle, suitable tolerances and relevant shapes.
- Stateful behavior needs checks of the affected state transition.
- CLI and serving changes need observable behavior and affected schema checks.
- Performance claims need measurements at the claimed scope, with the workload, hardware and toolchain recorded.
- Documentation changes need valid links, accurate commands and `git diff --check`.

Use the existing [test guide](tests/README.md), [benchmarks](bench/README.md) and [Op development reference](docs/maintainer/op-development.md). For Windows, use the branch's [build and acceptance guide](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/blob/windows-native-sm75/docs/windows-sm75.md).

A hosted build establishes compilation and package checks. Physical GPU correctness and exact-package release acceptance require their own runs. State any relevant check you could not run and why.

## Pull requests

Use [this repository's pull requests](https://github.com/loktoto/ninfer-rtx-2080ti-22gb-windows/pulls). Include:

- The concrete problem and resulting behavior.
- The design choice and affected contracts.
- Verification commands and summarized results, including failures or missing prerequisites.
- Hardware, toolchain and workload for numerical or performance claims.

AI-assisted contributions carry the same responsibility as other contributions: understand and review the code before submitting it. Entirely AI-generated implementations must use a current state-of-the-art coding model, with the exact model and version disclosed; the maintainer decides whether that requirement is met. Unreviewed output and unsupported validation claims are not ready for review.

Keep the change coherent. Review may be declined when basic correctness, verification or ownership requirements are unmet. Never include credentials or sensitive vulnerability details in a public pull request; use the [security policy](SECURITY.md).
