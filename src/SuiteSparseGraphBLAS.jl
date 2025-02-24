module SuiteSparseGraphBLAS
__precompile__(true)

using Libdl: dlsym, dlopen, dlclose

# Allow users to specify a non-Artifact shared lib.
using Preferences
include("find_binary.jl")
const libgraphblas_handle = Ref{Ptr{Nothing}}()
@static if artifact_or_path == "default"
    using SSGraphBLAS_jll
    const libgraphblas = SSGraphBLAS_jll.libgraphblas
else
    const libgraphblas = artifact_or_path
end

using SparseArrays
using SparseArrays: nonzeroinds
using MacroTools
using LinearAlgebra
using Random: randsubseq, default_rng, AbstractRNG, GLOBAL_RNG
using CEnum
using SpecialFunctions: lgamma, gamma, erf, erfc
using Base.Broadcast
include("abstracts.jl")
include("libutils.jl")
include("lib/LibGraphBLAS.jl")
using .libgb
include("operators/libgbops.jl")
include("types.jl")
include("gbtypes.jl")


include("operators/operatorutils.jl")
include("operators/unaryops.jl")
include("operators/binaryops.jl")
include("operators/monoids.jl")
include("operators/semirings.jl")
include("operators/selectops.jl")
include("descriptors.jl")
using .UnaryOps
using .BinaryOps
using .Monoids
using .Semirings

# Create typed operators
_createunaryops()
_createbinaryops()
_createmonoids()
_createsemirings()

include("operators/oplist.jl")
include("indexutils.jl")

# Globals
include("constants.jl")

include("scalar.jl")
include("vector.jl")
include("matrix.jl")
include("random.jl")

include("operations/operationutils.jl")
include("operations/transpose.jl")
include("operations/mul.jl")
include("operations/ewise.jl")
include("operations/map.jl")
include("operations/select.jl")
include("operations/reduce.jl")
include("operations/kronecker.jl")
include("operations/concat.jl")
include("operations/resize.jl")

include("print.jl")
include("import.jl")
include("export.jl")
include("options.jl")
#EXPERIMENTAL
include("operations/argminmax.jl")
include("operations/broadcasts.jl")
include("chainrules/chainruleutils.jl")
include("chainrules/mulrules.jl")
include("chainrules/ewiserules.jl")
include("chainrules/maprules.jl")
include("chainrules/reducerules.jl")
include("chainrules/selectrules.jl")
include("chainrules/constructorrules.jl")
#include("random.jl")
include("misc.jl")
export libgb
export UnaryOps, BinaryOps, Monoids, Semirings #Submodules
export UnaryOp, BinaryOp, Monoid, Semiring #UDFs
export Descriptor #Types
export xtype, ytype, ztype, validtypes #Determine input/output types of operators
export GBScalar, GBVector, GBMatrix #arrays
export lgamma, gamma, erf, erfc #reexport of SpecialFunctions.

# Function arguments not found elsewhere in Julia
#UnaryOps not found in Julia/stdlibs.
export frexpe, frexpx, positioni, positionj
#BinaryOps not found in Julia/stdlibs.
export second, rminus, pair, ∨, ∧, lxor, fmod, firsti,
    firstj, secondi, secondj
#SelectOps not found in Julia/stdlibs
export offdiag

export clear!, extract, extract!, subassign!, assign!, hvcat! #array functions

#operations
export mul, select, select!, eadd, eadd!, emul, emul!, map, map!, gbtranspose, gbtranspose!,
gbrand
# Reexports from LinAlg
export diag, diagm, mul!, kron, kron!, transpose, reduce, tril, triu

# Reexports from SparseArrays
export nnz, sprand, findnz, nonzeros, nonzeroinds

function __init__()
    @static if artifact_or_path != "default"
        libgraphblas_handle[] = dlopen(libgraphblas)
    else
        #The artifact does dlopen for us.
        libgraphblas_handle[] = SSGraphBLAS_jll.libgraphblas_handle
    end
    _load_globaltypes()
    # We initialize GraphBLAS by giving it Julia's GC wrapped memory management functions.
    # In the future this should hopefully allow us to do no-copy passing of arrays between Julia and SS:GrB.
    # In the meantime it helps Julia respond to memory pressure from SS:GrB and finalize things in a timely fashion.
    libgb.GxB_init(libgb.GrB_NONBLOCKING, cglobal(:jl_malloc), cglobal(:jl_calloc), cglobal(:jl_realloc), cglobal(:jl_free), true)
    # Eagerly load selectops constants.
    _loadselectops()
    # Set printing done by SuiteSparse:GraphBLAS to base-1 rather than base-0.
    gbset(BASE1, 1)
    atexit() do
        # Finalize the lib, for now only frees a small internal memory pool.
        libgb.GrB_finalize()
        @static if artifact_or_path != "default"
            dlclose(libgraphblas_handle[])
        end
    end
end

include("operators/ztypes.jl")
end #end of module
