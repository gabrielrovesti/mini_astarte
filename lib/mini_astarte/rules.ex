defmodule MiniAstarte.Rules do
  import Ecto.Query, only: [from: 2]
  alias MiniAstarte.Repo
  alias MiniAstarte.Schemas.{Alert, AlertRule}

  def maybe_alert(device_id, key, value, ts) do
    rules = list_rules_for_key(device_id, key)

    case Enum.filter(rules, &rule_match?(&1, value)) do
      [] ->
        :ok

      matches ->
        Enum.each(matches, fn rule ->
          changeset =
            Alert.changeset(%Alert{}, %{
              device_id: device_id,
              rule: "#{rule.key} #{rule.op} #{rule.value}",
              payload: %{"key" => key, "value" => value, "rule_id" => rule.id},
              ts: ts
            })

          Repo.insert(changeset)
        end)

        :alerted
    end
  end

  def list_rules(opts \\ %{}) do
    device_id = Map.get(opts, :device_id)
    limit = Map.get(opts, :limit, 50)
    offset = Map.get(opts, :offset, 0)

    query = from(r in AlertRule, select: r)
    query = if device_id, do: from(r in query, where: r.device_id == ^device_id), else: query

    query =
      from(r in query,
        order_by: [desc: r.inserted_at],
        limit: ^limit,
        offset: ^offset
      )

    Repo.all(query)
  end

  def get_rule(id) when is_binary(id), do: Repo.get(AlertRule, id)
  def get_rule(_), do: nil

  def create_rule(attrs) do
    %AlertRule{}
    |> AlertRule.changeset(attrs)
    |> Repo.insert()
  end

  def update_rule(%AlertRule{} = rule, attrs) do
    rule
    |> AlertRule.changeset(attrs)
    |> Repo.update()
  end

  def delete_rule(%AlertRule{} = rule), do: Repo.delete(rule)

  defp list_rules_for_key(device_id, key) do
    db_rules =
      from(r in AlertRule,
        where:
          r.key == ^key and r.enabled == true and
            (is_nil(r.device_id) or r.device_id == ^device_id)
      )
      |> Repo.all()

    if db_rules == [] do
      config_rules = Application.get_env(:mini_astarte, :rules, %{})
      config_rule = Map.get(config_rules, key)

      case config_rule do
        %{gt: threshold} ->
          [%AlertRule{id: "config", key: key, op: "gt", value: threshold}]

        %{lt: threshold} ->
          [%AlertRule{id: "config", key: key, op: "lt", value: threshold}]

        _ ->
          []
      end
    else
      db_rules
    end
  end

  defp rule_match?(%AlertRule{op: "gt", value: threshold}, value), do: value > threshold
  defp rule_match?(%AlertRule{op: "gte", value: threshold}, value), do: value >= threshold
  defp rule_match?(%AlertRule{op: "lt", value: threshold}, value), do: value < threshold
  defp rule_match?(%AlertRule{op: "lte", value: threshold}, value), do: value <= threshold
  defp rule_match?(%AlertRule{op: "eq", value: threshold}, value), do: value == threshold
  defp rule_match?(_, _), do: false
end
