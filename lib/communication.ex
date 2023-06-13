defmodule CommunicationServer do
  use GenServer
  alias Protobuf
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def send(port, index) do
    GenServer.cast(__MODULE__, {:send, port, index})
  end

  def accept(port) do
    GenServer.cast(__MODULE__, {:accept, port})
  end

  defp serve(socket) do
    msg = read_line(socket)

    IO.inspect(msg)

    x = Main.Message.decode(msg)
    IO.inspect(x)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, <<_rest::binary-size(4), encoded::binary-size(15), _rest2::binary-size(4)>>} = :gen_tcp.recv(socket, 0)
    # {:ok,<<data::binary-size(4)>>} = :gen_tcp.recv(socket, 4)
    # size = :binary.decode_unsigned(data)
    # {:ok, encoded} = :gen_tcp.recv(socket,size)
    # IEx.pry()
    message = Main.Message.decode(encoded)
    # message = Protobuf.decode(encoded, Main.Message)
    IO.inspect(message)
    message
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  def init(opts) do
    Logger.info("Starting CommunicationServer on port #{opts[:port]} with index #{opts[:index]}")
    host = "127.0.0.1"
    struct = %Main.Message{
      :type => 0,
      :networkMessage => %Main.NetworkMessage{
        :senderHost => "127.0.0.1",
        :senderListeningPort => opts[:port],
        :message => %Main.Message{
          :type => 1,
          :procRegistration => %Main.ProcRegistration{
            :owner => "tibi",
            :index => opts[:index]
          }
        }
      }
    }
    encoded = Main.Value.encode(struct)
    length = byte_size(encoded)
    bits = Integer.to_string(length, 2)

    msg = <<0, 0, 0, length>> <> encoded

    {:ok, socket} = :gen_tcp.connect('localhost', 5000, [:binary])
    :ok = :gen_tcp.send(socket, msg)
    :ok = :gen_tcp.close(socket)

    Logger.info("Sent registration message to master")


    # {:ok, _socket} = :gen_tcp.listen(opts[:port], [:binary, packet: :line, active: false, reuseaddr: true])
    # Logger.info("Accepting connections on port #{opts[:port]}")
    {:ok, opts}
  end

  def handle_cast({:send, port, index}, _state) do
    host = "127.0.0.1"
    struct = %Main.Message{
      :type => 0,
      :networkMessage => %Main.NetworkMessage{
        :senderHost => "127.0.0.1",
        :senderListeningPort => port,
        :message => %Main.Message{
          :type => 1,
          :procRegistration => %Main.ProcRegistration{
            :owner => "tibi",
            :index => index
          }
        }
      }
    }
    encoded = Main.Value.encode(struct)
    length = byte_size(encoded)
    bits = Integer.to_string(length, 2)

    msg = <<0, 0, 0, length>> <> encoded

    {:ok, socket} = :gen_tcp.connect('localhost', 5000, [:binary])
    :ok = :gen_tcp.send(socket, msg)
    :ok = :gen_tcp.close(socket)

    {:noreply, nil}
  end

  def handle_cast({:accept, port}, _state) do
    {:ok, socket} = :gen_tcp.accept(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accept worked!")
    IO.inspect(socket)
    serve(socket)
    {:noreply, nil}
  end

  #create a handler for the :tcp message
  def handle_info({:tcp, socket, data}, state) do
    Logger.info("Data: #{inspect data}")
    # Get the size of the message

    <<_rest::binary-size(4), encoded::binary>> = data
    Logger.info("Encoded: #{inspect encoded}")
    message = Protobuf.decode(encoded, Main.Message)
    # message = Main.Message.decode(encoded)
    Logger.info("Message: #{inspect message}")
    {:noreply, state}
  end

  def handle_info({:tcp_error, socket, reason}, state) do
    Logger.info("Received error on socket #{inspect socket}")
    end

    def handle_info({:tcp_closed, socket}, state) do
      Logger.info("Received closed on socket #{inspect socket}")
    end

end
