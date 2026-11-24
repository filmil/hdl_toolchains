[![Test](https://github.com/filmil/hdl_toolchains/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/filmil/hdl_toolchains/actions/workflows/test.yml)

# hdl_toolchains

Bazel toolchains for hardware description languages.

## Status

The first piece is a simulation toolchain. [docs/issue_1_approach.md](docs/issue_1_approach.md)
sets out the wider plan: abstract toolchain types with generic operations,
so that a caller writes a generic rule rather than one named after a
simulator.

## Simulation

`sim_test` simulates SystemVerilog sources with whichever simulator
toolchain is registered, and passes when the simulator exits 0.

```starlark
load("@hdl_toolchains//sim:defs.bzl", "sim_test")

sim_test(
    name = "counter_test",
    srcs = ["counter.sv"],
    hdrs = ["include/step.svh"],  # their directories go on the include path
    defines = {"LIMIT": "10"},
    plusargs = ["go"],
    top = "counter_tb",
    waves = True,  # an FST in the test's undeclared outputs
)
```

The one simulator so far is [xezim](https://github.com/aionhw/xezim). It is
built from source by the xezim module in
[filmil/bazel-registry](https://github.com/filmil/bazel-registry) and
registered by this module. Like that module, it builds only on Linux x86_64.
From version 0.11.7.bcr.1 on, the module builds xezim with a pinned clang and
a pinned Debian sysroot, not with the host's C compiler.
With it, both `$fatal` and `$error` fail the test.

To use it, add the registry, as `.bazelrc` here does, and depend on this
module:

```starlark
bazel_dep(name = "hdl_toolchains", version = "0.0.1")
```

Your workspace needs a root `BUILD` file, even an empty one, because of
https://github.com/bazelbuild/rules_rust/issues/4385 in the xezim module's
crate dependencies.

To run the simulator directly, for example under a timer, use
`@xezim//:xezim` from a `bazel_dep` on `xezim`.

### Adding a simulator

A simulator is a `sim_toolchain` that names the simulator binary and how it
spells each option, plus a `toolchain` of type
`@hdl_toolchains//sim:toolchain_type`. See [sim/xezim/BUILD.bazel](sim/xezim/BUILD.bazel)
and `SimInfo` in [sim/providers.bzl](sim/providers.bzl).

## Building and testing

```sh
bazel build //...
(cd integration && bazel test //...)
```

The rules are tested from `integration/`, a separate workspace that uses this
module through `local_path_override`, as a downstream module would. The first
build compiles xezim from source, which takes a while.
