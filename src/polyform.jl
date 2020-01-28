using FunctionalCollections

const pdict = PersistentHashMap
const onekey = pdict{Union{}, Union{}}()

# something like
#   1//2 * (x^2)(y^3) + 4//5 * x
# is expressed as:
#   PDict(x^2 * y^3 => 1//2, x^1 => 4//5)
# Where x^2 * y^3 is represented as
#   PDict(x=>2, y=>3)
#
struct LinearCombination{T<:pdict}
    terms::T
end

function _merge(f, d, others...)
    acc = d
    for other in others
        for (k, v) in other
            if haskey(acc, k)
                acc = assoc(acc, k, f(acc[k], v))
            else
                acc = assoc(acc, k, v)
            end
        end
    end
    acc
end

function constterm(b)
    LinearCombination(pdict(onekey => b))
end

function Base.:+(a::LinearCombination, b::LinearCombination)
    _merge(+, a.terms, b.terms)
end

function Base.:+(a::LinearCombination, b)
    if iszero(b)
        return a
    else
        return a + constterm(b)
    end
end

Base.:+(a, b::LinearCombination) = b+a

# Multiply 42*x^2*y^2  and 56*x^3*z
# which are actually:
#   pdict(:x=>2, :y=>2)=>42 and
#   pdict(:x=>3, :z=>3)=>56
function mul_term((a, ac)::Pair, (b, bc)::Pair)
    _merge(+, a, b) => ac * bc
end

function Base.:(*)(a::LinearCombination, b::LinearCombination)
    sum(LinearCombination(pdict(mul_term(ta, tb)))
        for ta in a.terms, tb in b.terms)
end

function Base.:(*)(a::LinearCombination, b)
    if iszero(b)
        return zero(b)
    elseif isone(b)
        return a
    else
        return a * constterm(b)
    end
end

# don't assume commutativity
function Base.:(*)(a, b::LinearCombination)
    if iszero(a)
        return zero(a)
    elseif isone(a)
        return b
    else
        constterm(a) * b
    end
end
