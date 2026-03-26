# Proposed Approach for `hdl_toolchains` (Issue #1)

Since the exact contents of issue #1 are unavailable, this approach outlines the best practices and recommended steps for creating a Bazel-based repository for Hardware Description Language (HDL) toolchains, which is the primary implied goal of the repository `filmil/hdl_toolchains`.

## Goals

1. **Hermeticity:** Ensure that HDL builds and tests are fully isolated and reproducible across different machines, without depending on the host's implicitly installed toolchains (like Verilator, Yosys, Icarus Verilog, etc.).
2. **Bazel Native (Bzlmod):** Utilize `MODULE.bazel` to define external dependencies and standard Bazel toolchain resolution APIs instead of legacy `WORKSPACE` practices.
3. **Cross-Platform Support:** Handle toolchain retrieval for different operating systems (Linux, macOS, Windows) seamlessly.

## Recommended Architecture

### 1. Toolchain Definition (`toolchain_type`)

Define abstract toolchain types for various HDL tools. For example, in a `bzl` file (e.g., `toolchain/hdl_toolchain.bzl`):

```starlark
def _hdl_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        yosys = ctx.executable.yosys,
        verilator = ctx.executable.verilator,
        iverilog = ctx.executable.iverilog,
        # ... other relevant tools
    )
    return [toolchain_info]

hdl_toolchain = rule(
    implementation = _hdl_toolchain_impl,
    attrs = {
        "yosys": attr.label(executable = True, cfg = "exec", allow_single_file = True),
        "verilator": attr.label(executable = True, cfg = "exec", allow_single_file = True),
        "iverilog": attr.label(executable = True, cfg = "exec", allow_single_file = True),
    },
)
```

And in a `BUILD.bazel` file:

```starlark
toolchain_type(name = "toolchain_type", visibility = ["//visibility:public"])
```

### 2. External Repository Rules for Toolchains

Write repository rules to fetch pre-compiled binaries of the required HDL tools. These rules should:
- Detect the host OS and architecture.
- Download the appropriate release archives from official sources (or GitHub releases).
- Extract them.
- Generate a `BUILD.bazel` file that exposes the executables via the `hdl_toolchain` rule.

```starlark
# In bzl/hdl_repository.bzl
def _hdl_toolchain_repo_impl(ctx):
    # Detect OS/Arch
    # Download correct binaries
    # Create BUILD file defining hdl_toolchain
    pass

hdl_toolchain_repo = repository_rule(
    implementation = _hdl_toolchain_repo_impl,
)
```

### 3. Module Extension (Bzlmod)

Integrate the repository rule into Bzlmod using a module extension. This allows other projects to use `hdl_toolchains` by declaring it in their `MODULE.bazel`.

```starlark
# In bzl/extensions.bzl
hdl_extension = module_extension(
    implementation = _hdl_extension_impl,
)

def _hdl_extension_impl(module_ctx):
    # Call hdl_toolchain_repo()
    pass
```

### 4. Toolchain Registration

Expose the downloaded toolchains to Bazel's resolution mechanism. In `MODULE.bazel`:

```starlark
register_toolchains("@hdl_toolchains_repo//:all")
```

### 5. Writing Build Rules

Create custom Bazel rules (e.g., `verilog_library`, `verilog_test`, `yosys_synth`) that request the toolchain type.

```starlark
def _verilog_test_impl(ctx):
    toolchain = ctx.toolchains["//toolchain:toolchain_type"]
    iverilog = toolchain.iverilog
    # ... compile and run test using iverilog
```

## Next Steps to Implement

1.  **Select Target Tools:** Decide on the initial set of tools to support (e.g., Icarus Verilog and Yosys).
2.  **Locate Binaries:** Find reliable sources for pre-compiled binaries for Linux, macOS, and (optionally) Windows. OSS CAD Suite is a good comprehensive source.
3.  **Implement Repository Rule:** Write the `repository_rule` to download and configure these binaries.
4.  **Implement Bzlmod Extension:** Create the module extension to integrate with `MODULE.bazel`.
5.  **Write Minimal Rules:** Create a simple `verilog_test` rule to verify the toolchain works end-to-end.
6.  **Add Examples:** Provide a small example project demonstrating how to use the toolchain.
