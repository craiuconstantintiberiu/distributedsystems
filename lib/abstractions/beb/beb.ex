defmodule Beb do
  use GenServer
  import Abstractionnaming
  require Logger

  def start_link(opts \\ []) do
    # IEx.configure(inspect: [limit: :infinity])
    # name = String.to_atom("server_#{opts[:port]}")
    server_name = "beb_#{opts[:port]}_#{opts[:index]}"
    Logger.info(server_name)

    case GenServer.start_link(__MODULE__, {:init_state, opts}, name: String.to_atom(get_beb_name(opts[:port], opts[:index]))) do
      {:ok, pid} ->
        Logger.info("Beb started on port #{opts[:port]} with pid #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} ->
        Logger.error(
          "Beb failed to start on port #{opts[:port]} with reason #{inspect(reason)}"
        )

        {:error, reason}
    end

    # GenServer.start_link(__MODULE__, {:init_state, opts}, name: {:local, opts[:port]})
  end

  def broadcast(name, msg) do
    Logger.info("Broadcast message #{inspect(msg)} to beb #{inspect(name)}")
    GenServer.call(name, {:broadcast, msg})
  end

  def handle_call({:broadcast, msg}, _from, state) do
    # Logger.info("Beb received message #{inspect(msg)}")
        Logger.info("Beb received broadcast message #{inspect(msg)}")

        # send the message to all the processes
        Enum.each(state[:processes], fn process ->
          Logger.info("Sending message #{inspect(msg)} to process #{inspect(process)}")
          
          GenServer.call(process, {:send, msg})
        end)

        {:reply, :ok, state}
    end

  def set_processes(name, processes) do
    Logger.info("Set processes for beb #{inspect(name)}")
    GenServer.call(name, {:set_processes, processes})
  end

  def handle_call({:set_processes, processes}, _from, state) do
    {:reply, :ok, Keyword.put(state, :processes, processes)}
  end

  @spec init({:init_state, any}) :: {:ok, any}
  def init({:init_state, opts}) do
    Logger.info("Initiating beb on port #{opts[:port]}")
    Logger.info(opts)
    # accept(new_opts)
    {:ok, opts}
  end
end

defmodule Beb.Supervisor do
  use Supervisor
  import Abstractionnaming
  require Logger


  def start_link(%{port: port, index: index} = init_arg) do
    Supervisor.start_link(__MODULE__, init_arg,
      name: String.to_atom("#{__MODULE__}_#{port}_#{index}")
    )
  end

  def init(%{port: port, index: index} = _opts) do
    id = "beb_port_#{port}_index_#{index}"

    children = [
      Supervisor.child_spec({Beb, [port: port, index: index]}, id: String.to_atom(get_beb_supervisor_name(port, index)))
    ]

    Logger.info("Starting beb child #{id}")

    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}_#{port}_#{index}")
  end
end
