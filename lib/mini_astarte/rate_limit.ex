defmodule MiniAstarte.RateLimit do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def check(key) when is_binary(key) do
    GenServer.call(__MODULE__, {:check, key})
  end

  def check(_), do: :ok

  @impl true
  def init(_opts) do
    config = Application.get_env(:mini_astarte, :rate_limit, %{})
    max = Map.get(config, :max, 60)
    window_ms = Map.get(config, :window_ms, 60_000)
    {:ok, %{max: max, window_ms: window_ms, buckets: %{}}}
  end

  @impl true
  def handle_call({:check, key}, _from, state) do
    now = System.system_time(:millisecond)
    {count, reset_at} = Map.get(state.buckets, key, {0, now + state.window_ms})

    {count, reset_at} =
      if now > reset_at do
        {0, now + state.window_ms}
      else
        {count, reset_at}
      end

    if count + 1 > state.max do
      {:reply, {:error, "rate_limited"}, state}
    else
      buckets = Map.put(state.buckets, key, {count + 1, reset_at})
      {:reply, :ok, %{state | buckets: buckets}}
    end
  end
end
