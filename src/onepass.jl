# onepass
# todo: unalias expressions (in constraints and cost,
# not declarations); add default unalias for x₁, etc.

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
parse(ocp, e; log=true) = @match e begin
    :( $v ∈ R^$q, variable ) => p_variable(ocp, v, q; log)
    :( $v ∈ R   , variable ) => p_variable(ocp, v   ; log)
    :( $t ∈ [ $t0, $tf ], time ) => p_time(ocp, t, t0, tf; log)
    :( $x ∈ R^$n, state ) => p_state(ocp, x, n; log)
    :( $x ∈ R   , state ) => p_state(ocp, x   ; log)
    :( $u ∈ R^$m, control ) => p_control(ocp, u, m; log)
    :( $u ∈ R   , control ) => p_control(ocp, u   ; log)
    :( $a = $e1 ) => p_alias(ocp, a, e1; log)
    :( $x'($t) == $e1 ) => p_dynamics(ocp, x, t, e1; log)
    :( $e1 == $e2 ) => p_constraint_eq(ocp, e1, e2; log)
    :( ∫($e1) → min ) => p_objective(ocp, e1, :min; log)
    :( ∫($e1) → max ) => p_objective(ocp, e1, :max; log)
    _ =>

    if e isa LineNumberNode
        e
    elseif (e isa Expr) && (e.head == :block)
        Expr(:block, map(e -> parse(ocp, e), e.args)...)
    else
        throw("syntax error")
    end
end

p_variable(ocp, v, q=1; log=false) = begin
    log && println("variable: $v, dim: $q")
    vv = QuoteNode(v)
    :( $ocp.parsed.vars[$vv] = $(esc(q)) )
end

p_time(ocp, t, t0, tf; log=false) = begin
    log && println("time: $t, initial time: $t0, final time: $tf")
    tt = QuoteNode(t)
    tt0 = QuoteNode(t0)
    ttf = QuoteNode(tf)
    quote
        $ocp.parsed.t = $tt
        $ocp.parsed.t0 = $tt0
        $ocp.parsed.tf = $ttf
        @match ($tt0 ∈ keys($ocp.parsed.vars), $ttf ∈ keys($ocp.parsed.vars)) begin
            (false, false) => time!($ocp, [ $(esc(t0)), $(esc(tf)) ] , String($tt))
            (false, true ) => time!($ocp, :initial, $(esc(t0)), String($tt))
            (true , false) => time!($ocp, :final  , $(esc(tf)), String($tt))
            _              => throw("parsing error: both initial and final time " *
	                            "cannot be variable")
        end
    end
end

p_state(ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    xx = QuoteNode(x)
    quote
        $ocp.parsed.x = $xx
        state!($ocp, $(esc(n))) # todo: add state name
    end
end

p_control(ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    uu = QuoteNode(u)
    quote
        $ocp.parsed.u = $uu
        control!($ocp, $(esc(m))) # todo: add control name
    end
end

p_alias(ocp, a, e; log=false) = begin
    log && println("alias: $a = $e")
    aa = QuoteNode(a)
    ee = QuoteNode(e)
    :( $ocp.parsed.aliases[$aa] = $ee )
end

p_dynamics(ocp, x, t, e; log) = begin
    log && println("dynamics: $x'($t) == $e")
    xx = QuoteNode(x)
    tt = QuoteNode(t)
    gs = gensym()
    # quote $( replace_call(e, s) ) end
    quote # debug: let seems to be escaped; but vars local to @match seem not...
        ( $xx ≠ $ocp.parsed.x ) && throw("dynamics: wrong state")
        ( $tt ≠ $ocp.parsed.t ) && throw("dynamics: wrong time")

        function $gs($ocp.parsed.x, $ocp.parsed.u)
	    $(esc( replace_call(e, t) ))
	end
	constraint!($ocp, :dynamics, $gs)
    end
end

p_constraint_eq(ocp, e1, e2; log) = begin
    log && println("constraint: $e1 == $e2")
    ee1 = QuoteNode(e1)
    ee2 = QuoteNode(e2)
    quote
        @match constraint_type($ee1,
	    $ocp.parsed.t,
	    $ocp.parsed.t0,
	    $ocp.parsed.tf,
	    $ocp.parsed.x,
	    $ocp.parsed.u) begin
	    (:initial, nothing) => constraint!($ocp, :initial,      $(esc(e2)))
	    (:initial, val    ) => constraint!($ocp, :initial, val, $(esc(e2)))
	    (:final  , nothing) => constraint!($ocp, :final  ,      $(esc(e2)))
	    (:final  , val    ) => constraint!($ocp, :final  , val, $(esc(e2)))
	    _ => throw("syntax error")
	end
    end
end

p_objective(ocp, e, type; log) = begin
    log && println("objective: ∫($e) → $type")
    ee = QuoteNode(e)
    ttype = QuoteNode(type)
    gs = QuoteNode(gensym())
    quote
	eval(Expr(:function, Expr(:call,
   	    $gs,
	    $ocp.parsed.x,
	    $ocp.parsed.u),
	    replace_call(replace_call($ee,
	    $ocp.parsed.x,
	    $ocp.parsed.t,
	    $ocp.parsed.x),
	    $ocp.parsed.u,
	    $ocp.parsed.t,
	    $ocp.parsed.u)))
	objective!($ocp,
	    :lagrange,
	    (a, b) -> Base.invokelatest(eval($gs), a, b),
	    $ttype)
    end
end
 
"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
macro def1(ocp, e)
    #esc( parse(ocp, e; log=true) )
    parse(esc(ocp), e; log=true)
end

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
macro def1(e)
    esc( quote ocp = Model(); @def1 ocp $e; ocp end )
end
