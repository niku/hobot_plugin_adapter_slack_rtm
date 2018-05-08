ExUnit.start()

Mox.defmock(
  Hobot.Plugin.Adapter.SlackRTM.SlackAPIMock,
  for: Hobot.Plugin.Adapter.SlackRTM.SlackAPI
)

Application.put_env(
  :hobot_plugin_adapter_slack_rtm,
  :slack_api,
  Hobot.Plugin.Adapter.SlackRTM.SlackAPIMock
)
