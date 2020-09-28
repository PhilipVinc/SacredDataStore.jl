struct NetketJsonDataType <: LazyDataType end

function _lazyload(m::MetricsData, ::NetketJsonDataType)
    m.loaded && return m

    path = m.path
    data_json = JSON.parse(read(path, String))["Output"]

    for iter_data in data_json
        ks = keys(iter_data)
        step = iter_data["Iteration"]

        for k in ks
            k == "Iteration" && continue
            data = iter_data[k]

            if data isa Dict
                expval = data["Mean"] ± data["Sigma"]
                variance = data["Variance"]
                rhat = data["R_hat"]
                taucorr = data["TauCorr"]

                push!(m.data, Symbol(k), step, expval)
                push!(m.data, Symbol(k*"_var"), step, variance)
                push!(m.data, Symbol(k*"_rhat"), step, rhat)
                push!(m.data, Symbol(k*"_tau"), step, taucorr)
            else
                val = data
                push!(m.data, Symbol(k), step, data)
            end
        end
    end

    m.loaded = true
    return m
end
