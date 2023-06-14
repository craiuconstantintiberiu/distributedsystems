defmodule Start do
  @moduledoc """
  Starts Communication Servers on specific ports.
  """

  def start do
    start_servers([
      [port: 5004, index: 1],
      [port: 5005, index: 2],
      [port: 5006, index: 3]
    ])
  end

  defp start_servers([]), do: :ok

  defp start_servers([opts | rest]) do
    {:ok, _pid} = CommunicationServer.start_link(opts)
    start_servers(rest)
  end
end
