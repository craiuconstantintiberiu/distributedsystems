defmodule PerfectLink do
  use GenServer
  alias ElixirSense.Log
  alias Protobuf
  require Logger

  def start_link(opts \\ []) do
    #name = String.to_atom("server_#{opts[:port]}")
    server_name="pl_#{opts[:port]}_#{opts[:index]}"
    Logger.info server_name
    case GenServer.start_link(__MODULE__, {:init_state, opts}, name: String.to_atom(server_name)) do
      {:ok, pid} ->
        Logger.info("PerfectLink started on port #{opts[:port]} with pid #{inspect pid}")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("PerfectLink failed to start on port #{opts[:port]} with reason #{inspect reason}")
        {:error, reason}
    end
    #GenServer.start_link(__MODULE__, {:init_state, opts}, name: {:local, opts[:port]})
  end



  def send_register_message(port, index) do
    Logger.info("Sending register message with index #{index} to port #{port}")
    host = "127.0.0.1"
        #struct =%Main.Value{:defined=> true, :v=>2}
        struct = %Main.Message{:type=>0,
          :networkMessage=>%Main.NetworkMessage{
          :senderHost=>"127.0.0.1",
          :senderListeningPort=>port,
          :message=>%Main.Message{
            :type=>1,
            :procRegistration=>%Main.ProcRegistration{
              :owner=>"tibi",
              :index=>index
            }
          }
          }}
        encoded =Main.Value.encode(struct)
        length = byte_size(encoded)
        bits = Integer.to_string(length,2)

        msg = <<0,0,0, length>> <> encoded


        {:ok, socket} = :gen_tcp.connect('localhost', 5000, [:binary])
        :ok = :gen_tcp.send(socket, msg)
        :ok = :gen_tcp.close(socket)
  end

  # def accept(opts) do
  #   {:ok, client} = :gen_tcp.accept(opts[:socket])
  #     Logger.info("Accept worked!")
  # end

  def init({:init_state, opts}) do
    Logger.info("Initiating pl")
    Logger.info(opts)
    {:ok, socket} = :gen_tcp.listen(opts[:port], [:binary, active: true, reuseaddr: true])
    Logger.info("Listening on port #{opts[:port]}")
    new_opts = Keyword.put(opts, :socket, socket)
    send_register_message(opts[:port], opts[:index])
    Logger.info("Register message sent with index #{opts[:index]} to port #{opts[:port]}")
    :gen_tcp.controlling_process(socket, self())
    accept(socket, self()) # Spawn a new process to accept connections
    # accept(new_opts)

    {:ok, new_opts}
  end

  defp create_message(_port, _index) do
    "Hello world!"
  end

  def accept(socket, genserver) do
    Task.start_link(fn ->
      Logger.info "Starting accept task on socket #{inspect socket}"
      {:ok, client} = :gen_tcp.accept(socket)
      Logger.info("Accept worked! #{inspect client}")
      # Set options
      :inet.setopts(client, [:binary, active: true, reuseaddr: true])
      #Controlling process needs to be set to genserver - pl link abstraction, it is initially set to the Task
      :gen_tcp.controlling_process(client, genserver)
      # Send the client back to the genserver for processing
      GenServer.cast(genserver, {:new_client, client})
    end)
  end

  def handle_call({:send, message}, {socket, opts}) do
    encoded = Main.Message.encode(message)
    length = byte_size(encoded)

    msg = <<0, 0, 0, length>> <> encoded

    :ok = :gen_tcp.send(socket, msg)
    :ok = :gen_tcp.close(socket)

    {:noreply, {socket, opts}}
  end

  def handle_call(:accept, {socket, opts}) do
    case :gen_tcp.accept(socket) do
      {:ok, client_socket} ->
        Logger.info("Accept worked!" + inspect client_socket)
        # GenServer.cast(genserver, {:new_client, client})

        # Process the client socket as necessary
      {:error, _} -> Logger.info("Error: Accept failed!")
        # Handle error
    end

    {:noreply, {socket, opts}}
  end

  def handle_cast({:new_client, client}, state) do
    # Start listening to the client
    Logger.info("New client: #{inspect client}")
    :inet.setopts(client, [:binary, active: true, reuseaddr: true])
    :gen_tcp.controlling_process(client, self())
    {:noreply, state}
  end

  def handle_info({:tcp_error, socket, reason}, state) do
    Logger.info("Received error on socket #{inspect socket}: #{inspect reason}")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("Received closed on socket #{inspect socket}")
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, <<size::unsigned-32, msg::binary>>}, state) do
    Logger.info("Received message: #{inspect(msg)}")
    decoded = Main.Message.decode(msg)
    Logger.info("Decoded message: #{inspect(decoded)}")
    Logger.info("Cleaned message: #{inspect(MapUtils.clean_map(decoded))}")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

end

# defmodule PerfectLink.A do

# end


# defmodule BestEffortBroadcast do
#   use GenServer

#   def start_link(port, index) do
#     {:ok, pl_pid} = PerfectLink.start_link(port, index)
#     GenServer.start_link(__MODULE__, {port, index, pl_pid})
#   end

#   def init({port, index, pl_pid}) do
#     Logger.info("Starting beb")
#     {:ok, {port, index, pl_pid, %{}}}
#   end

#   # Other callbacks omitted for brevity
# end

# defmodule Application do
#   use GenServer

#   def start_link(port, index) do
#     {:ok, beb_pid} = BestEffortBroadcast.start_link(port, index)
#     GenServer.start_link(__MODULE__, {port, index, beb_pid})
#   end

#   def init({port, index, beb_pid}) do
#     Logger.info("Starting application")
#     {:ok, {port, index, beb_pid, %{}}}
#   end

#   # Other callbacks omitted for brevity
# end

defmodule PerfectLink.Supervisor do
  use Supervisor
  require Logger

  def start_link(%{port: port, index: index} = init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: String.to_atom("#{__MODULE__}_#{port}_#{index}"))
  end

  def init(%{port: port, index: index} = _opts) do
    id = "pl_port_#{port}_index_#{index}"
    children = [
      Supervisor.child_spec({PerfectLink, [port: port, index: index]}, id: :"#{id}"),
    ]
    Logger.info("Starting pl child #{id}")

    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}_#{port}_#{index}")
  end
end

# defmodule BestEffortBroadcast.Supervisor do
#   use Supervisor

#   def start_link(init_arg) do
#     Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
#   end

#   def init({port, index}) do
#     children = [
#       {BestEffortBroadcast, {port, index}}
#     ]
#     Logger.info("Starting beb supervisor")
#     Supervisor.init(children, strategy: :one_for_one)
#   end
# end

# defmodule Application.Supervisor do
#   use Supervisor

#   def start_link(init_arg) do
#     Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
#   end

#   def init({port, index}) do
#     children = [
#       {Application, {port, index}}
#     ]
#     Logger.info("Starting application supervisor")
#     Supervisor.init(children, strategy: :one_for_one)
#   end
# end

# defmodule YourApplication do
#   require Logger
#   def start do
#     port = 5004  # Substitute with your own port
#     index = 1    # Substitute with your own index

#     children = [
#       {Application.Supervisor, {port, index}}
#     ]

#     opts = [strategy: :one_for_one, name: Application.Supervisor]
#     Logger.info("Starting yourapplication supervisor")
#     Supervisor.start_link(children, opts)
#   end
# end
