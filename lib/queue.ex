defmodule Queue do
  use GenServer
  require Logger

  def start_link(opts \\ []) do

    server_name = "queue_#{opts[:port]}_#{opts[:index]}"
    Logger.info(server_name)

    case GenServer.start_link(__MODULE__, {:init_state, opts}, name: String.to_atom(server_name)) do
      {:ok, pid} ->
        Logger.info("Queue started on port #{opts[:port]} with pid #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} ->
        Logger.error(
          "Queue failed to start on port #{opts[:port]} with reason #{inspect(reason)}"
        )

        {:error, reason}
    end
    end

    def init({:init_state, opts}) do
    new_arg = Keyword.put(opts, :queue, :queue.new)
    {:ok, new_arg}
  end

  def enqueue(name, item) do
    GenServer.call(name, {:enqueue, item})
  end

  def dequeue(name) do
    GenServer.call(name, :dequeue)
  end

  def handle_call({:enqueue, item}, _from, %{queue: queue} = state) do
    Logger.info("Enqueueing item #{item}")
    {:reply, :ok, %{state | queue: enqueue(queue, item)}}
  end

  def handle_call(:dequeue, _from, %{queue: queue} = state) do
    Logger.info("Dequeueing")
    {{:value, value}, queue} = :queue.out(queue)
    Logger.info("Dequeued item #{value}")
    {:reply, value, %{state | queue: queue}}
  end
end


defmodule Queue.Supervisor do
  use Supervisor
  require Logger
  def start_link(%{port: port, index: index} = init_arg) do
    Logger.info("Starting supervisor.")
    Supervisor.start_link(__MODULE__, init_arg,
      name: String.to_atom("#{__MODULE__}_#{port}_#{index}")
    )
  end

  def init(%{port: port, index: index} = opts) do
    id = "#{port}_index_#{index}"
    Logger.info("Starting queue #{id}")

    children = [
      Supervisor.child_spec({Queue, [port: port, index: index]}, id: :"queue_#{id}")

    ]


    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}_#{port}_#{index}")
  end
end
