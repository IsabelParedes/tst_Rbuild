
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

# NOTE: a few of these tests check for specific symbols in the libraries,
# however the objdump tool is not set up to handle wasm files.
# Maybe this is why the checks fail.

# Skip non-working checks
export r_cv_header_zlib_h=yes # Otherwise the version check fails
export r_cv_have_bzlib=yes
export ac_cv_lib_lzma_lzma_version_number=yes
export ac_cv_header_lzma_h=yes
export r_cv_have_lzma=yes
export r_cv_have_pcre2utf=yes
export r_cv_have_pcre832=yes
export r_cv_size_max=yes
export ac_cv_lib_z_inflateInit2_=yes
export ac_cv_lib_bz2_BZ2_bzlibVersion=yes

# Not supported
export ac_cv_have_decl_getrusage=no
export ac_cv_have_decl_getrlimit=no
export ac_cv_have_decl_sigaltstack=no
export ac_cv_have_decl_wcsftime=no
export ac_cv_have_decl_umask=no

# Otherwise set to .not_implemented and cannot be used
# Must be shared... otherwise duplicate symbol issues
export SHLIB_EXT=".so"

# NOTE: These flags are saved in etc/Makeconf and are passed down to any other
# R packages built with the R binary/shell wrapper.

# NOTE: The pre.js only gets added to the Rscript binary and not the R binary
#   MAIN_CFLAGS:   additional CFLAGS used when compiling the main binary
export MAIN_CFLAGS="-sMAIN_MODULE --pre-js ${RECIPE_DIR}/pre.js"
#   SHLIB_CFLAGS:  additional CFLAGS used when building shared objects
export SHLIB_CFLAGS="-sSIDE_MODULE"
#   MAIN_FFLAGS:   additional FFLAGS used when compiling the main binary
#   SHLIB_FFLAGS:  additional FFLAGS used when building shared objects
#   MAIN_LD:       command used to link the main binary
#   MAIN_LDFLAGS:  flags which are necessary for loading a main program which
#                  will load shared objects (DLLs) at runtime
#   CPICFLAGS:     special flags for compiling C code to be turned into a shared
#                  object.
#   FPICFLAGS:     special flags for compiling Fortran code to be turned into a
#                  shared object.
#   SHLIB_LD:      command for linking shared objects which contain object files
#                  from a C or Fortran compiler only

#   SHLIB_LDFLAGS: special flags used by SHLIB_LD
export SHLIB_LDFLAGS="-sSIDE_MODULE"
#   DYLIB_LD:      command for linking dynamic libraries which contain object files
#                  from a C or Fortran compiler only
#   DYLIB_LDFLAGS: special flags used for make a dynamic library
export DYLIB_LDFLAGS="-sSIDE_MODULE"
#   CXXPICFLAGS:   special flags for compiling C++ code to be turned into a shared
#                  object
#   SHLIB_CXXLD:   command for linking shared objects which contain object files
#                  from the C++ compiler
#   SHLIB_CXXLDFLAGS: special flags used by SHLIB_CXXLD
#   TCLTK_LIBS:    flags needed for linking against the Tcl and Tk libraries
#   TCLTK_CPPFLAGS: flags needed for finding the tcl.h and tk.h headers
#   MAKE        make command
#   TAR         tar command
#   R_BROWSER   default browser
#   R_PDFVIEWER default PDF viewer
#   BLAS_LIBS   flags needed for linking against external BLAS libraries
#   LAPACK_LIBS flags needed for linking against external LAPACK libraries
#   LIBnn       'lib' or 'lib64' for dynamic libraries
#   SAFE_FFLAGS Safe Fortran fixed-form compiler flags for e.g. dlamc.f
#   r_arch      Use architecture-dependent subdirs with this name
#   DEFS        C defines for use when compiling R
#   JAVA_HOME   Path to the root of the Java environment
#   R_SHELL     shell to be used for shell scripts, including 'R'
#   YACC        The 'Yet Another Compiler Compiler' implementation to use.
#               Defaults to the first program found out of: 'bison -y', 'byacc',
#               'yacc'.
#   YFLAGS      The list of arguments that will be passed by default to $YACC.
#               This script will default YFLAGS to the empty string to avoid a
#               default value of '-d' given by some make applications.
#   PKG_CONFIG  path to pkg-config (or pkgconf) utility
export PKG_CONFIG=${BUILD_PREFIX}/bin/pkg-config
#   PKG_CONFIG_PATH directories to add to pkg-config's search path
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
#   PKG_CONFIG_LIBDIR path overriding pkg-config's default search path
export PKG_CONFIG_LIBDIR=$PREFIX/lib
#   CC          C compiler command
#   CFLAGS      C compiler flags
# NOTE: The context.c file needs these features
export CFLAGS="$CFLAGS -matomics -mbulk-memory"
#   LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries in a
#               nonstandard directory <lib dir>
# https://emscripten.org/docs/tools_reference/settings_reference.html
export LDFLAGS="-L$PREFIX/lib \
    -s WASM_BIGINT \
    -s STACK_SIZE=5MB \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s EXPORTED_RUNTIME_METHODS=callMain,FS,ENV,getEnvStrings,TTY \
    -s FORCE_FILESYSTEM=1 \
    -s INVOKE_RUN=0 \
    -s MODULARIZE=1"
#   LIBS        libraries to pass to the linker, e.g. -l<library>
export LIBS="-lFortranRuntime" # NOTE: Needed for external blas and lapack
#   CPPFLAGS    (Objective) C/C++ preprocessor flags, e.g. -I<include dir> if
#               you have headers in a nonstandard directory <include dir>
export CPPFLAGS="-I$PREFIX/include" # Otherwise can't find zlib.h
#   CPP         C preprocessor
#   FC          Fortran compiler command
export FC=flang-new
#   FCFLAGS     Fortran compiler flags
export FCFLAGS="$FFLAGS --target=wasm32-unknown-emscripten"
#   CXX         C++ compiler command
#   CXXFLAGS    C++ compiler flags
#   CXXCPP      C++ preprocessor
#   OBJC        Objective C compiler command
#   OBJCFLAGS   Objective C compiler flags
#   LT_SYS_LIBRARY_PATH
#               User-defined run-time library search path.
#   CXX11       C++11 compiler command
#   CXX11STD    special flag for compiling and for linking C++11 code, e.g.
#               -std=c++11
#   CXX11FLAGS  C++11 compiler flags
#   CXX11PICFLAGS
#               special flags for compiling C++11 code to be turned into a
#               shared object
#   SHLIB_CXX11LD
#               command for linking shared objects which contain object files
#               from the C++11 compiler
#   SHLIB_CXX11LDFLAGS
#               special flags used by SHLIB_CXX11LD
#   CXX14       C++14 compiler command
#   CXX14STD    special flag for compiling and for linking C++14 code, e.g.
#               -std=c++14
#   CXX14FLAGS  C++14 compiler flags
#   CXX14PICFLAGS
#               special flags for compiling C++14 code to be turned into a
#               shared object
#   SHLIB_CXX14LD
#               command for linking shared objects which contain object files
#               from the C++14 compiler
#   SHLIB_CXX14LDFLAGS
#               special flags used by SHLIB_CXX14LD
#   CXX17       C++17 compiler command
#   CXX17STD    special flag for compiling and for linking C++17 code, e.g.
#               -std=c++17
#   CXX17FLAGS  C++17 compiler flags
#   CXX17PICFLAGS
#               special flags for compiling C++17 code to be turned into a
#               shared object
#   SHLIB_CXX17LD
#               command for linking shared objects which contain object files
#               from the C++17 compiler
#   SHLIB_CXX17LDFLAGS
#               special flags used by SHLIB_CXX17LD
#   CXX20       C++20 compiler command
#   CXX20STD    special flag for compiling and for linking C++20 code, e.g.
#               -std=c++20
#   CXX20FLAGS  C++20 compiler flags
#   CXX20PICFLAGS
#               special flags for compiling C++20 code to be turned into a
#               shared object
#   SHLIB_CXX20LD
#               command for linking shared objects which contain object files
#               from the C++20 compiler
#   SHLIB_CXX20LDFLAGS
#               special flags used by SHLIB_CXX20LD
#   CXX23       C++23 compiler command
#   CXX23STD    special flag for compiling and for linking C++23 code, e.g.
#               -std=c++23
#   CXX23FLAGS  C++23 compiler flags
#   CXX23PICFLAGS
#               special flags for compiling C++23 code to be turned into a
#               shared object
#   SHLIB_CXX23LD
#               command for linking shared objects which contain object files
#               from the C++23 compiler
#   SHLIB_CXX23LDFLAGS
#               special flags used by SHLIB_CXX23LD
#   XMKMF       Path to xmkmf, Makefile generator for X Window System

# NOTE: `--enable-R-shlib` generates libR.so BUT this causes an issue with
# libRblas.so: undefined symbol: _FortranACharacterCompareScalar1

# NOTE: the host and build systems are explicitly set to enable the cross-
# compiling options even though it's not actually supported.
# Otherwise, it assumes it's not cross-compiling. REQUIRED!!!

emconfigure ./configure \
    --prefix=$PREFIX    \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --enable-R-static-lib \
    --enable-BLAS-shlib=no \
    --with-cairo \
    --without-readline  \
    --without-x         \
    --enable-static  \
    --enable-java=no \
    --enable-R-profiling=no \
    --enable-byte-compiled-packages=no \
    --disable-rpath \
    --with-internal-tzcode \
    --with-recommended-packages=no \
    --with-libdeflate-compression=no

emmake make clean
emmake make -j${CPU_COUNT}
emmake make install

# NOTE: bin/R is a shell wrapper for the R binary (found in lib/R/bin/exec/R)
# Manually copying the R.wasm file
cp src/main/R.* $PREFIX/lib/R/bin/exec/

# and Rscript (also has shell wrapper)
cp src/unix/Rscript.wasm $PREFIX/lib/R/bin/
