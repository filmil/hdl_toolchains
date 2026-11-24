"""The rule that declares a simulator toolchain."""

load(":providers.bzl", "SimInfo")

def _sim_toolchain_impl(ctx):
    sim = ctx.attr.simulator[DefaultInfo]
    return [platform_common.ToolchainInfo(sim = SimInfo(
        executable = sim.files_to_run.executable,
        runfiles = sim.default_runfiles,
        define = ctx.attr.define,
        define_bare = ctx.attr.define_bare,
        incdir = ctx.attr.incdir,
        top = ctx.attr.top,
        plusarg = ctx.attr.plusarg,
        waves = ctx.attr.waves,
        waves_extension = ctx.attr.waves_extension,
        extra_args = ctx.attr.extra_args,
    ))]

sim_toolchain = rule(
    implementation = _sim_toolchain_impl,
    doc = "Declares a simulator and its option spellings. See SimInfo.",
    attrs = {
        # The simulator runs inside the test, so it is built for the target.
        "simulator": attr.label(executable = True, cfg = "target", mandatory = True),
        "define": attr.string_list(mandatory = True),
        "define_bare": attr.string_list(mandatory = True),
        "incdir": attr.string_list(mandatory = True),
        "top": attr.string_list(mandatory = True),
        "plusarg": attr.string_list(mandatory = True),
        "waves": attr.string_list(),
        "waves_extension": attr.string(),
        "extra_args": attr.string_list(),
    },
)
