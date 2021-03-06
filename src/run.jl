# ---------------------------------------------------------------
function run_cmd(cmd::Cmd; ios = [stdout], detach = false)

    # run
    _out = Pipe()
    cmd = pipeline(Cmd(cmd; detach), stdout = _out, stderr = _out)
    proc = run(cmd, wait = false)
    pid = _try_getpid(proc)
    wait(proc)
    
    # out
    close(_out.in)
    out = read(_out, String)
    
    # print
    for io in ios
        _append(io, out)
    end

    return (;pid, out)
end

# ---------------------------------------------------------------
function _short_run(cmd::Cmd;
        stdout_log::AbstractString = tempname(), stderr_log::AbstractString = tempname(),
        stdout_tee_ios = [stdout], stderr_tee_ios = [stderr],
        append = false, 
        kwargs... # to ignore foreing kwargs
    )

    # empty
    !append && _empty!.([stderr_log, stdout_log])
    
    # run
    cmd = pipeline(cmd, stdout=stdout_log, stderr=stderr_log; append)
    proc = run(cmd; wait = false)
    pid = _try_getpid(proc)
    wait(proc)

    # tee
    for (logfile, ios) in [
            (stdout_log, stdout_tee_ios), 
            (stderr_log, stderr_tee_ios)
        ]
        for io in ios
            !append && _empty!(io)
            _append(io, read(logfile, String))
        end
    end

    return pid
end

# ---------------------------------------------------------------
function _long_run(cmd::Cmd; 
        stderr_log = tempname(), stdout_log = tempname(), 
        stdout_tee_ios = [stdout], stderr_tee_ios = [stderr],  
        printlk = ReentrantLock(), timeout = time() + 1e9,
        savetime = 60.0, # To wait for flushing
        append = false, 
        upfrec = 1.0,
        finish_time = Ref{Float64}(time() + timeout), # define tee tout
        kwargs... # to ignore foreing kwargs
    )

    # empty
    !append && _empty!.([stderr_log, stdout_log])

    @sync begin

        proc = run(pipeline(cmd, stdout=stdout_log, stderr=stderr_log; append), wait=false)
        pid = _try_getpid(proc)

        # tee
        stdout_tsk = @async tee_file(stdout_tee_ios, stdout_log; finish_time, printlk, upfrec)
        stderr_tsk = @async tee_file(stderr_tee_ios, stderr_log; finish_time, printlk, upfrec)

        # ending
        wait(proc)
        finish_time[] = time() + savetime
        wait(stdout_tsk)
        wait(stderr_tsk)
        
        return pid
    end

end

# ---------------------------------------------------------------
function tee_run(cmd::Cmd; long::Bool = false, runkwargs...)
    long ? _long_run(cmd; runkwargs...) : _short_run(cmd; runkwargs...)
end

# ---------------------------------------------------------------
function run_bash(
        src_lines::Vector{String};
        startup::Vector{String} = String[],
        buff_file = tempname(),
        run_fun = run_cmd,
        rm_buff = true,
        runkwargs...
    )

    touch(buff_file)
    chmod(buff_file, 0o755)

    src = join(filter(!isempty, [
        startup; 
        rm_buff ? """rm -f '$(buff_file)';""" : ""; 
        src_lines
    ]), "\n")

    write(buff_file, src)

    run_fun(`bash -c $(buff_file)`; runkwargs...)
end

run_bash(src::String; run_fun = run_cmd, runkwargs...) = run_fun(Cmd(`bash -c $(src)`); runkwargs...)