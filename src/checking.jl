function __check_time_dependence(time_dependence::DataType)
    time_dependence ∉ [Autonomous, NonAutonomous] && throw(IncorrectArgument("time_dependence must be either Autonomous or NonAutonomous"))
end

function __check_variable_dependence(variable_dependence::DataType)
    variable_dependence ∉ [NonVariable, Variable] && throw(IncorrectArgument("variable_dependence must be either NonVariable or Variable"))
end

function __check_criterion(criterion::Symbol)
    criterion ∉ [:min, :max] && throw(IncorrectArgument("criterion must be either :min or :max"))
end

function __check_state_set(ocp::OptimalControlModel)
    __state_not_set(ocp) && throw(UnauthorizedCall("the state dimension has to be set before. Use state!."))
end

function __check_control_set(ocp::OptimalControlModel)
    __control_not_set(ocp) && throw(UnauthorizedCall("the control dimension has to be set before. Use control!."))
end

function __check___time_set(ocp::OptimalControlModel)
    __time_not_set(ocp) && throw(UnauthorizedCall("the time dimension has to be set before. Use time!."))
end

function __check_variable_set(ocp::OptimalControlModel{td, Variable}) where {td}
    __variable_not_set(ocp) && throw(UnauthorizedCall("the variable dimension has to be set before. Use variable!."))
end

function __check_variable_set(ocp::OptimalControlModel{td, NonVariable}) where {td}
    nothing
end

function __check_all_set(ocp::OptimalControlModel)
    __check_state_set(ocp)
    __check_control_set(ocp)
    __check___time_set(ocp)
    __check_variable_set(ocp)
end

macro __check(s::Symbol)
    s == :time_dependence && return esc(quote __check_time_dependence($s) end)
    s == :variable_dependence && return esc(quote __check_variable_dependence($s) end)
    s == :criterion && return esc(quote __check_criterion($s) end)
    s == :ocp && return esc(quote __check_all_set($s) end)
    error("s must be either :time_dependence, :variable_dependence or :criterion")
end

macro __check(s::DataType)
    eval(s) <: VariableDependence && return esc(quote __check_variable_dependence($s) end)
    eval(s) <: TimeDependence && return esc(quote __check_time_dependence($s) end)
    error("s must be either VariableDependence or TimeDependence")
end