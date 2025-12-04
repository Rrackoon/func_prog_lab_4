defmodule Bot.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      Bot.Storage,
      Bot.Schedule,
      Bot.Reminder
    ]

    opts = [strategy: :one_for_one, name: Bot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
