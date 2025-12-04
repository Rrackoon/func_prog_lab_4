defmodule Bot.Schedule do
  use GenServer

  # state: %{schedule: [%{day: :mon, time: "09:00", subject: "Матан"}]}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{schedule: default_schedule()}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def get_for_day(day) do
    GenServer.call(__MODULE__, {:get_for_day, day})
  end

  def get_for_week() do
    GenServer.call(__MODULE__, :get_for_week)
  end

  def handle_call({:get_for_day, day}, _from, state) do
    res = state.schedule |> Enum.filter(&(&1.day == day))
    {:reply, res, state}
  end

  def handle_call(:get_for_week, _from, state) do
    {:reply, state.schedule, state}
  end

  defp default_schedule do
    [
      %{day: :mon, time: "09:00", subject: "Матан"},
      %{day: :mon, time: "11:00", subject: "ФП"},
      %{day: :tue, time: "10:00", subject: "АиСД"},
      %{day: :wed, time: "13:00", subject: "Анализ"}
    ]
  end
end
