# ---------------------------------------------------------------
_append(io::IO, x, xs...) = print(io, x, xs...)
_append(fn::AbstractString, x, xs...) = open((io) -> print(io, x, xs...), fn, "a")

_empty!(::IO) = nothing
_empty!(fn::AbstractString) = open((io) -> print(io, ""), fn, "w")

# ---------------------------------------------------------------
# take the content of a file and print it into a set of `ios`
function tee_file(ios::Vector, file::AbstractString;
        print_fun = print,
        finish_time::Ref{Float64} = Ref{Float64}(time() + 1e20),
        buffsize = 150,
        wtime = 1.0,
        printlk::ReentrantLock = ReentrantLock(),
        append = false
    )

    # check
    isempty(ios) && return

    # empty
    !append && _empty!.(ios)

    buff = Vector{Char}(undef, buffsize)
    bi = 0
    open(file, "r") do fileio
        while true
            while eof(fileio)
                if (bi > 0)
                    str = join(buff[1:bi])
                    lock(printlk) do
                        for io in ios
                            print_fun(io, str)
                        end
                    end
                    bi = 0
                end
                (time() > finish_time[]) && return
                sleep(wtime)
            end

            ch = read(fileio, Char)
            bi += 1
            buff[bi] = ch
            if (bi == buffsize)
                str = join(buff)
                lock(printlk) do
                    for io in ios
                        print_fun(io, str)
                    end
                end
                bi = 0
            end
        end
    end
end


# ---------------------------------------------------------------
function _try_getpid(proc)
    try; return getpid(proc)
        catch err
        (err isa Base.IOError) && return -1
        rethrow(err)
    end
end