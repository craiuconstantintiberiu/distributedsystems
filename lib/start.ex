defmodule Start do
  require CommunicationServer
  def start do
    # sapwn three communication servers on different ports
    #get pid of each server
    {:ok, pid1} = CommunicationServer.start_link([port: 5004, index: 1])
    {:ok, pid2} = CommunicationServer.start_link([port: 5005, index: 2])
    {:ok, pid3} = CommunicationServer.start_link([port: 5006, index: 3])

    #create a tcp listener on each port that is active and has controlling process
    {:ok, socket1} = :gen_tcp.listen(5004, [:binary, active: true, reuseaddr: true])
    {:ok, socket2} = :gen_tcp.listen(5005, [:binary, active: true, reuseaddr: true])
    {:ok, socket3} = :gen_tcp.listen(5006, [:binary, active: true, reuseaddr: true])

    {:ok, socket1} = :gen_tcp.accept(socket1)
    {:ok, socket2} = :gen_tcp.accept(socket2)
    {:ok, socket3} = :gen_tcp.accept(socket3)

    :gen_tcp.controlling_process(socket1, pid1)
    :gen_tcp.controlling_process(socket2, pid2)
    :gen_tcp.controlling_process(socket3, pid3)
  end
end
