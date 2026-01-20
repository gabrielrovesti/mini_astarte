defmodule MiniAstarte.Streams do
  alias MiniAstarte.Schemas.Measurement

  def broadcast_measurement(%Measurement{} = measurement) do
    Phoenix.PubSub.broadcast(
      MiniAstarte.PubSub,
      "measurements",
      {:measurement, measurement}
    )
  end
end
