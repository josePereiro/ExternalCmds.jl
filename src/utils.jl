# ---------------------------------------------------------------
_append(io::IO, x, xs...) = print(io, x, xs...)
_append(fn::AbstractString, x, xs...) = open((io) -> print(io, x, xs...), fn, "a")

_empty!(::IO) = nothing
_empty!(fn::AbstractString) = open((io) -> print(io, ""), fn, "w")

# ---------------------------------------------------------------
function _try_getpid(proc)
    try; return getpid(proc)
        catch err
        (err isa Base.IOError) && return -1
        rethrow(err)
    end
end