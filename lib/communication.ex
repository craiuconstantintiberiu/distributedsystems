# defmodule CommunicationServer do
#   use GenServer
#   alias Protobuf
#   require Logger

#   def start_link(opts \\ []) do
#     #name = String.to_atom("server_#{opts[:port]}")
#     name = {:global, String.to_atom("server_#{opts[:port]}")}
#     GenServer.start_link(__MODULE__, {:init_state, opts}, name: name)
#     #GenServer.start_link(__MODULE__, {:init_state, opts}, name: {:local, opts[:port]})
#   end

#   def sendCom(port, message) do
#     GenServer.call(self(), {:send, message, :port, port})
#   end

#   def accept(port) do
#     GenServer.call({:local, port}, :accept)
#   end

#   def init({:init_state, opts}) do
#     {:ok, socket} = :gen_tcp.listen(opts[:port], [:binary, active: false, reuseaddr: true])
#     sendCom(self(), {:send, create_message(opts[:port], opts[:index])})
#     {:ok, {socket, opts}}
#   end

#   defp create_message(port, index) do
#     # Your message creation logic goes here
#   end

#   def handle_call({:send, message}, {socket, _opts}) do
#     encoded = Main.Message.encode(message)
#     length = byte_size(encoded)

#     msg = <<0, 0, 0, length>> <> encoded

#     :ok = :gen_tcp.send(socket, msg)
#     :ok = :gen_tcp.close(socket)

#     {:noreply, {socket, _opts}}
#   end

#   def handle_call(:accept, {socket, _opts}) do
#     case :gen_tcp.accept(socket) do
#       {:ok, client_socket} ->
#         Logger.info("Accept worked!")
#         # Process the client socket as necessary
#       {:error, _} ->
#         # Handle error
#     end

#     {:noreply, {socket, _opts}}
#   end

#   def handle_info(msg, state) do
#     Logger.warn("Received unexpected message: #{inspect(msg)}")
#     {:noreply, state}
#   end

#   def handle_info({:tcp_error, socket, reason}, state) do
#     Logger.info("Received error on socket #{inspect socket}")
#     {:noreply, state}
#   end

#   def handle_info({:tcp_closed, socket}, state) do
#     Logger.info("Received closed on socket #{inspect socket}")
#     {:noreply, state}
#   end
# end
