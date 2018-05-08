# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule Hobot.Plugin.Adapter.SlackRTMTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest Hobot.Plugin.Adapter.SlackRTM

  import Mox
  alias Hobot.Plugin.Adapter.SlackRTM

  setup :verify_on_exit!

  test "child_spec" do
    bot_context = %{}
    access_token = "xoxb-Your_Bot_User_OAuth_Access_Token"

    assert SlackRTM.child_spec({bot_context, access_token}) == %{
             id: SlackRTM,
             start: {SlackRTM, :start_link, [{bot_context, access_token}]}
           }
  end

  test "start_link" do
    access_token = "xoxb-Your_Bot_User_OAuth_Access_Token"
    access_token_charlist = String.to_charlist(access_token)
    websocket_url = "wss://abc.lb.example.com/websocket/random_url"

    SlackRTM.SlackAPIMock
    |> expect(:get_rtm_connect, fn ^access_token_charlist ->
      %{
        "ok" => true,
        "self" => %{"id" => "MYBOTID", "name" => "hobot"},
        "team" => %{
          "domain" => "niku",
          "id" => "MYTEAMID",
          "name" => "niku"
        },
        "url" => websocket_url
      }
    end)
    |> expect(:connect_websocket, fn ^websocket_url ->
      spawn(fn ->
        receive do
        end
      end)
    end)

    {:ok, pid} = SlackRTM.start_link({nil, access_token})
    allow(SlackRTM.SlackAPIMock, self(), pid)
    # Wait the mock is called
    Process.sleep(100)
  end
end
