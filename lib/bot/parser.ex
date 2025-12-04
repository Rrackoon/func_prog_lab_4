defmodule Bot.Parser do
  # Парсинг команды add: берет поля по регуляркам, в любом порядке.
  def parse("task add " <> rest) do
    fields = parse_fields(rest)

    with {:ok, title}    <- fetch_field(fields, :title),
         {:ok, deadline} <- fetch_field(fields, :deadline),
         {:ok, category} <- fetch_field(fields, :category) do

      {:task_add, %{
        title: title,
        deadline: deadline,
        category: category,
        recurring: Map.get(fields, :recurring),
        priority: Map.get(fields, :priority)
      }}
    else
      _ -> {:error, :bad_add_format}
    end
  end

  defp parse_fields(text) do
    %{}
    |> put_title(text)
    |> put_string(text, :category, ~r/category:\s*"([^"]+)"/)
    |> put_string(text, :priority, ~r/priority:\s*(\S+)/)
    |> put_string(text, :recurring, ~r/recurring:\s*(\S+)/)
    |> put_date(text, :deadline, ~r/due:\s*(\S+)/)
  end

  defp put_title(map, text) do
    case Regex.run(~r/^"([^"]+)"/, String.trim(text)) do
      [_, val] -> Map.put(map, :title, val)
      _ -> map
    end
  end

  defp put_string(map, text, key, regex) do
    case Regex.run(regex, text) do
      [_, val] -> Map.put(map, key, val)
      _ -> map
    end
  end

  defp put_date(map, text, key, regex) do
    case Regex.run(regex, text) do
      [_, date_str] ->
        case Date.from_iso8601(date_str) do
          {:ok, d} -> Map.put(map, key, d)
          _ -> map
        end
      _ -> map
    end
  end

  defp fetch_field(fields, key) do
    case fields[key] do
      nil -> {:error, key}
      val -> {:ok, val}
    end
  end

  def parse("task list"), do: {:task_list}
  def parse("task upcoming"), do: {:task_upcoming}

  def parse("task delete " <> id_str) do
    case Integer.parse(String.trim(id_str)) do
      {id, ""} -> {:task_delete, id}
      _ -> {:error, :bad_delete_format}
    end
  end

  def parse("task filter " <> category), do: {:task_filter, String.trim(category)}
  def parse("task search " <> text),   do: {:task_search, String.trim(text)}

  def parse("task edit " <> rest) do
    with [id_str | _] <- String.split(rest, " ", parts: 2),
         {id, ""} <- Integer.parse(id_str) do
      updates = parse_edit_args(rest)
      {:task_edit, id, updates}
    else
      _ -> {:error, :bad_edit_format}
    end
  end

  def parse("task export"), do: {:task_export}


  def parse(_), do: {:error, :unknown_command}

  defp parse_edit_args(text) do
    %{}
    |> put_if_match(text, :title, ~r/title:"([^"]+)"/)
    |> put_if_match(text, :category, ~r/category:"([^"]+)"/)
    |> put_if_match(text, :deadline, ~r/deadline:(\S+)/, &to_date/1)
    |> put_if_match(text, :recurring, ~r/recurring:(\S+)/)
    |> put_if_match(text, :priority, ~r/priority:(\S+)/)
  end

  defp put_if_match(map, text, key, regex, transform \\ & &1) do
    case Regex.run(regex, text) do
      [_, value] -> Map.put(map, key, transform.(value))
      _ -> map
    end
  end

  defp to_date(str) do
    case Date.from_iso8601(str) do
      {:ok, d} -> d
      _ -> nil
    end
  end
end
