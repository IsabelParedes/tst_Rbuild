
## Start of bash preamble
if [ -z ${CONDA_BUILD+x} ]; then
    source /home/ihuicatl/Repos/Packaging/emscripten-forge-recipes/output/bld/rattler-build_r-base_1724847472/work/build_env.sh
fi
# enable debug mode for the rest of the script
set -x
## End of preamble

#!/bin/bash

set -e

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
# micromamba install -p $BUILD_PREFIX \
#     conda-forge/label/llvm_rc::libllvm19=19.1.0.rc2 \
#     conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
#     -y --no-channel-priority
# rm $BUILD_PREFIX/bin/clang # links to clang19
# ln -s $BUILD_PREFIX/bin/clang-18 $BUILD_PREFIX/bin/clang # links to emsdk clang

# # NOTE: Taking the runtime lib from wasi to pass some of the fortran tests
# mkdir -p $BUILD_PREFIX/lib/clang/19/lib/wasm32-unknown-emscripten/
# cp libclang_rt.builtins-wasm32.a $BUILD_PREFIX/lib/clang/19/lib/wasm32-unknown-emscripten/libclang_rt.builtins.a

# NOTE: a few of these tests check for specific symbols in the libraries,
# however the objdump tool is not set up to handle wasm files.
# Maybe this is why the checks fail.

# Skip non-working checks
export r_cv_header_zlib_h=yes
export r_cv_have_bzlib=yes
export r_cv_have_lzma=yes
export r_cv_have_pcre2utf=yes
export r_cv_size_max=yes


# Not supported
export ac_cv_have_decl_getrusage=no
export ac_cv_have_decl_getrlimit=no
export ac_cv_have_decl_sigaltstack=no
export ac_cv_have_decl_wcsftime=no
export ac_cv_have_decl_umask=no



# Otherwise set to .not_implemented and cannot be used
# Must be shared... otherwise duplicate symbol issues
export SHLIB_EXT=".so"

# NOTE: the host and build systems are explicitly set to enable the cross-
# compiling options even though it's not actually supported.
# Otherwise, it assumes it's not cross-compiling. REQUIRED!!!

cd _build
echo "😈😈😈 Configuring R"

emconfigure ../configure \
    --prefix=$PREFIX    \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --with-sysroot=$BUILD_PREFIX/opt/emsdk/upstream/emscripten/cache/sysroot \
    --enable-R-static-lib \
    --enable-BLAS-shlib \
    --with-cairo \
    --without-readline  \
    --without-x         \
    --enable-static  \
    --enable-java=no \
    --enable-R-profiling=no \
    --enable-byte-compiled-packages=no \
    --disable-rpath \
    --disable-openmp \
    --with-internal-tzcode \
    --with-recommended-packages=no \
    --with-libdeflate-compression=no


echo "😈😈😈 Building R"
emmake make clean
emmake make -j${CPU_COUNT}
# emmake make install

# # NOTE: bin/R is a shell wrapper for the R binary (found in lib/R/bin/exec/R)
# # Manually copying the R.wasm file
# cp src/main/R.* $PREFIX/lib/R/bin/exec/

# # and Rscript (also has shell wrapper)
# cp src/unix/Rscript.wasm $PREFIX/lib/R/bin/
