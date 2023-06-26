load("@rules_pkg//pkg:providers.bzl", "PackageArtifactInfo")

debian_splits = ["debian/11", "debian/12", "ubuntu/kinetic", "ubuntu/lunar"]
redhat_splits = ["centos/6", "centos/7", "fedora/37", "fedora/38", "rockylinux/8", "rockylinux/9"]

def _split(splits):
    """
    Assume we've named all our platforms and toolchains consistently and generate the split.
    This could be defined as a rule attribute dictionary rather than hidden in here.
    TODO Decide if that is better or not.
    """
    return {
        split: {
            "//command_line_option:platforms": ["//platforms:%s" % split],
            "//command_line_option:extra_execution_platforms": ["//platforms:%s" % split],
            "//command_line_option:extra_toolchains": ["//toolchains/cc:%s" % split],
        }
        for split in splits
    }

def _all_platforms_transition(settings, attr):
    """
    Explode the build graph, possibly catastrophically for all our target platforms.
    Also, transition to extra_execution_platform and extra_toolchains required for the
    platform(s); registering them all in WORKSPACE seems to freak out:
    - always selects the first execution platform: centos/6
    - somehow seems to get confused which toolchain to use despite exec_compatible_with
      and target_compatible_with and picks @local_config_cc?
    TODO: figure that out; at least be able to explain why.
    """

    if "//platforms/family:debian" in attr.target_compatible_with + attr.exec_compatible_with:
        return _split(debian_splits)
    elif "//platforms/family:redhat" in attr.target_compatible_with + attr.exec_compatible_with:
        return _split(redhat_splits)
    else:
        return _split(debian_splits + redhat_splits)

all_platforms_transition = transition(
    implementation = _all_platforms_transition,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
        "//command_line_option:extra_execution_platforms",
        "//command_line_option:extra_toolchains",
    ],
)

def _all_platforms(ctx):
    """Collect files for each platform."""
    ins_and_outs = {
        in_file: ctx.actions.declare_file("%s/%s" % (in_dir, in_file.basename))
        for in_dir in ctx.split_attr.actual
        for in_file in ctx.split_attr.actual[in_dir].files.to_list()
    }
    for in_file, out_file in ins_and_outs.items():
        ctx.actions.symlink(output = out_file, target_file = in_file)

    return [DefaultInfo(files = depset(ins_and_outs.values()))]

all_platforms = rule(
    implementation = _all_platforms,
    attrs = {
        "actual": attr.label(mandatory = True, cfg = all_platforms_transition),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def platforms(name, actual):
    all_platforms(
        name = name,
        actual = actual,
    )
