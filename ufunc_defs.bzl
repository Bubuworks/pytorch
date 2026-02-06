load("@bazel_skylib//lib:paths.bzl", "paths")
load(":build_variables.bzl", "aten_ufunc_headers")

aten_ufunc_names = [paths.split_extension(paths.basename(h))[0] for h in aten_ufunc_headers]

def _aten_ufunc_generated_sources(prefix, extension, gencode_pattern="{}"):
    """Generate ufunc source file names with optional gencode pattern."""
    files = ["{}{}_{}".format(prefix, "", n) + extension for n in aten_ufunc_names]
    return [gencode_pattern.format(f) for f in files]

def aten_ufunc_generated_cpu_sources(gencode_pattern="{}"):
    return _aten_ufunc_generated_sources("UfuncCPU_", ".cpp", gencode_pattern)

def aten_ufunc_generated_cpu_kernel_sources(gencode_pattern="{}"):
    return _aten_ufunc_generated_sources("UfuncCPUKernel_", ".cpp", gencode_pattern)

def aten_ufunc_generated_cuda_sources(gencode_pattern="{}"):
    return _aten_ufunc_generated_sources("UfuncCUDA_", ".cu", gencode_pattern)
