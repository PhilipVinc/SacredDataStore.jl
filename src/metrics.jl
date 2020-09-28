abstract type LazyDataType end
struct MetricsDataType <: LazyDataType end

mutable struct MetricsData
    path::String
    loaded::Bool
    datatype::LazyDataType

    data::MVHistory{History}
end

MetricsData(path::String, type::Type{T}) where T<:LazyDataType =
    MetricsData(path, T())
MetricsData(path::String, type::LazyDataType=MetricsDataType()) =
    MetricsData(path, false, type, MVHistory())

Base.keys(m::MetricsData) = keys(lazyload(m).data)
Base.getindex(m::MetricsData, args...) = getindex(lazyload(m).data, args...)
Base.getindex(m::MetricsData, arg::String) = getindex(lazyload(m).data, Symbol(arg))
Base.length(m::MetricsData) = length(lazyload(m).data.iterations)
Base.enumerate(m::MetricsData) = zip(lazyload(m).data.iterations, lazyload(m).data.values)
Base.get(m::MetricsData) = lazyload(m).data.iterations, lazyload(m).data.values

lazyload(m::MetricsData) = _lazyload(m, m.datatype)

function _lazyload(m::MetricsData, ::MetricsDataType)
    m.loaded && return m

    path = m.path
    metrics_json = JSON.parse(read(path, String))

    ks = collect(keys(metrics_json))

    has_time = "t" ∈ ks 
    if has_time
        deleteat!(ks, findfirst(ks .== "t"))
        time_steps_iters = Int.(metrics_json["t"]["steps"])
        time_steps = Float64.(metrics_json["t"]["values"])
    end

    for k in ks
        data = metrics_json[k]
        vals = data["values"] .|> Float64
        steps = data["steps"] .|> Int
        if has_time
            if length(steps) == length(time_steps) - 1
                pushfirst!(vals, first(vals))
            end
            steps = time_steps
        end
        
        i=-1
        if endswith(k, "/re")
            k2 = k[begin:end-3]*"/im"
            i = findfirst(ks .== k2)

            vals_im = metrics_json[k2]["values"] .|> Float64
            vals = vals + im* vals_im
            k = k[begin:end-3]
            deleteat!(ks, i)
        elseif endswith(k, "/im")
            k2 = k[begin:end-3]*"/re"
            i = findfirst(ks .== k2)

            vals_re = metrics_json[k2]["values"] .|> Float64
            vals = vals_re + im* vals
            k = k[begin:end-3]
            deleteat!(ks, i)
        end

        _hist = History(eltype(vals), eltype(steps))
        _hist.iterations = steps
        _hist.values = vals
        _hist.lastiter = last(steps)

        m.data.storage[Symbol(k)] = _hist
    end

    m.loaded = true
    return m
end

function Base.show(io::IO, mt::MIME"text/plain", md::MetricsData)
    println(io, "MetricData @ $(md.path)")
    show(io, mt, lazyload(md).data)
    return io
end
