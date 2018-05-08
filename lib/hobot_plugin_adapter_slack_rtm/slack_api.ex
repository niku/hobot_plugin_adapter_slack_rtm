defmodule Hobot.Plugin.Adapter.SlackRTM.SlackAPI do
  @moduledoc """
  A module handles about interacting with slack through [RTM](https://api.slack.com/rtm) API.
  """

  @type access_token :: String.t() | nonempty_charlist
  @type rtm_connect_response :: map

  @doc """
  Gets a Real Time Messaging API session and reserves a specific URL for our application.

  It returns [a response](https://api.slack.com/methods/rtm.connect#response).
  """
  @callback get_rtm_connect(access_token) :: rtm_connect_response

  @doc """
  Connects websocket.

  It returns pid of a client which have a websocket connection.
  """
  @callback connect_websocket(String.t()) :: pid

  @doc """
  Sends a text to Slack
  """
  @callback send_text(pid, String.t()) :: :ok
end

defmodule Hobot.Plugin.Adapter.SlackRTM.SlackAPIWithGun do
  @moduledoc false
  @behaviour Hobot.Plugin.Adapter.SlackRTM.SlackAPI

  @impl true
  def get_rtm_connect(access_token) do
    {:ok, conn_pid} = :gun.open('slack.com', 443)
    stream_ref = :gun.get(conn_pid, '/api/rtm.connect?token=#{access_token}')
    {:response, :nofin, 200, _headers} = :gun.await(conn_pid, stream_ref)
    {:ok, body} = :gun.await_body(conn_pid, stream_ref)
    :gun.shutdown(conn_pid)
    :gun.flush(conn_pid)
    Jason.decode!(body)
  end

  @impl true
  def connect_websocket(url) do
    %URI{scheme: "wss", host: host, path: path} = URI.parse(url)
    {:ok, conn_pid} = :gun.open(String.to_charlist(host), 443)
    {:ok, :http} = :gun.await_up(conn_pid)
    _ref = :gun.ws_upgrade(conn_pid, String.to_charlist(path))
    conn_pid
  end

  @impl true
  def send_text(pid, text) do
    :gun.ws_send(pid, {:text, text})
  end
end
