#!/usr/bin/env bash
# Runs a sim_test with waves and checks that it wrote the dump.
set -euo pipefail
export TEST_UNDECLARED_OUTPUTS_DIR="${TEST_TMPDIR}/outputs"
mkdir -p "${TEST_UNDECLARED_OUTPUTS_DIR}"
"$1"
[[ -s "${TEST_UNDECLARED_OUTPUTS_DIR}/$2" ]] || { echo "FAIL: no $2"; exit 1; }
echo PASS
