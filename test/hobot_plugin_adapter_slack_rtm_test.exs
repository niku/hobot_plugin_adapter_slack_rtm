defmodule Hobot.Plugin.Adapter.SlackRTMTest do
  use ExUnit.Case
  doctest Hobot.Plugin.Adapter.SlackRTM

  test "greets the world" do
    assert Hobot.Plugin.Adapter.SlackRTM.hello() == :world
  end
end
