defmodule Bot.Reminder do
  use GenServer
  # проверять каждую минуту (для демонстрации)
  @check_interval :timer.minutes(1)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_tick()
    {:ok, state}
  end

  def handle_info(:tick, state) do
    check_deadlines()
    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @check_interval)
  end

  defp check_deadlines do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)

    Bot.Storage.upcoming(100)
    |> Enum.filter(fn t -> t.deadline == tomorrow end)
    |> Enum.each(fn t ->
      IO.puts("[REMINDER] Завтра дедлайн: #{t.title} (#{t.category}) — #{t.deadline}")
    end)
  end
end
