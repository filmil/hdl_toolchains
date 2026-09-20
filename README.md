[![Test](https://github.com/filmil/hdl_toolchains/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/filmil/hdl_toolchains/actions/workflows/test.yml)

# hdl_toolchains

Bazel toolchains for hardware description languages.

## Status

This repository is at the design stage and implements no rules yet.
[docs/issue_1_approach.md](docs/issue_1_approach.md) sets out the proposed
architecture: an abstract toolchain type that exposes generic operations,
so that a caller writes `verilog_library` rather than a rule named after
whichever simulator happens to be installed.

## Building

```sh
bazel build //...
```

Bazel itself is pinned by `.bazelversion` and fetched by
[Bazelisk](https://github.com/bazelbuild/bazelisk), so no toolchain needs
installing first.

There are no targets yet, so the build succeeds without doing anything.
It is still worth running, and worth having in CI, because it is what
proves the module resolves and the registries named in `.bazelrc` answer.

`bazel test //...` reports that no test targets were found, which is
accurate until the first rule lands.
