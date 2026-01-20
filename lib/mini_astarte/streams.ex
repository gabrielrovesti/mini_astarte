defmodule MiniAstarte.Streams do
  alias MiniAstarte.Schemas.Measurement

  def broadcast_measurement(%Measurement{} = measurement) do
    Phoenix.PubSub.broadcast(
      MiniAstarte.PubSub,
      "measurements",
      {:measurement, measurement}
    )
  end

  def broadcast_alert(alert) do
    Phoenix.PubSub.broadcast(
      MiniAstarte.PubSub,
      "alerts",
      {:alert, alert}
    )
  end
end
