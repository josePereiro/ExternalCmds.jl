# ---------------------------------------------------------------
# take the content of a `file` and print it into a set of `ios`
function tee_file(ios::Vector, file::AbstractString;
        print_fun = print,
        finish_time::Ref{Float64} = Ref{Float64}(time() + 1e20),
        buffsize = 150,
        upfrec = 1.0,
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
            while eof(fileio) # will wait at the end of the file
                if (bi > 0) # will print any new content
                    str = join(buff[1:bi])
                    lock(printlk) do
                        for io in ios
                            print_fun(io, str)
                        end
                    end
                    bi = 0
                end
                (time() > finish_time[]) && return # time out
                sleep(upfrec)
            end

            ch = read(fileio, Char)
            bi += 1
            buff[bi] = ch
            if (bi == buffsize) # will print the whole buff
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