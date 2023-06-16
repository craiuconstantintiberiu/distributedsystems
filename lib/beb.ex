defmodule Beb do
  use GenServer
  require Logger
  
  def start_link(opts \\ []) do
    # IEx.configure(inspect: [limit: :infinity])
    # name = String.to_atom("server_#{opts[:port]}")
    server_name = "beb_#{opts[:port]}_#{opts[:index]}"
    Logger.info(server_name)

    case GenServer.start_link(__MODULE__, {:init_state, opts}, name: String.to_atom(server_name)) do
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

  def init({:init_state, opts}) do
    Logger.info("Initiating beb on port #{opts[:port]}")
    Logger.info(opts)
    # accept(new_opts)
    {:ok, opts}
  end
end

defmodule Beb.Supervisor do
  use Supervisor
  require Logger


  def start_link(%{port: port, index: index} = init_arg) do
    Supervisor.start_link(__MODULE__, init_arg,
      name: String.to_atom("#{__MODULE__}_#{port}_#{index}")
    )
  end

  def init(%{port: port, index: index} = _opts) do
    id = "beb_port_#{port}_index_#{index}"

    children = [
      Supervisor.child_spec({Beb, [port: port, index: index]}, id: :"#{id}")
    ]

    Logger.info("Starting beb child #{id}")

    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}_#{port}_#{index}")
  end
end

# defmodule BestEffortBroadcast do
#   require PL

#   def broadcast(message) do
#     processes = PL.get_processes()  # Get the list of processes from the Perfect Point-to-Point Links (PL) abstraction

#     # Broadcast the message to all processes using PL
#     Enum.each(processes, fn process ->
#       # PL.send(process, %Message{type: :BEB_DELIVER, bebDeliver: %BebDeliver{message: message}})
#     end)
#   end

#   def handle_message(%Message{type: :BEB_DELIVER, bebDeliver: %BebDeliver{message: message}} = message) do
#     # Upon receiving the BEB_DELIVER message, deliver the message locally
#     deliver_message(message)
#   end

#   defp deliver_message(message) do
#     # Implement the logic to handle the delivered message
#     IO.puts("Delivered message: #{inspect message}")
#   end
# end
