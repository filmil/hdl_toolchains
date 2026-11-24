#!/usr/bin/env bash
# Runs a sim_test and passes only if it fails.
#   expect_fail.sh <sim_test executable> <line its output must have>
set -uo pipefail
out="$("$1" 2>&1)"
rc=$?
echo "${out}"
[[ ${rc} -ne 0 ]] || { echo "FAIL: the simulation passed"; exit 1; }
grep -qF -- "$2" <<<"${out}" || { echo "FAIL: no '$2' in the output"; exit 1; }
echo "PASS: failed with exit ${rc}"
