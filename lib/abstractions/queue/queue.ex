defmodule Queue do
  use GenServer
  import Abstractionnaming
  require Logger

  def start_link(opts \\ []) do
    server_name = "queue_#{opts[:port]}_#{opts[:index]}"
    Logger.info(server_name)

    case GenServer.start_link(__MODULE__, {:init_state, opts},
           name: String.to_atom(get_queue_name(opts[:port], opts[:index]))
         ) do
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
    new_args = Map.new(opts)
    new_args = Map.put(new_args, :queue, :queue.new())
    {:ok, new_args, {:continue, :process_queue}}
  end

  def handle_continue(:process_queue, state) do
    schedule_work()
    {:noreply, state}
  end

  def handle_info(:work, state) do
    case :queue.out(state.queue) do
      {:empty, _} ->
        # Logger.info("Queue is empty")
        schedule_work()
        {:noreply, state}

      {{:value, item}, new_queue} ->
        Logger.info("Queue is not empty. Dequeuing first.")
        response = process_item(state, item)

        cond do
          response == {:ok, :sent} ->
            Logger.info("Dequeued item and processed.")
            schedule_work()
            {:noreply, %{state | queue: new_queue}}

          true ->
            Logger.info("Reenqued item as message type was not known.")
            schedule_work()

            {:noreply, state}
        end
    end
  end

  defp schedule_work() do
    # schedule to run every second
    Process.send_after(self(), :work, 1_000)
  end

  defp process_item(state, item) do
    # Here you will process the item based on its type field
    Logger.info("Queue: Processing item #{inspect(item)}")
    abstraction_id = Map.get(item, :ToAbstractionId)
    cond do
      item.procInitializeSystem ->
        # put all the processes in the procInitializeSystem in state
        App.send(
          String.to_atom(get_app_name(state[:port], state[:index])),
          item
        )

        {:ok, :sent}

      item.procDestroySystem ->
        App.send(
          String.to_atom(get_app_name(state[:port], state[:index])),
          item
        )

        {:ok, :sent}

      item.bebBroadcast ->
        Beb.broadcast(
          String.to_atom(get_beb_name(state[:port], state[:index])),
          item
        )

        {:ok, :sent}
      abstraction_id == "app" ->
        # Here, you can write your logic to pass the message to the corresponding abstraction
        Logger.info("Queue: Sending message to abstraction #{abstraction_id}")
        App.send(
          String.to_atom(get_name(abstraction_id, state[:port], state[:index])),
          item
        )

        {:ok, :sent}
      abstraction_id == "beb" ->
        Logger.info("Queue: Sending message to abstraction #{abstraction_id}")
        Beb.send(
          String.to_atom(get_name(abstraction_id, state[:port], state[:index])),
          item
        )

        {:ok, :sent}
      true ->
        # default case, equivalent to 'else'
        Logger.info("Unknown message. Reenquing")
        {:error, :unknown_message}
    end
  end

  def enqueue(name, item) do
    Logger.info("Enqueueing item #{inspect(item)} on queue #{name}")
    GenServer.cast(name, {:enqueue, item})
  end

  def dequeue(name) do
    GenServer.cast(name, :dequeue)
  end

  def handle_cast({:enqueue, item}, %{queue: queue} = state) do
    Logger.info("Enqueueing item #{inspect(item)}")
    {:noreply, %{state | queue: :queue.in(item, queue)}}
  end

  def handle_cast(:dequeue, %{queue: queue} = state) do
    Logger.info("Dequeueing")
    {{:value, value}, queue} = :queue.out(queue)
    Logger.info("Dequeued item #{inspect(value)}")
    {:noreply, %{state | queue: queue}}
  end

  def handle_cast(msg, %{queue: queue} = state) do
    Logger.info("Unknown message #{inspect(msg)}")
    {:noreply, %{state | queue: queue}}
  end
end

defmodule Queue.Supervisor do
  use Supervisor
  import Abstractionnaming
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
      Supervisor.child_spec({Queue, [port: port, index: index]},
        id: String.to_atom(get_queue_name(port, index))
      )
    ]

    Supervisor.init(children, strategy: :one_for_one, name: "#{__MODULE__}_#{port}_#{index}")
  end
end
