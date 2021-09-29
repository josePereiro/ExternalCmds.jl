# ---------------------------------------------------------------
_append(io::IO, x, xs...) = print(io, x, xs...)
_append(fn::AbstractString, x, xs...) = open((io) -> print(io, x, xs...), fn, "a")

_empty!(::IO) = nothing
_empty!(fn::AbstractString) = open((io) -> print(io, ""), fn, "w")

# ---------------------------------------------------------------
# take the content of a file and print it into a set of `ios`
function _tee_file(
    ios::Vector, file::AbstractString;
    finish_time::Ref{Float64}, lk::ReentrantLock,
    append = false, wt = 1.0
)

    # check
    isempty(ios) && return

    # empty
    !append && _empty!.(ios)

    # tee
    _lmtime = -1.0
    _lli = 1
    while (time() < finish_time[])
        
        # wait for news
        (mtime(file) != _lmtime) ? 
            _lmtime = mtime(file) : 
            (sleep(wt); continue)
            
        # read
        all_lines = readlines(file; keep = true)
        (length(all_lines) < _lli) && continue

        # print to ios
        lock(lk) do
            lines = all_lines[_lli:end]
            for io in ios
                _append(io, lines...)
            end
            _lli = lastindex(all_lines) + 1
        end
    end

    return nothing
end

# ---------------------------------------------------------------
function _try_getpid(proc)
    try; return getpid(proc)
        catch err
        (err isa Base.IOError) && return -1
        rethrow(err)
    end
end