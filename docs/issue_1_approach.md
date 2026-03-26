# Proposed Approach for `hdl_toolchains` (Issue #1)

This document outlines the recommended approach for creating a Bazel-based repository for Hardware Description Language (HDL) toolchains, aiming to provide a robust, generic, and hermetic build environment for both Verilog and VHDL.

## Goals

1. **Hermeticity:** Ensure that HDL builds and tests are fully isolated and reproducible across different machines, without depending on the host's implicitly installed toolchains (like Verilator, Yosys, Icarus Verilog, GHDL, etc.).
2. **Bazel Native (Bzlmod):** Utilize `MODULE.bazel` to define external dependencies and standard Bazel toolchain resolution APIs instead of legacy `WORKSPACE` practices.
3. **Cross-Platform Support:** Handle toolchain retrieval for different operating systems (Linux, macOS, Windows) seamlessly.
4. **Generic Operations:** Abstract the build steps (compilation, simulation, synthesis) away from specific underlying tools. Users should write rules like `verilog_library` or `vhdl_library`, not tool-specific rules like `iverilog_library` or `ghdl_library`.

## Recommended Architecture

### 1. Abstract Toolchain Interface (`toolchain_type`)

Instead of exposing specific executables directly, the toolchain should expose generic operations (actions) that abstract the underlying tools.

We can define a generic HDL toolchain type (or separate ones for simulation vs. synthesis if they diverge significantly) in a `bzl` file (e.g., `toolchain/hdl_toolchain.bzl`):

```starlark
def _hdl_toolchain_info_impl(ctx):
    # The toolchain provides callbacks/functions that rules can invoke
    # to perform generic operations.
    return platform_common.ToolchainInfo(
        # Compilation & Simulation
        compile_verilog = ctx.attr._compile_verilog_impl,
        compile_vhdl = ctx.attr._compile_vhdl_impl,
        simulate = ctx.attr._simulate_impl,

        # Synthesis
        synthesize = ctx.attr._synthesize_impl,

        # Underlying tool execution information (for the callbacks to use)
        simulator_tool = ctx.executable.simulator,
        synthesizer_tool = ctx.executable.synthesizer,
    )

hdl_toolchain = rule(
    implementation = _hdl_toolchain_info_impl,
    attrs = {
        # The specific tools backing this toolchain instance
        "simulator": attr.label(executable = True, cfg = "exec", allow_single_file = True),
        "synthesizer": attr.label(executable = True, cfg = "exec", allow_single_file = True),

        # Internal implementations for the generic operations
        "_compile_verilog_impl": attr.label(default = "//toolchain/impl:compile_verilog"),
        "_compile_vhdl_impl": attr.label(default = "//toolchain/impl:compile_vhdl"),
        "_simulate_impl": attr.label(default = "//toolchain/impl:simulate"),
        "_synthesize_impl": attr.label(default = "//toolchain/impl:synthesize"),
    },
)
```

In `BUILD.bazel`:

```starlark
toolchain_type(name = "toolchain_type", visibility = ["//visibility:public"])
```

### 2. Backing Toolchains with Specific Tools

You can then create specific instances of the `hdl_toolchain` backed by different open-source tools:

*   **Verilog Simulation:** Backed by Icarus Verilog or Verilator.
*   **VHDL Simulation:** Backed by GHDL or NVC.
*   **Synthesis:** Backed by Yosys (which supports Verilog and some VHDL via plugins).

When a user executes a build, Bazel's toolchain resolution selects the appropriate `hdl_toolchain` based on the target platform and execution constraints.

### 3. Generic Build Rules

Users will write build files using generic rules like `verilog_library`, `vhdl_library`, and `hdl_test`. These rules do not know about the underlying tools; they only know how to ask the resolved toolchain to perform an operation.

```starlark
# In bzl/rules.bzl
def _verilog_library_impl(ctx):
    toolchain = ctx.toolchains["//toolchain:toolchain_type"]

    # Delegate the actual compilation to the toolchain's generic operation
    compiled_outputs = toolchain.compile_verilog(
        ctx = ctx,
        srcs = ctx.files.srcs,
        deps = ctx.attr.deps,
    )

    return [DefaultInfo(files = depset(compiled_outputs))]

verilog_library = rule(
    implementation = _verilog_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".v", ".sv"]),
        "deps": attr.label_list(),
    },
    toolchains = ["//toolchain:toolchain_type"],
)

def _vhdl_library_impl(ctx):
    toolchain = ctx.toolchains["//toolchain:toolchain_type"]

    compiled_outputs = toolchain.compile_vhdl(
        ctx = ctx,
        srcs = ctx.files.srcs,
        deps = ctx.attr.deps,
    )

    return [DefaultInfo(files = depset(compiled_outputs))]

vhdl_library = rule(
    implementation = _vhdl_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".vhd", ".vhdl"]),
        "deps": attr.label_list(),
    },
    toolchains = ["//toolchain:toolchain_type"],
)
```

### 4. Bzlmod Integration and External Repositories

Use repository rules and Bzlmod to fetch pre-compiled binaries of the required HDL tools seamlessly.

```starlark
# In bzl/extensions.bzl
hdl_extension = module_extension(
    implementation = _hdl_extension_impl,
)

def _hdl_extension_impl(module_ctx):
    # Fetch OSS CAD Suite or individual tools
    # e.g., iverilog_repo(), ghdl_repo(), yosys_repo()
    pass
```

Register the downloaded toolchains in `MODULE.bazel`:

```starlark
register_toolchains("@hdl_toolchains_repo//:all")
```

## Next Steps to Implement

1.  **Define the Abstraction Layer:** Formalize the generic operations (Providers or Starlark functions) that the toolchain must implement for compilation, simulation, and synthesis.
2.  **Select Initial Backing Tools:** Start with Icarus Verilog for Verilog, GHDL for VHDL, and Yosys for synthesis.
3.  **Implement Bzlmod Fetching:** Write the repository rules to download these tools for various host architectures.
4.  **Implement the Generic Rules:** Write `verilog_library`, `vhdl_library`, and `hdl_test` rules that delegate to the toolchain operations.
5.  **Create Example Workflows:** Build a sample project containing both Verilog and VHDL modules that interact and are tested and synthesized via the generic rules.

## Integration Testing Strategy

Any functionality implemented within the `hdl_toolchains` repository must be thoroughly validated against end-to-end user workflows.

To achieve this cleanly, all integration tests should reside in a separate Bazel workspace located within the `integration` directory of the repository root. This guarantees that the rules are consumed exactly as a downstream user would (e.g., via `local_path_override` in the integration workspace's `MODULE.bazel`).

*Note: The `integration` directory should be excluded from the main repository's source control via `.gitignore`, or if tracked, should be explicitly managed as a separate standalone project.*