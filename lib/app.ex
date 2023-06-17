defmodule App do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    # IEx.configure(inspect: [limit: :infinity])
    # name = String.to_atom("server_#{opts[:port]}")
    server_name = "app_#{opts[:port]}_#{opts[:index]}"
    Logger.info(server_name)

    case GenServer.start_link(__MODULE__, {:init_state, opts}, name: String.to_atom(server_name)) do
      {:ok, pid} ->
        Logger.info("App started on port #{opts[:port]} with pid #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} ->
        Logger.error(
          "App failed to start on port #{opts[:port]} with reason #{inspect(reason)}"
        )

        {:error, reason}
    end

    # GenServer.start_link(__MODULE__, {:init_state, opts}, name: {:local, opts[:port]})
  end

  def init({:init_state, opts}) do
    Logger.info("Initiating app on port #{opts[:port]}")
    Logger.info(opts)
    # accept(new_opts)
    {:ok, opts}
  end
end

defmodule App.Supervisor do
  use Supervisor
  require Logger

  def start_link(%{port: port, index: index} = init_arg) do
    Supervisor.start_link(__MODULE__, init_arg,
      name: String.to_atom("#{__MODULE__}_#{port}_#{index}")
    )
  end

  def init(%{port: port, index: index} = opts) do
    id = "port_#{port}_index_#{index}"

    children = [
      Supervisor.child_spec({App, [port: port, index: index]}, id: :"app_#{id}"),
      Supervisor.child_spec({Beb.Supervisor, opts}, id: :"beb_supervisor_#{id}"),
      Supervisor.child_spec({PerfectLink.Supervisor, opts}, id: :"pl_supervisor_#{id}"),
      Supervisor.child_spec({Queue.Supervisor, opts}, id: :"queue_supervisor_#{id}")

    ]

    Logger.info("Starting app, beb supeprvisor, pl supervisor #{id}")

    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}_#{port}_#{index}")
  end
end
