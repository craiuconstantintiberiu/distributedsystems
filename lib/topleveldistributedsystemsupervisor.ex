defmodule TopLevelDistributedSystemSupervisor do
  use Supervisor
  require Logger

  def start_link(init_arg) do
    Logger.info("Starting top level supervisor")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info("Starting top level supervisor on ports 5004, 5005, 5006")
    children = [
      Supervisor.child_spec({App.Supervisor, %{port: 5004, index: 1}}, id: :app_supervisor_1_port_5004_index_1),
      Supervisor.child_spec({App.Supervisor, %{port: 5005, index: 2}}, id: :app_supervisor_2_port_5005_index_2),
      Supervisor.child_spec({App.Supervisor, %{port: 5006, index: 3}}, id: :app_supervisor_3_port_5006_index_3),
    ]

    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}toplevel_supervisor_5004_5005_5006")
  end
end
