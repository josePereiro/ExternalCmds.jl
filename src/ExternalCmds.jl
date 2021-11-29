module ExternalCmds

    include("utils.jl")
    include("tee_file.jl")
    include("run.jl")

    export run_cmd, tee_run, run_bash

end

