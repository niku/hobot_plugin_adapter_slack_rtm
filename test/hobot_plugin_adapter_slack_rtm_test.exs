# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule Hobot.Plugin.Adapter.SlackRTMTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest Hobot.Plugin.Adapter.SlackRTM

  test "greets the world" do
    assert Hobot.Plugin.Adapter.SlackRTM.hello() == :world
  end

  property "sort two values" do
    check all term1 <- term(),
              term2 <- term() do
      [a, b | []] = Enum.sort([term1, term2])
      assert a <= b
    end
  end
end
