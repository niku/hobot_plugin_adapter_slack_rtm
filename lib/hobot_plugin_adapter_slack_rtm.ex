defmodule Hobot.Plugin.Adapter.SlackRTM do
  @moduledoc """
  Documentation for Hobot.Plugin.Adapter.SlackRTM.
  """

  defmodule Config do
    @moduledoc false

    @keys ~w(context access_token self team conn monitor_ref)a
    @enforce_keys @keys
    defstruct @keys
  end

  use GenServer

  def start_link(access_token, options \\ []) do
    GenServer.start_link(__MODULE__, access_token, options)
  end

  def init({context, access_token}) do
    send(self(), :initialize)
    {:ok, {:initializing, context, access_token}}
  end

  def handle_cast({:send_text, text}, {:connected, config}) do
    :ok = slack_api().send_text(config.conn, text)
    {:noreply, {:connected, config}}
  end

  def handle_info(:initialize, {:initializing, context, access_token}) do
    %{"ok" => true, "self" => self, "team" => team, "url" => url} =
      slack_api().get_rtm_connect(String.to_charlist(access_token))

    conn = slack_api().connect_websocket(url)
    monitor_ref = Process.monitor(conn)

    {:noreply,
     {:connecting,
      %Config{
        context: context,
        access_token: access_token,
        self: self,
        team: team,
        conn: conn,
        monitor_ref: monitor_ref
      }}}
  end

  def handle_info({:gun_ws_upgrade, _, _, _}, {:connecting, config}) do
    # {gun_ws_upgrade, ConnPid, ok, Headers}
    # https://ninenines.eu/docs/en/gun/1.0/manual/gun/#_gun_ws_upgrade_connpid_ok_headers
    schedule_work()
    {:noreply, {:connected, config}}
  end

  def handle_info({:gun_ws, _, {:text, frame}}, {status, config}) do
    # {gun_ws, ConnPid, Frame}
    # https://ninenines.eu/docs/en/gun/1.0/manual/gun/#_gun_ws_connpid_frame
    decoded = Jason.decode!(frame)

    apply(config.context.publish, [
      "on_event",
      make_ref(),
      {config.team, config.self, decoded}
    ])

    {:noreply, {status, config}}
  end

  def handle_info(:do_ping, state) do
    # https://api.slack.com/rtm#ping_and_pong
    schedule_work()

    json =
      Jason.encode!(%{
        id: System.os_time(),
        type: "ping"
      })

    GenServer.cast(self(), {:send_text, json})
    {:noreply, state}
  end

  defp slack_api do
    module =
      Application.get_env(:hobot_plugin_adapter_slack_rtm, :slack_api) ||
        Hobot.Plugin.Adapter.SlackRTM.SlackAPIWithGun

    # HACK: We have to wait to allow the mock is shared in the testing.
    #  If we didn't wait sharing the mock, the test is failed.
    if module === Hobot.Plugin.Adapter.SlackRTM.SlackAPIMock do
      Process.sleep(10)
    end

    module
  end

  defp schedule_work do
    a_minute = 60 * 1000

    # We know this implementation is a bit silly.
    # The client pings to server as fixed interval
    # even if any other communication have between the client and the server.
    # Of cource we can implement more smarter one,
    # but the code gets more complex.
    # To keep the code simple, I think the code is OK.
    # If you don't think so or think we can choose better one,
    # feel free to let us know.
    Process.send_after(self(), :do_ping, a_minute)
  end
end
