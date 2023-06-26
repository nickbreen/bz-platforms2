load("@rules_pkg//pkg:providers.bzl", "PackageArtifactInfo")

def _all_platforms_transition(settings, attr):
    # explode the build graph, possibly catastrophically for all our target platforms
    if "//platforms/family:debian" in attr.target_compatible_with or "//platforms/family:debian" in attr.exec_compatible_with:
        return {
            "debian/11": {"//command_line_option:platforms": "//platforms:debian/11"},
            "debian/12": {"//command_line_option:platforms": "//platforms:debian/12"},
            "ubuntu/kinetic": {"//command_line_option:platforms": "//platforms:ubuntu/kinetic"},
            "ubuntu/lunar": {"//command_line_option:platforms": "//platforms:ubuntu/lunar"},
        }
    elif "//platforms/family:redhat" in attr.target_compatible_with or "//platforms/family:redhat" in attr.exec_compatible_with:
        return {
            "centos/6": {"//command_line_option:platforms": "//platforms:centos/6"},
            "centos/7": {"//command_line_option:platforms": "//platforms:centos/7"},
            "fedora/37": {"//command_line_option:platforms": "//platforms:fedora/37"},
            "fedora/38": {"//command_line_option:platforms": "//platforms:fedora/38"},
            "rockylinux/8": {"//command_line_option:platforms": "//platforms:rockylinux/8"},
            "rockylinux/9": {"//command_line_option:platforms": "//platforms:rockylinux/9"},
        }
    else:
        return {
            "centos/6": {"//command_line_option:platforms": "//platforms:centos/6"},
            "centos/7": {"//command_line_option:platforms": "//platforms:centos/7"},
            "debian/11": {"//command_line_option:platforms": "//platforms:debian/11"},
            "debian/12": {"//command_line_option:platforms": "//platforms:debian/12"},
            "fedora/37": {"//command_line_option:platforms": "//platforms:fedora/37"},
            "fedora/38": {"//command_line_option:platforms": "//platforms:fedora/38"},
            "rockylinux/8": {"//command_line_option:platforms": "//platforms:rockylinux/8"},
            "rockylinux/9": {"//command_line_option:platforms": "//platforms:rockylinux/9"},
            "ubuntu/kinetic": {"//command_line_option:platforms": "//platforms:ubuntu/kinetic"},
            "ubuntu/lunar": {"//command_line_option:platforms": "//platforms:ubuntu/lunar"},
        }

all_platforms_transition = transition(
    implementation = _all_platforms_transition,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
    ],
)

def _all_platforms(ctx):
    outs = []
    for subdir_name in ctx.split_attr.actual:
        subdir = ctx.actions.declare_directory(subdir_name)
        ctx.actions.run(outputs = [subdir], executable = "mkdir", arguments = ["-vp", subdir.path])
        outs += [subdir]
        for file_name in ctx.split_attr.actual[subdir_name].files.to_list():
            file = ctx.actions.declare_file(file_name.path, sibling = subdir)
            ctx.actions.run(outputs = [file], inputs = [file_name], executable = "cp", arguments = ["-v", file_name.path, file.path])
            outs += [file]

    return [DefaultInfo(files = depset(outs))]

all_platforms = rule(
    implementation = _all_platforms,
    attrs = {
        "actual": attr.label(mandatory = True, cfg = all_platforms_transition, providers = [PackageArtifactInfo]),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def platforms(name, actual, **kwargs):
    all_platforms(
        name = name,
        actual = actual,
    )
