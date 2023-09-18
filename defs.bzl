load("@rules_pkg//pkg:providers.bzl", "PackageArtifactInfo")
load("@bazel_skylib//lib:new_sets.bzl", "sets")

def _platforms_transition(settings, attr):
    """
    Explode the build graph, possibly catastrophically for all our target platforms.
    Also, transition to extra_execution_platform required for the
    platform(s); registering them all in WORKSPACE seems to freak out:
    - always selects the first execution platform: centos/6
    TODO: figure that out; at least be able to explain why.
    """

    split_keys = sets.to_list(sets.make([label.name for label in attr.target_platforms + attr.exec_platforms]))

    splits = {split_key: {
        "//command_line_option:platforms": [],
        "//command_line_option:extra_execution_platforms": [],
        "//command_line_option:platform_suffix": None,
    } for split_key in split_keys}

    for label in attr.target_platforms:
        splits[label.name]["//command_line_option:platforms"] += ["%s" % label]
        splits[label.name]["//command_line_option:platform_suffix"] = "%s_%s" % (label.package.replace("/", "_"), label.name.replace("/", "_"))
    for label in attr.exec_platforms:
        splits[label.name]["//command_line_option:extra_execution_platforms"] += ["%s" % label]

    # Do we need to default to @local_config_platform//:host if either are empty?

    return splits

platforms_transition = transition(
    implementation = _platforms_transition,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
        "//command_line_option:platform_suffix",
        "//command_line_option:extra_execution_platforms",
    ],
)

def _platform_transition(settings, attr):
    return {
        "//command_line_option:platforms": ["%s" % attr.platform],
        "//command_line_option:extra_execution_platforms": ["%s" % attr.platform],
        "//command_line_option:platform_suffix": "%s_%s" % (attr.platform.package.replace("/", "_"), attr.platform.name.replace("/", "_")),
    }

platform_transition = transition(
    implementation = _platform_transition,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
        "//command_line_option:platform_suffix",
        "//command_line_option:extra_execution_platforms",
    ],
)

def _platforms(ctx):
    """Collect files for each platform."""

    return [DefaultInfo(files = depset(transitive = [ctx.split_attr.actual[target].files for target in ctx.split_attr.actual]))]

platforms = rule(
    implementation = _platforms,
    attrs = {
        "actual": attr.label(mandatory = True, cfg = platforms_transition),
        "target_platforms": attr.label_list(providers = [platform_common.PlatformInfo]),
        "exec_platforms": attr.label_list(providers = [platform_common.PlatformInfo]),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

TestArgInfo = provider(fields = ["args", "data"])

def _test_arg_info_aspect(target, ctx):
    data = getattr(ctx.rule.attr, "data", [])
    args = getattr(ctx.rule.attr, "args", [])
    args = [ctx.expand_location(arg, data) for arg in args]
    return [
        TestArgInfo(args = args, data = getattr(ctx.rule.files, "data", [])),
    ]

test_arg_info_aspect = aspect(implementation = _test_arg_info_aspect)

def _platform_test(ctx):
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.expand_template(template = ctx.file._tpl, output = executable, is_executable = True, substitutions = {
        "${test?}": ctx.executable.test.short_path,
        "${args?}": " ".join(ctx.attr.test[TestArgInfo].args),
    })
    return [DefaultInfo(executable = executable, runfiles = ctx.runfiles(files = ctx.files.test, transitive_files = depset(ctx.attr.test[TestArgInfo].data)))]

platform_test = rule(
    implementation = _platform_test,
    attrs = {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "platform": attr.label(mandatory = True, providers = [platform_common.PlatformInfo]),
        "test": attr.label(mandatory = True, cfg = "target", executable = True, aspects = [test_arg_info_aspect]),
        "_tpl": attr.label(default = "//:platform.test.sh.tpl", allow_single_file = True),
    },
    cfg = platform_transition,
    test = True,
)

def platforms_test(name, platforms = [], test = None, **kwargs):
    tests = []
    test = Label(test)
    for i, p in enumerate(platforms):
        pl = Label(p)
        test_name = "%s_%d_%s" % (test.name, i, pl.name)
        tests += [test_name]
        platform_test(
            name = test_name,
            platform = pl,
            test = test,
        )
    native.test_suite(
        name = name,
        tests = tests,
        **kwargs
    )
