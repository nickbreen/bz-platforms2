load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "tool_path")

def _impl(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        cxx_builtin_include_directories = ctx.attr.includes,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.target_cpu,
        target_libc = ctx.attr.target_libc,
        compiler = ctx.attr.compiler,
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        tool_paths = [
            tool_path(
                name = "gcc",
                path = ctx.attr.gcc,
            ),
            tool_path(
                name = "ld",
                path = ctx.attr.ld,
            ),
            tool_path(
                name = "ar",
                path = ctx.attr.ar,
            ),
            tool_path(
                name = "cpp",
                path = ctx.attr.cpp,
            ),
            tool_path(
                name = "gcov",
                path = ctx.attr.gcov,
            ),
            tool_path(
                name = "nm",
                path = ctx.attr.nm,
            ),
            tool_path(
                name = "objdump",
                path = ctx.attr.objdump,
            ),
            tool_path(
                name = "strip",
                path = ctx.attr.strip,
            ),
        ],
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "includes": attr.string_list(default = ["/usr/include"]),
        "toolchain_identifier": attr.string(mandatory = True),
        "compiler": attr.string(mandatory = True),
        "target_cpu": attr.string(default = "k8"),
        "target_system_name": attr.string(default = "linux-gnu"),
        "target_libc": attr.string(mandatory = True),
        "abi_version": attr.string(),
        "abi_libc_version": attr.string(),
        "gcc": attr.string(default = "/usr/bin/gcc"),
        "ld": attr.string(default = "/usr/bin/ld"),
        "ar": attr.string(default = "/usr/bin/ar"),
        "cpp": attr.string(default = "/usr/bin/cpp"),
        "gcov": attr.string(default = "/usr/bin/gcov"),
        "nm": attr.string(default = "/usr/bin/nm"),
        "objdump": attr.string(default = "/usr/bin/objdump"),
        "strip": attr.string(default = "/usr/bin/strip"),
    },
    provides = [CcToolchainConfigInfo],
)
