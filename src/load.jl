export sacred_load

function absolute_path(path::String)
    if first(path) == '/'
        return path
    else
        return joinpath(pwd(), path)
    end
end

function sacred_load(depot_path)

    depot_path = absolute_path(depot_path)
    depot_entries = readdir(depot_path, join=true)

    df = DataFrame(:name=>Vector{Union{String,Missing}}(),
                   :id=>Vector{Union{Missing, Int}}())

    for entry_path in depot_entries
        first(basename(entry_path)) == '_' && continue
        first(basename(entry_path)) == '.' && continue

        #@info "parsing " id=basename(entry_path)

        el_files = readdir(entry_path)

        el_json = JSON3.read(read(joinpath(entry_path, "run.json"), String))
        config_json = JSON3.read(read(joinpath(entry_path, "config.json"), String))
        experiment = el_json[:experiment]

        push!(df)
        row = nrow(df)

        # Experiment
        setcol!(df, row, :name, experiment[:name])
        setcol!(df, row, :id, parse(Int, basename(entry_path)))
        setcol!(df, row, :status, el_json.status)
        if el_json.status == "RUNNING"
            t = el_json.heartbeat
            cut = findlast('.', t)
            dt = now() - DateTime(t[begin:cut-1], "y-m-dTH:M:S")
            if dt >= Day(5)
                setcol!(df, row, :status, "FAILED $(floor(dt, Day(1)))")
            elseif dt >= Hour(8)
                setcol!(df, row, :status, "RUNNING/FAILED $(floor(dt, Hour(1)))")
            else
                setcol!(df, row, :status, "RUNNING")
            end
        end
        setcol!(df, row, :path, entry_path)

        ks = keys(config_json)
        for k in ks
            setcol!(df, row, k, config_json[k])
        end

        # Sources
        sources_list = experiment[:sources]
        sources = Vector{String}()
        for (source_orig, source_stored) in sources_list
            push!(sources, joinpath(depot_path, source_stored))
        end
        setcol!(df, row, :sources, sources)

        # Metrics stuff
        metrics = MetricsData(joinpath(entry_path, "metrics.json"), MetricsDataType())
        setcol!(df, row, :metrics, metrics)

        # Artifacts stuff
        artifacts = el_json[:artifacts]
        artifacts_paths = Vector{Any}()
        for artifact in artifacts
            path = joinpath(entry_path, artifact)
            push!(artifacts_paths, path)

            if endswith(path, ".log")
                # convert to jsonlog netket
                nklog = MetricsData(path, NetketJsonDataType())
                setcol!(df, row, :nklog, nklog)
            end
        end
        setcol!(df, row, :artifacts, artifacts_paths)
    end

    return df
end
