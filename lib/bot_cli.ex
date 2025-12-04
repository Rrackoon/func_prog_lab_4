defmodule Bot.CLI do
  alias Bot.Parser
  alias Bot.Storage

  def main do
    # Ничего НЕ запускаем — всё стартует Supervisor
    loop()
  end

  defp loop do
    input =
      IO.gets("> ")
      |> case do
        nil -> :quit
        s -> String.trim(s)
      end

    case input do
      :quit ->
        IO.puts("Exit.")
        :ok

      "" ->
        loop()

      cmd ->
        handle_command(cmd)
        loop()
    end
  end

  defp handle_command(cmd) do
    case Parser.parse(cmd) do
      {:task_add, data} ->
        {:ok, task} = Storage.add_task(data)
        IO.puts("Добавлено: #{task.title} (#{task.category}) deadline=#{task.deadline}")

      {:task_list} ->
        Storage.list_tasks()
        |> Enum.each(fn t ->
          IO.puts(
            "[#{t.id}] #{t.title}" <>
              if(t.category, do: " (#{t.category})", else: "") <>
              if(t.priority, do: " priority:#{t.priority}", else: "") <>
              if(t.recurring, do: " recurring:#{t.recurring}", else: "") <>
              if(t.deadline, do: " deadline:#{t.deadline}", else: "")
          )
        end)

      {:task_upcoming} ->
        Storage.upcoming()
        |> Enum.each(fn t ->
          mark = if t.overdue, do: " (просрочено)", else: ""
          IO.puts("[#{t.id}] #{t.title} — дедлайн: #{t.deadline}#{mark}")
        end)

      {:task_delete, id} ->
        case Storage.delete_task(id) do
          :ok ->
            IO.puts("Задача #{id} удалена.")

          {:error, :not_found} ->
            IO.puts("Нет задачи с ID=#{id}.")
        end

      {:task_filter, cat} ->
        Storage.filter_by_category(cat)
        |> Enum.each(fn t ->
          IO.puts(
            "[#{t.id}] #{t.title}" <>
              if(t.category, do: " (#{t.category})", else: "") <>
              if(t.priority, do: " priority:#{t.priority}", else: "") <>
              if(t.recurring, do: " recurring:#{t.recurring}", else: "") <>
              if(t.deadline, do: " deadline:#{t.deadline}", else: "")
          )
        end)

      {:task_search, text} ->
        Storage.search(text)
        |> Enum.each(fn t ->
          IO.puts(
            "[#{t.id}] #{t.title}" <>
              if(t.category, do: " (#{t.category})", else: "") <>
              if(t.priority, do: " priority:#{t.priority}", else: "") <>
              if(t.recurring, do: " recurring:#{t.recurring}", else: "") <>
              if(t.deadline, do: " deadline:#{t.deadline}", else: "")
          )
        end)

      {:task_edit, id, updates} ->
        case Storage.edit_task(id, updates) do
          {:ok, t} ->
            IO.puts(
              "Обновлено: [#{t.id}] #{t.title}" <>
                if(t.category, do: " (#{t.category})", else: "") <>
                if(t.priority, do: " priority:#{t.priority}", else: "") <>
                if(t.recurring, do: " recurring:#{t.recurring}", else: "") <>
                if(t.deadline, do: " deadline:#{t.deadline}", else: "")
            )

          {:error, :not_found} ->
            IO.puts("Нет задачи с ID=#{id}.")
        end

      {:task_export} ->
        tasks = Storage.list_tasks()

        # JSON
        File.write!("tasks.json", Jason.encode!(tasks, pretty: true))

        # TXT
        lines =
          tasks
          |> Enum.map(fn t ->
            [
              "ID=#{t.id}",
              "title=#{t.title}",
              "category=#{t.category || "-"}",
              "priority=#{t.priority || "-"}",
              "recurring=#{t.recurring || "-"}",
              "deadline=#{t.deadline}"
            ]
            |> Enum.join(" | ")
          end)
          |> Enum.join("\n")

        File.write!("tasks.txt", lines)

        IO.puts("Экспорт завершён: tasks.json, tasks.txt")

      {:error, :bad_add_format} ->
        IO.puts("Неверный формат команды. Пример:")
        IO.puts(~s/task add "дз" due: 2025-12-01 category: "матан"/)

      {:error, :unknown_command} ->
        IO.puts("Неизвестная команда.")

      {:error, :bad_edit_format} ->
        IO.puts("Неверный формат. Пример:")
        IO.puts(~s/task edit 1 title:"новый текст" deadline:2025-12-10 category:"фп"/)

      {:error, :bad_delete_format} ->
        IO.puts("Неверный формат. Используй: task delete ID")
    end
  end
end
