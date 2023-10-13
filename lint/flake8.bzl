"""API for declaring a flake8 lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")

flake8 = flake8_aspect(
    binary = "@@//:flake8",
    config = "@@//:.flake8",
)
```
"""

def flake8_action(ctx, executable, srcs, config, report, use_exit_code = False):
    """Run flake8 as an action under Bazel.

    Based on https://flake8.pycqa.org/en/latest/user/invocation.html

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the flake8 program
        srcs: python files to be linted
        config: label of the flake8 config file (setup.cfg, tox.ini, or .flake8)
        report: output file to generate
        use_exit_code: whether to fail the build when a lint violation is reported
    """
    inputs = srcs + [config, executable]
    outputs = [report]

    # Wire command-line options, see
    # https://flake8.pycqa.org/en/latest/user/options.html
    args = ctx.actions.args()
    args.add_all(srcs)
    args.add("--format=sarif")
    args.add(config, format = "--config=%s")
    if not use_exit_code:
        args.add("--exit-zero")

    # The -output-file argument seems not to work with -format=sarif.
    # So we pipe stdout instead.
    # (https://github.com/bazelbuild/bazel/issues/5511 tracks ctx.actions.run support for stdout redirect)
    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = "{flake8} $@ > {report}".format(flake8 = executable.path, report = report.path),
        arguments = [args],
        mnemonic = "flake8",
    )

# buildifier: disable=function-docstring
def _flake8_aspect_impl(target, ctx):
    if ctx.rule.kind in ["py_library"]:
        report = ctx.actions.declare_file(target.label.name + ".flake8-report.sarif")
        flake8_action(ctx, ctx.executable._flake8, ctx.rule.files.srcs, ctx.file._config_file, report)
        results = depset([report])
    else:
        results = depset()

    return [
        OutputGroupInfo(report = results),
    ]

def flake8_aspect(binary, config):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a flake8 executable. Can be obtained from rules_python like so:

            load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

            py_console_script_binary(
                name = "flake8",
                pkg = "@pip//flake8:pkg",
            )

        config: the flake8 config file (`setup.cfg`, `tox.ini`, or `.flake8`)
    """
    return aspect(
        implementation = _flake8_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "_flake8": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
        },
    )
