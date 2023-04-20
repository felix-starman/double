- [Example Usage](#example-usage)
  - [blank/map](#blankmap)
    - [Creation](#creation)
    - [Modification of existing Double](#modification-of-existing-double)
    - [Calling](#calling)
    - [Asserting](#asserting)
  - [explicit func-arity list](#explicit-func-arity-list)
    - [Creation](#creation-1)
    - [Modification of existing Double](#modification-of-existing-double-1)
    - [Calling](#calling-1)
    - [Asserting](#asserting-1)
  - [for module](#for-module)
    - [Creation](#creation-2)
    - [Modification of existing Double](#modification-of-existing-double-2)
    - [Calling](#calling-2)
    - [Asserting](#asserting-2)
  - [for behaviour](#for-behaviour)

# Example Usage
## blank/map

### Creation
- `double/0` or `double/1`
- then `allow/2` or `allow/3`

```elixir

# Results in: %{_double_id: "double-id-hash-of-test-pid"}
# and registered Double GenServer linked to calling pid (assumed to be a test-pid)
double()
double(%{})
```

```elixir
# Creation of the "shim" map-key function
allow(dbl, :process, with: [1, 2, 3], returns: 6 end)
# %{_double_id: "double-id-hash-of-test-pid", process: shim_fn}
# Double GenServer's FuncList is updated for what was allowed
```


### Modification of existing Double
- more calls to `allow/2` or `allow/3`
- `spy/n` should fail with a Double-based error
- `stub/n` should fail with a Double-based error


### Calling
- anonymous functions
- raises if defined outside of a test


```elixir
dbl.process.(1, 2, 3)

spawn do
  dbl.process.(1, 2, 3)
end
```

### Asserting
- `assert_receive/1`, `assert_received/1`
- `assert_called/1`
- `clear` removes Double GenServer setup

```elixir
# Old format for `assert_receive` (deprecated)
assert_receive({:process, 1, 2, 3})

# New format for `assert_receive`
assert_receive({:process, [1, 2, 3]})

# New, where `dbl` is a map with `_double_id` key
assert_called({dbl, :process, [1, 2, 3]})
```


## explicit func-arity list

### Creation
- `defmock/1` or `defmock/2`

```elixir
# Results in compiled module, randomly named, e.g. `Double1234`
# Not registered anywhere
dblmod = defmock(for: [process: 3, process: 1])

# Results in compiled module named `NewMock`
# Not registered anywhere
NewMock = defmock(NewMock, for: [process: 3, process: 1])

defmock(NewMock, for: [process: 3, process: 1]) # raises Double.AlreadyDefinedError
```

### Modification of existing Double
- calls to `stub/2` or `stub/3`
- `spy/n` should fail with a Double-based error
- `allow/n` should fail with a Double-based error

```elixir
stub(dblmod) # raises Double.AlreadyDefinedError or MatchError?
spy(dblmod) # raises Double.AlreadyDefinedError

# any `allow` call raises a Double.AlreadyDefinedError
allow(dblmod) # raises Double.AlreadyDefinedError
allow(dblmod, :process) # raises Double.AlreadyDefinedError
allow(dblmod, :process, opts) # raises Double.AlreadyDefinedError
allow(dblmod, :process, func) # raises Double.AlreadyDefinedError


stub(dblmod, :process, fn a, b, c -> a + b + c end)
stub(dblmod, :process, fn 0, 0, 0 -> nil end) # order matters

# async: true, :global
stub(dblmod, ..., ...) # raises Double.GlobalStubError, message suggests switching to :private
# ??? what about setup_all?
```

### Calling
- public functions
- raises if not stubbed
- supports private mode


```elixir
NewMock.process(1, 2, 3)
dblmod.process(1, 2, 3) # 6
dblmod.process(0, 0, 0) # nil

dblmod.other_function() # nil


# async: false, :global
spawn do
  dbl.process(1, 2, 3)
end

# :private
spawn do
  dbl.process(1, 2, 3)
  # will call to the Global Double
end
```

### Asserting
- `assert_receive/1`, `assert_received/1`
- `assert_called/1`
- `clear` removes Double GenServer setup

```elixir
assert_receive({dblmod, :process, [1, 2, 3]})
assert_called({dblmod, :process, [1, 2, 3]})
```


## for module
similar to "explicit func-arity list"

### Creation
- `defmock/1` or `defmock/2`

```elixir
# Results in compiled module, randomly named, e.g. `Double1234`
# Not registered anywhere
dblmod = defmock(for: OriginalModule)

# Results in compiled module named `NewMock`
# Not registered anywhere
NewMock = defmock(NewMock, for: OriginalModule)

defmock(NewMock, for: OriginalModule) # raises Double.AlreadyDefinedError
```

### Modification of existing Double
same as ["explicit func-arity list"](#modification-of-existing-double-1)

### Calling
same as ["explicit func-arity list"](#calling-1)

### Asserting
same as ["explicit func-arity list"](#asserting-1)

## for behaviour
same as ["for module"](#for-module) except raises if it's not a behaviour, and that stubbing with a module is only allowed on something that implements the behaviour.
