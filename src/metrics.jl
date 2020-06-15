using ValueHistories
using JSON
using MacroTools

struct MetricsData
    path::String
    loaded::Bool

    data::MVHistory{History}
end

MetricsData(path::String) = MetricsData(path, false, MVHistory())

Base.keys(m::MetricsData) = keys(lazyload(m).data)
Base.getindex(m::MetricsData, args...) = getindex(lazyload(m).data, args...)
Base.getindex(m::MetricsData, arg::String) = getindex(lazyload(m).data, Symbol(arg))
Base.length(m::MetricsData) = length(lazyload(m).data.iterations)
Base.enumerate(m::MetricsData) = zip(lazyload(m).data.iterations, lazyload(m).data.values)
Base.get(m::MetricsData) = lazyload(m).data.iterations, lazyload(m).data.values

function lazyload(m::MetricsData)
    m.loaded && return m

    path = m.path
    metrics_json = JSON.parse(read(path, String))

    ks = collect(keys(metrics_json))
    for k in ks
        data = metrics_json[k]
        vals = data["values"] .|> Float64
        steps = data["steps"]      .|> Int

        i=-1
        if endswith(k, "/re")
            k2 = k[begin:end-3]*"/im"
            i = findfirst(ks .== k2)

            vals_im = metrics_json[k2]["values"] .|> Float64
            vals = vals + im* vals_im
            deleteat!(ks, i)

        elseif endswith(k, "/im")
            k2 = k[begin:end-3]*"/re"
            i = findfirst(ks .== k2)

            vals_re = metrics_json[k2]["values"] .|> Float64
            vals = vals_re + im* vals
            deleteat!(ks, i)
        end

        _hist = History(eltype(vals))
        _hist.iterations = steps
        _hist.values = vals

        m.data.storage[Symbol(k)] = _hist
    end

    m.loaded = true
    return m
end
