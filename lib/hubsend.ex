defmodule Communication do
  use Agent
  alias Protobuf
  require Logger
  require IEx

  @doc """
  Starts a new bucket.
  """
  def send(port, index) do
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

  def accept(port) do
    {:ok, socket} =:gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Accept worked!")
    IO.inspect(client)
    serve(client)
    loop_acceptor(socket)
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

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn dict ->
      Map.pop(dict, key)
    end)
  end
end
