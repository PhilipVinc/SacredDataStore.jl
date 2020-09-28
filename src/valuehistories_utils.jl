using RecipesBase

function Base.real(h::History)
    steps, vals = get(h)
    _h = History(real(eltype(vals)), eltype(steps))
    _h.iterations = steps
    _h.values = real(vals)
    return _h
end

function Base.imag(h::History)
    steps, vals = get(h)
    _h = History(real(eltype(vals)), eltype(steps))
    _h.iterations = steps
    _h.values = imag(vals)
    return _h
end

function Base.getindex(h::History, step::Number)
    steps, vals = get(h)
    id = findfirst(steps .== step)
    return vals[id]
end

function Base.getindex(h::History, ids)
    steps, vals = get(h)

    id_start = findfirst(steps .>= first(ids))
    id_end = findlast(steps .<= last(ids))

    _h = History(eltype(vals), eltype(steps))
    _h.iterations = steps[id_start:id_end]
    _h.values = vals[id_start:id_end]
    return _h
end

Base.firstindex(h::History) = first(h.iterations)
Base.lastindex(h::History) = last(h.iterations)

@recipe function plot(h::History)
    markershape --> :cross
    title       --> "Value History"
    get(h)
end
