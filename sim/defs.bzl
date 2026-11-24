"""Public API of the HDL simulation rules."""

load(":providers.bzl", _SimInfo = "SimInfo")
load(":sim_test.bzl", _sim_test = "sim_test")
load(":toolchain.bzl", _sim_toolchain = "sim_toolchain")

SimInfo = _SimInfo
sim_test = _sim_test
sim_toolchain = _sim_toolchain
