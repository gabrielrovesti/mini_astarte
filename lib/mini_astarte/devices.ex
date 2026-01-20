defmodule MiniAstarte.Devices do
  alias MiniAstarte.Repo
  alias MiniAstarte.Schemas.Device

  def register_device(id, name) when is_binary(id) do
    token = generate_token()

    %Device{}
    |> Device.changeset(%{id: id, name: name, token: token})
    |> Repo.insert()
  end

  def register_device(_id, _name), do: {:error, Device.changeset(%Device{}, %{})}

  def get_device(id) when is_binary(id), do: Repo.get(Device, id)
  def get_device(_), do: nil

  def valid_token?(%Device{token: token}, provided) when is_binary(provided) do
    token == provided
  end

  def valid_token?(_, _), do: false

  defp generate_token do
    24
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
