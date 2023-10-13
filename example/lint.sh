#!/usr/bin/env bash
#
# Shows an end-to-end workflow for linting without failing the build.
# This is meant to mimic the behavior of the `bazel lint` command that you'd have
# by using the Aspect CLI with the plugin in this repository.
#
# We recommend using Aspect CLI instead!
set -o errexit -o pipefail -o nounset

if [ "$#" -eq 0 ]; then
    echo "usage: lint.sh [target pattern...]"
    exit 1
fi

# Produce report files
bazel build --aspects //:lint.bzl%eslint,//:lint.bzl%buf,//:lint.bzl%flake8 --output_groups=report $@

# Show the results.
# `-mtime -1`: only look at files modified in the last day, to mitigate showing stale results of old bazel runs.
# `-size +1c`: don't show files containing zero bytes
#
# SARIF contains absolute paths (both for flake8 and eslint)
# However, for flake8 this is not a problem, because we run it against the real source files.
# So reviewdog can re-relativize them on output.
# For eslint, it's not pretty (everything is prefixed with `../../.cache/bazel/_bazel_tos/d36d2bbba7f14022b41b33a6745e4b76/sandbox/linux-sandbox/923/execroot/_main/bazel-out/k8-fastbuild/bin/`).
# eslint doesn't seem to want to change to relative paths: https://github.com/eslint/eslint/issues/13376
for report in $(find $(bazel info bazel-bin) -mtime -1 -size +1c -type f -name "*.sarif"); do
    echo ${report}
    cat ${report} | reviewdog -f=sarif -filter-mode=nofilter
done
