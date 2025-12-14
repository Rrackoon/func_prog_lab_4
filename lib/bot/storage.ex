defmodule Bot.Storage do
  use GenServer

  ## Client API

  def start_link(_opts) do
    GenServer.start_link(
      __MODULE__,
      %{
        tasks: [],
        next_id: 1
      }, name: __MODULE__)
  end

  def add_task(task_map) do
    GenServer.call(__MODULE__, {:add_task, task_map})
  end

  def list_tasks() do
    GenServer.call(__MODULE__, :list_tasks)
  end

  def get_task(id) do
    GenServer.call(__MODULE__, {:get_task, id})
  end

  def edit_task(id, updates) do
    GenServer.call(__MODULE__, {:edit_task, id, updates})
  end

  def delete_task(id) do
    GenServer.call(__MODULE__, {:delete_task, id})
  end

  def filter_by_category(cat) do
    GenServer.call(__MODULE__, {:filter_category, cat})
  end

  def search(substring) do
    GenServer.call(__MODULE__, {:search, substring})
  end

  def stats_by_category() do
    GenServer.call(__MODULE__, :stats_by_category)
  end

  def upcoming(n \\ 5) do
    GenServer.call(__MODULE__, {:upcoming, n})
  end

  ## Server callbacks

  def init(state), do: {:ok, state}

  def handle_call({:add_task, task}, _from, state) do
    id = state.next_id

    deadline =
      case Map.get(task, :deadline) do
        %Date{} = d ->
          d

        nil ->
          nil

        s when is_binary(s) ->
          case Date.from_iso8601(String.trim(s)) do
            {:ok, d} -> d
            _ -> nil
          end

        _ ->
          nil
      end

    new_task = %{
      id: id,
      title: Map.get(task, :title, ""),
      deadline: Map.get(task, :deadline, nil),
      category: Map.get(task, :category, nil),
      priority: Map.get(task, :priority, nil),
      recurring: Map.get(task, :recurring, nil)
    }

    new_state = %{
      state
      | tasks: [new_task | state.tasks],
        next_id: id + 1
    }

    {:reply, {:ok, new_task}, new_state}
  end

  def handle_call(:list_tasks, _from, state) do
    sorted =
      state.tasks
      |> Enum.sort_by(&maybe_date_for_sort(&1.deadline))

    {:reply, sorted, state}
  end

  def handle_call({:get_task, id}, _from, state) do
    {:reply, Enum.find(state.tasks, &(&1.id == id)), state}
  end

  def handle_call({:edit_task, id, updates}, _from, state) do
    {found, others} = Enum.split_with(state.tasks, &(&1.id == id))

    case found do
      [task | _] ->
        deadline =
          case Map.get(updates, :deadline, task.deadline) do
            %Date{} = d ->
              d

            s when is_binary(s) ->
              case Date.from_iso8601(String.trim(s)) do
                {:ok, d} -> d
                _ -> task.deadline
              end

            _ ->
              task.deadline
          end

        updated =
          Map.merge(task, %{
            title: Map.get(updates, :title, task.title),
            deadline: Map.get(updates, :deadline, task.deadline),
            category: Map.get(updates, :category, task.category),
            priority: Map.get(updates, :priority, task.priority),
            recurring: Map.get(updates, :recurring, task.recurring)
          })

        {:reply, {:ok, updated}, %{state | tasks: [updated | others]}}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:delete_task, id}, _from, state) do
    {deleted, rest} = Enum.split_with(state.tasks, &(&1.id == id))

    case deleted do
      [] -> {:reply, {:error, :not_found}, state}
      _ -> {:reply, :ok, %{state | tasks: rest}}
    end
  end

  def handle_call({:filter_category, cat}, _from, state) do
    res =
      state.tasks
      |> Enum.filter(&(&1.category == cat))
      |> Enum.sort_by(&maybe_date_for_sort(&1.deadline))

    {:reply, res, state}
  end

  def handle_call({:search, substr}, _from, state) do
    ss = String.downcase(substr || "")

    res =
      state.tasks
      |> Enum.filter(&String.contains?(String.downcase(&1.title), ss))

    {:reply, res, state}
  end

  def handle_call(:stats_by_category, _from, state) do
    stats =
      state.tasks
      |> Enum.group_by(& &1.category)
      |> Enum.map(fn {cat, list} -> {cat, length(list)} end)
      |> Enum.into(%{})

    {:reply, stats, state}
  end

  def handle_call({:upcoming, n}, _from, state) do
    today = Date.utc_today()

    res =
      state.tasks
      |> Enum.filter(&(&1.deadline != nil))
      |> Enum.sort_by(& &1.deadline)
      |> Enum.take(n)
      |> Enum.map(fn t ->
        overdue? = Date.compare(t.deadline, today) == :lt
        Map.put(t, :overdue, overdue?)
      end)

    {:reply, res, state}
  end


  defp maybe_date_for_sort(nil), do: ~D[9999-12-31]
  defp maybe_date_for_sort(%Date{} = d), do: d
end
