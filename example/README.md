# Example of using rules_lint

The `src/` folder contains a project that we want to lint.
It contains sources in multiple languages.

### With Aspect CLI

We haven't published the plugin from this repo yet, so build it from source:

```bash
cd ..; bazel build dev
```

Then you can run `bazel lint src:all`

### Without Aspect CLI

There's a shell script to approximate what our Aspect CLI plugin does:

```
rules_lint/example$ ./lint.sh src:all
INFO: Analyzed 4 targets (0 packages loaded, 0 targets configured).
INFO: Found 4 targets...
INFO: Elapsed time: 0.063s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
From /shared/cache/bazel/user_base/b6913b1339fd4037a680edabc6135c1d/execroot/_main/bazel-out/k8-fastbuild/bin/src/ts.eslint-report.txt:

/shared/cache/bazel/user_base/b6913b1339fd4037a680edabc6135c1d/sandbox/linux-sandbox/861/execroot/_main/bazel-out/k8-fastbuild/bin/src/file.ts
  2:7  error  Type string trivially inferred from a string literal, remove type annotation  @typescript-eslint/no-inferrable-types

✖ 1 problem (1 error, 0 warnings)
  1 error and 0 warnings potentially fixable with the `--fix` option.

From /shared/cache/bazel/user_base/b6913b1339fd4037a680edabc6135c1d/execroot/_main/bazel-out/k8-fastbuild/bin/src/foo_proto.buf-report.txt:
--buf-plugin_out: src/file.proto:1:1:Import "src/unused.proto" is unused.

```

## ESLint

This folder simply follows the instructions at https://typescript-eslint.io/getting-started
to create the ESLint setup.

## Buf
