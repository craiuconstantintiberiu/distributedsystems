defmodule App do
  use GenServer
  alias Protobuf
  import Abstractionnaming
  require Logger
  require Queue
  require IEx

  def start_link(opts \\ []) do
    # IEx.configure(inspect: [limit: :infinity])
    # name = String.to_atom("server_#{opts[:port]}")
    server_name = get_app_name(opts[:port], opts[:index])
    Logger.info(server_name)

    case GenServer.start_link(__MODULE__, {:init_state, opts}, name: String.to_atom(get_app_name(opts[:port], opts[:index]))) do
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

  def get_processes(name, _state) do
    Logger.info("Get processes for app #{inspect(name)}")
    GenServer.call(name, {:processes})
  end


  def send(name, msg) do
    Logger.info("Send message #{inspect(msg)} to app #{inspect(name)}")
    GenServer.cast(name, {:send, msg})
  end


  def handle_call({:processes}, _from, state) do
    {:reply, Keyword.get(state, :processes), state}
  end

  def broadcast(value, state) do
    struct = %Main.Message{
      type: :BEB_BROADCAST,
      ToAbstractionId: "beb",
      bebBroadcast: %Main.BebBroadcast{
        message: %Main.Message{
          type: :APP_VALUE,
          appValue: %Main.AppValue{
            value: %Main.Value{
              defined: true,
              v: value
            }
          }
        }
      }
    }

    Queue.enqueue(String.to_atom(get_queue_name(state[:port], state[:index])), struct)
  end

  def handle_cast({:send, msg}, state) do
    Logger.info("App received message #{inspect(msg)}")
    cond do
      msg.procInitializeSystem ->

        # put all the processes in the procInitializeSystem in state
        new_state =
          Keyword.put(
            state,
            :processes,
            msg.procInitializeSystem.processes
          )

        Logger.info("State with new processes: #{inspect(new_state)}")
        Beb.set_processes(String.to_atom(get_beb_name(state[:port], state[:index])), msg.procInitializeSystem.processes)
        {:noreply, new_state}
      msg.procDestroySystem ->
        Logger.info("Ignoring destroy system message.")
        {:noreply, state}
      msg.appBroadcast ->
        Logger.info("Received broadcast message. Will create broadcast message, and send it to queue, which will send it to beb.")
        # Or should we send it to beb directly?
        # We should send it to the queue, which will send it to beb.

        #create broadcast message using protobuf
        #get value
        # IEx.pry()
        # Logger.info("msg.appBroadcast: #{inspect(msg.appBroadcast)}")
        # Logger.info("msg.appBroadcast.value: #{inspect(msg.appBroadcast.value)}")
        # Logger.info("msg.appBroadcast.value.v: #{inspect(msg.appBroadcast.value.v)}")

        value = msg.appBroadcast.value.v
        broadcast(value, state)
#        Logger.info("Value: #{inspect(value)}")
#        struct = %Main.Message{
#          type: :BEB_BROADCAST,
#          ToAbstractionId: "beb",
#          bebBroadcast: %Main.BebBroadcast{
#            message: %Main.Message{
#              type: :APP_VALUE,
#              appValue: %Main.AppValue{
#                value: %Main.Value{
#                  defined: true,
#                  v: value
#                }
#              }
#            }
#          }
#        }
#
#        Logger.info("Created broadcast message: #{inspect(struct)}")
#        #Pass to queue
#        Logger.info("Passing broadcast message to queue.")
#        Queue.enqueue(String.to_atom(get_queue_name(state[:port], state[:index])), struct)
        {:noreply, state}
      true ->
        Logger.warn("Received message that does not match anything: #{inspect(msg)}")
        {:noreply, state}
  end

  end
end

defmodule App.Supervisor do
  use Supervisor
  import Abstractionnaming
  require Logger

  def start_link(%{port: port, index: index} = init_arg) do
    Supervisor.start_link(__MODULE__, init_arg,
      name: String.to_atom("#{__MODULE__}_#{port}_#{index}")
    )
  end

  def init(%{port: port, index: index} = opts) do
    id = "port_#{port}_index_#{index}"

    children = [
      Supervisor.child_spec({App, [port: port, index: index]}, id: String.to_atom(get_app_name(port, index))),
      Supervisor.child_spec({Beb.Supervisor, opts}, id: String.to_atom(get_beb_supervisor_name(port, index))),
      Supervisor.child_spec({PerfectLink.Supervisor, opts}, id: String.to_atom(get_pl_supervisor_name(port, index))),
      Supervisor.child_spec({Queue.Supervisor, opts}, id: String.to_atom(get_queue_supervisor_name(port, index)))

    ]

    Logger.info("Starting app, beb supeprvisor, pl supervisor #{id}")

    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}_#{port}_#{index}")
  end
end
