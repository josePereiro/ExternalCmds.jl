using ExternalCmds
using Test

@testset "ExternalCmds.jl" begin
    
    if Sys.isunix()

        println()

        # ------------------------------------
        # run_cmd
        token = "TESTING_RUN_CMD"
        pid, out = run_cmd(`echo $(token)`)
        @test pid isa Integer
        @test contains(out, token)
        println()

        # ------------------------------------
        # tee_run
        stdout_log = tempname()
        rm(stdout_log; force = true)
        stderr_log = stdout_log
        for (token, long) in [
                ("TESTING_SHORT_RUN", false),
                ("TESTING_LONG_RUN", true),
            ]

            pid = tee_run(`echo $(token)`; 
                long,
                stdout_log, stderr_log, 
                stdout_tee_ios = [stdout], stderr_tee_ios = [], 
                savetime = 5.0,
            )
            @test pid isa Integer
            
            # wait for answer
            while true
                if isfile(stdout_log)
                    out = read(stdout_log, String)
                    if contains(out, token) 
                        @test true
                        break  
                    end
                end
                sleep(1.0)
            end
            println()
        end # for (token, long)

        # ------------------------------------
        token = "TESTING_RUN_BASH SINGLELINE"
        pid, out = run_bash("echo $(token)"; run_fun = run_cmd)
        @test pid isa Integer
        @test contains(out, token)
        println()

        token = "TESTING_RUN_BASH MULTILINE"
        buff_file = tempname()
        pid, out = run_bash(["echo $(token)"]; buff_file, run_fun = run_cmd, rm_buff = true)
        @test pid isa Integer
        @test contains(out, token)
        println()

        # ------------------------------------
        # clear
        rm(stdout_log; force = true)
        rm(buff_file; force = true)

    end # if Sys.isunix()

end
