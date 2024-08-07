function test_exception()

e = AmbiguousDescription((:e,))
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = IncorrectArgument("e")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = IncorrectMethod(:e)
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = IncorrectOutput("blabla")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = NotImplemented("blabla")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = ExtensionError("tatat")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

end