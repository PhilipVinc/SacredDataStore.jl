function addcol!(df::DataFrame, k, val)
    col_val = Vector{Union{Missing, typeof(val)}}(undef, nrow(df))
    col_val .= missing
    col_val[end] = val
    setproperty!(df, k, col_val)
end

function setcol!(df::DataFrame, i, k, val)
    if string(k) ∈ names(df)
        df[i, k] = val
    else
        addcol!(df, k, val)
    end
end

Base.push!(df::DataFrame) = push!(df, [missing for i=1:ncol(df)])
