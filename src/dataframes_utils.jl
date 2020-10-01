using Base64

function addcol!(df::DataFrame, k, val)
    col_val = Vector{Union{Missing, typeof(val)}}(undef, nrow(df))
    col_val .= missing
    col_val[end] = val
    setproperty!(df, k, col_val)
end

function setcol!(df::DataFrame, i, k, val)
    if string(k) ∈ names(df)
    	T = eltype(df[k])
        df[i, k] = _convert(T,val)
    else
        addcol!(df, k, val)
    end
end

Base.push!(df::DataFrame) = push!(df, [missing for i=1:ncol(df)])

_convert(T::Type{Union{Missing, String}}, val::JSON3.Object{Base.CodeUnits{UInt8,String},SubArray{UInt64,1,Array{UInt64,1},Tuple{UnitRange{Int64}},true}}) = begin
    ks = keys(val)
    if length(ks) == 1 && first(ks) == Symbol("py/b64")
        return convert(T, String(base64decode(val[first(ks)]))) 
    end 
end 
_convert(T::Type{<:Union{Missing, String}}, val::Number) = "$val"
_convert(T::Type, val) = convert(T, val)
