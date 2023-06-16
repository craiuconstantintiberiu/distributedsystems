defmodule PerfectLink do
  use GenServer
  alias Protobuf
  require Logger

  def start_link(opts \\ []) do
    # IEx.configure(inspect: [limit: :infinity])
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
      # GenServer.call(genserver, {:new_client, client})
      accept(socket, genserver)
    end)
  end

  def handle_call({:send, message}, {socket} = state) do
    encoded = Main.Message.encode(message)
    length = byte_size(encoded)

    msg = <<0, 0, 0, length>> <> encoded

    :ok = :gen_tcp.send(socket, msg)
    :ok = :gen_tcp.close(socket)

    {:noreply, state}
  end

  def handle_call(:accept, {socket} = state) do
    case :gen_tcp.accept(socket) do
      {:ok, client_socket} ->
        Logger.info("Accept worked!" + inspect client_socket)
        Logger.info("Accept worked!" + inspect state)

        # GenServer.cast(genserver, {:new_client, client})

        # Process the client socket as necessary
      {:error, _} -> Logger.info("Error: Accept failed!")
        # Handle error
    end

    {:noreply, state}
  end

  # def handle_call({:new_client, client}, _from, state) do
  #   # Start listening to the client
  #   Logger.info("New client: #{inspect client}")
  #   :inet.setopts(client, [:binary, active: true, reuseaddr: true])
  #   :gen_tcp.controlling_process(client, self())
  #   Logger.info("New client! State: #{inspect state}")
  #   {:reply, :ok, state}
  # end

  def handle_info({:tcp_error, socket, reason}, state) do
    Logger.info("Received error on socket #{inspect socket}: #{inspect reason}")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("Received closed on socket #{inspect socket}")
    {:noreply, state}
  end

  def handle_info({:tcp, socket, <<size::unsigned-32, msg::binary>>}, state) do
    # Logger.info("Received message: #{inspect(msg)}")
    decoded = Main.Message.decode(msg)
    Logger.info("Decoded message: #{inspect(decoded)}")
    # Logger.info(IEx.Info.info decoded)
    # Logger.info("Cleaned message: #{inspect(MapUtils.clean_struct(decoded))}")
    Logger.info("Type: #{decoded.type}")
    Logger.info("NetworkMessage: #{inspect(decoded.networkMessage)}")
    final_message=decoded.networkMessage.message
    Logger.info("NetworkMessageMessage: #{inspect(final_message)}")


    if final_message.procInitializeSystem != nil do
      Logger.info("NetworkMessageMessageProcInitializeSystem: #{inspect(final_message.procInitializeSystem)}")
      Logger.info("NetworkMessageMessageProcInitializeSystem: #{inspect(final_message.procInitializeSystem.processes)}")

      #put all the processes in the procInitializeSystem in state
      new_state = Keyword.put(state, :processes, decoded.networkMessage.message.procInitializeSystem.processes)
      Logger.info("State with new processes: #{inspect(new_state)}")
      {:noreply, new_state}

    end
    if final_message.procDestroySystem != nil do
      Logger.info("Received procDestroySystem message. Ignoring")
      {:noreply, state}
    end
    if final_message.appBroadcast != nil do
      Logger.info("Received message app.Broadcast (should be passed to hub or put in queue): #{inspect(final_message.appBroadcast)}")
      Logger.info("Value: #{inspect(final_message.appBroadcast.value)}")
      value = final_message.appBroadcast.value
      Logger.info("Value: #{inspect(value)}")

      #send message to all processes in state
      Logger.info("State: #{inspect(state)}")
      Logger.info("Processes: #{inspect(Keyword.get(state, :processes))}")


      Logger
      struct = %Main.Message{:type=>0,
          :networkMessage=>%Main.NetworkMessage{
          :senderHost=>"127.0.0.1",
          :senderListeningPort=>5001,
          :message=>%Main.Message{
            :type=>1,
            :procRegistration=>%{
              :owner=>"tibi",
              :index=>2
            }
          }
          }}
        encoded =Main.Value.encode(struct)
        length = byte_size(encoded)
        beb_broadcast = <<0,0,0, length>> <> encoded
      # broadcast_message =
      {:noreply, state}
    end



    # :gen_tcp.close(socket)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

end

defmodule PerfectLink.Supervisor do
  use Supervisor
  require Logger

  @spec start_link(%{:index => any, :port => any, optional(any) => any}) ::
          :ignore | {:error, any} | {:ok, pid}
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
