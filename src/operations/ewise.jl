"""
    emul!(C::GBArray, A::GBArray, B::GBArray, op = BinaryOps.TIMES; kwargs...)::GBArray

Apply the binary operator `op` elementwise on the set intersection of `A` and `B`. Store or
accumulate the result into C. When `op = BinaryOps.TIMES` this is equivalent to `A .* B`,
however any binary operation may be substituted.

As mentioned the pattern of the result is the set intersection of `A` and `B`. For a set
union equivalent see [`eadd!`](@ref).

# Arguments
- `C::GBArray`: the output vector or matrix.
- `A::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `B::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `op::MonoidBinaryOrRig = BinaryOps.TIMES`: the binary operation which is applied such that
    `C[i,j] = op(A[i,j], B[i,j])` for all `i,j` present in both `A` and `B`.

# Keywords
- `mask::Union{Nothing, GBMatrix} = nothing`: optional mask.
- `accum::Union{Nothing, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc = nothing`
"""
function emul!(
    C::GBVecOrMat,
    A::GBArray,
    B::GBArray,
    op::MonoidBinaryOrRig = BinaryOps.TIMES;
    mask = nothing,
    accum = nothing,
    desc = nothing
)
    mask, accum = _handlenothings(mask, accum)
    desc = _handledescriptor(desc; in1=A, in2=B)
    size(C) == size(A) == size(B) || throw(DimensionMismatch())
    op = getoperator(op, optype(A, B))
    accum = getaccum(accum, eltype(C))
    if op isa TypedSemiring
        libgb.GrB_Matrix_eWiseMult_Semiring(C, mask, accum, op, parent(A), parent(B), desc)
        return C
    elseif op isa TypedMonoid
        libgb.GrB_Matrix_eWiseMult_Monoid(C, mask, accum, op, parent(A), parent(B), desc)
        return C
    elseif op isa TypedBinaryOperator
        libgb.GrB_Matrix_eWiseMult_BinaryOp(C, mask, accum, op, parent(A), parent(B), desc)
        return C
    else
        throw(ArgumentError("$op is not a valid monoid binary op or semiring."))
    end
    return C
end

"""
    emul(A::GBArray, B::GBArray, op = BinaryOps.TIMES; kwargs...)::GBMatrix

Apply the binary operator `op` elementwise on the set intersection of `A` and `B`. Store or
accumulate the result into C. When `op = BinaryOps.TIMES` this is equivalent to `A .* B`,
however any binary operation may be substituted.

As mentioned the pattern of the result is the set intersection of `A` and `B`. For a set
union equivalent see [`eadd`](@ref).

# Arguments
- `A::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `B::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `op::MonoidBinaryOrRig = BinaryOps.TIMES`: the binary operation which is applied such that
    `C[i,j] = op(A[i,j], B[i,j])` for all `i,j` present in both `A` and `B`.

# Keywords
- `mask::Union{Nothing, GBMatrix} = nothing`: optional mask.
- `accum::Union{Nothing, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc = nothing`

# Returns
- `GBArray`: Output `GBVector` or `GBMatrix` whose eltype is determined by the `eltype` of
    `A` and `B` or the binary operation if a type specific operation is provided.
"""
function emul(
    A::GBArray,
    B::GBArray,
    op::MonoidBinaryOrRig = BinaryOps.TIMES;
    mask = nothing,
    accum = nothing,
    desc = nothing
)
    t = inferoutputtype(A, B, op)
    if A isa GBVector && B isa GBVector
        C = GBVector{t}(size(A))
    else
        C = GBMatrix{t}(size(A))
    end
    return emul!(C, A, B, op; mask, accum, desc)
end

"""
    eadd!(C::GBArray, A::GBArray, B::GBArray, op = BinaryOps.PLUS; kwargs...)::GBArray

Apply the binary operator `op` elementwise on the set union of `A` and `B`. Store or
accumulate the result into C. When `op = BinaryOps.PLUS` this is equivalent to `A .+ B`,
however any binary operation may be substituted.

As mentioned the pattern of the result is the set union of `A` and `B`. For a set
intersection equivalent see [`emul!`](@ref).

# Arguments
- `C::GBArray`: the output vector or matrix.
- `A::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `B::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `op::MonoidBinaryOrRig = BinaryOps.PLUS`: the binary operation which is applied such that
    `C[i,j] = op(A[i,j], B[i,j])` for all `i,j` present in either `A` and/or `B`.

# Keywords
- `mask::Union{Nothing, GBMatrix} = nothing`: optional mask.
- `accum::Union{Nothing, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc = nothing`
"""
function eadd!(
    C::GBVecOrMat,
    A::GBArray,
    B::GBArray,
    op::MonoidBinaryOrRig = BinaryOps.PLUS;
    mask = nothing,
    accum = nothing,
    desc = nothing
)
    mask, accum = _handlenothings(mask, accum)
    desc = _handledescriptor(desc; in1=A, in2 = B)
    size(C) == size(A) == size(B) || throw(DimensionMismatch())
    op = getoperator(op, optype(A, B))
    accum = getaccum(accum, eltype(C))
    if op isa TypedSemiring
        libgb.GrB_Matrix_eWiseAdd_Semiring(C, mask, accum, op, parent(A), parent(B), desc)
        return C
    elseif op isa TypedMonoid
        libgb.GrB_Matrix_eWiseAdd_Monoid(C, mask, accum, op, parent(A), parent(B), desc)
        return C
    elseif op isa TypedBinaryOperator
        libgb.GrB_Matrix_eWiseAdd_BinaryOp(C, mask, accum, op, parent(A), parent(B), desc)
        return C
    else
        throw(ArgumentError("$op is not a valid monoid binary op or semiring."))
    end
    return C
end

"""
    eadd(A::GBArray, B::GBArray, op = BinaryOps.PLUS; kwargs...)::GBArray

Apply the binary operator `op` elementwise on the set union of `A` and `B`. Store or
accumulate the result into C. When `op = BinaryOps.TIMES` this is equivalent to `A .* B`,
however any binary operation may be substituted.

As mentioned the pattern of the result is the set union of `A` and `B`. For a set
intersection equivalent see [`emul`](@ref).

# Arguments
- `A::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `B::GBArray`: `GBVector` or optionally transposed `GBMatrix`.
- `op::MonoidBinaryOrRig = BinaryOps.PLUS`: the binary operation which is applied such that
    `C[i,j] = op(A[i,j], B[i,j])` for all `i,j` present in either `A` or `B`.

# Keywords
- `mask::Union{Nothing, GBMatrix} = nothing`: optional mask.
- `accum::Union{Nothing, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc = nothing`

# Returns
- `GBArray`: Output `GBVector` or `GBMatrix` whose eltype is determined by the `eltype` of
    `A` and `B` or the binary operation if a type specific operation is provided.
"""
function eadd(
    A::GBArray,
    B::GBArray,
    op::MonoidBinaryOrRig = BinaryOps.PLUS;
    mask = nothing,
    accum = nothing,
    desc = nothing
)
    t = inferoutputtype(A, B, op)
    if A isa GBVector && B isa GBVector
        C = GBVector{t}(size(A))
    else
        C = GBMatrix{t}(size(A))
    end
    return eadd!(C, A, B, op; mask, accum, desc)
end

function emul!(C, A, B, op::Function; mask = nothing, accum = nothing, desc = nothing)
    emul!(C, A, B, BinaryOp(op); mask, accum, desc)
end

function emul(A, B, op::Function; mask = nothing, accum = nothing, desc = nothing)
    emul(A, B, BinaryOp(op); mask, accum, desc)
end

function eadd!(C, A, B, op::Function; mask = nothing, accum = nothing, desc = nothing)
    eadd!(C, A, B, BinaryOp(op); mask, accum, desc)
end

function eadd(A, B, op::Function; mask = nothing, accum = nothing, desc = nothing)
    eadd(A, B, BinaryOp(op); mask, accum, desc)
end

function Base.:+(A::GBArray, B::GBArray)
    eadd(A, B, BinaryOps.PLUS)
end

function Base.:-(A::GBArray, B::GBArray)
    eadd(A, B, BinaryOps.MINUS)
end

⊕(A, B, op; mask = nothing, accum = nothing, desc = nothing) =
    eadd(A, B, op; mask, accum, desc)
⊗(A, B, op; mask = nothing, accum = nothing, desc = nothing) =
    emul(A, B, op; mask, accum, desc)

⊕(f::Union{Function, BinaryUnion}) = (A, B; mask = nothing, accum = nothing, desc = nothing) ->
    eadd(A, B, f; mask, accum, desc)

⊗(f::Union{Function, BinaryUnion}) = (A, B; mask = nothing, accum = nothing, desc = nothing) ->
    emul(A, B, f; mask, accum, desc)
