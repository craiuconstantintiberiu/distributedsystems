defmodule BestEffortBroadcast do
  require PL

  def broadcast(message) do
    processes = PL.get_processes()  # Get the list of processes from the Perfect Point-to-Point Links (PL) abstraction

    # Broadcast the message to all processes using PL
    Enum.each(processes, fn process ->
      PL.send(process, %Message{type: :BEB_DELIVER, bebDeliver: %BebDeliver{message: message}})
    end)
  end

  def handle_message(%Message{type: :BEB_DELIVER, bebDeliver: %BebDeliver{message: message}} = message) do
    # Upon receiving the BEB_DELIVER message, deliver the message locally
    deliver_message(message)
  end

  defp deliver_message(message) do
    # Implement the logic to handle the delivered message
    IO.puts("Delivered message: #{inspect message}")
  end
end
