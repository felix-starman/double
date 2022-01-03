# Code.require_file("./test/keyword_syntax_tests.ex")
# Code.require_file("./test/function_syntax_tests.ex")

defmodule MockTest do
  use ExUnit.Case
  # import KeywordSyntaxTests
  # import FunctionSyntaxTests
  import Double

  @moduletag :skip
  # TODO - remove/rework all this

  setup_all do
    %{
      dbl: TestMock,
      dbl2: TestMock2,
      subject: &__MODULE__.subject/3
    }
  end

  def subject(dbl, function_name, args) do
    apply(dbl, function_name, args)
  end

  # defp mocks(context) do
  #   Map.merge(context, )
  # end

  # TODO - Replace with a `set_double_mode :global
  # @pending true
  # test "can be stubbed and called in multiple processes", %{dbl: mock} do
  #   mock
  # end

  describe "Module mocks" do
    # setup [:mocks]

    # keyword_syntax_behavior()
    # function_syntax_behavior()

    # test "module names are the name given", %{dbl: mock} do
    #   assert MockMod = mock
    # end

    test "can be stubbed" do
      _mock = defmock(MockMod, for: TestModule)
      assert stub(MockMod, :process, fn 1, 2, 3 -> :from_mock end)
      assert stub(MockMod, :process, fn 3, 2, 1 -> :from_mock end)

      assert :from_mock = MockMod.process(1, 2, 3)
      # assert stub(TestModule, :process, fn 1, 2, 3 -> :from_mock end)
    end
  end
end
