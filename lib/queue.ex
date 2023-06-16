defmodule Queue do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    Logger.info("Starting queue")
    GenServer.start_link(__MODULE__, %{}, name: "#{__MODULE__}_#{opts[:port]}_#{opts[:index]}")
  end

  def init(init_arg) do
    {:ok, %{port: init_arg[:port], index: init_arg[:index], queue: :queue.new}}
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
