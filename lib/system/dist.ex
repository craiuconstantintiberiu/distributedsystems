defmodule Dist do
  require Logger
  require Supervisor
  use Application

  def start(_type, _args) do
    Logger.info("Starting distributed system supervisor")
    children = [
      Supervisor.child_spec({TopLevelDistributedSystemSupervisor, {}}, id: :top_level_distributed_system_supervisor)
    ]

    opts = [strategy: :one_for_one, name: DistSupervisor]
    Supervisor.start_link(children, opts)
  end
end
