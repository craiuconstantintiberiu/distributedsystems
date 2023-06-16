

# defmodule Application do
#   use GenServer

#   def start_link(port, index) do
#     {:ok, beb_pid} = BestEffortBroadcast.start_link(port, index)
#     GenServer.start_link(__MODULE__, {port, index, beb_pid})
#   end

#   def init({port, index, beb_pid}) do
#     Logger.info("Starting application")
#     {:ok, {port, index, beb_pid, %{}}}
#   end

#   # Other callbacks omitted for brevity
# end

# defmodule BestEffortBroadcast.Supervisor do
#   use Supervisor

#   def start_link(init_arg) do
#     Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
#   end

#   def init({port, index}) do
#     children = [
#       {BestEffortBroadcast, {port, index}}
#     ]
#     Logger.info("Starting beb supervisor")
#     Supervisor.init(children, strategy: :one_for_one)
#   end
# end

# defmodule Application.Supervisor do
#   use Supervisor

#   def start_link(init_arg) do
#     Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
#   end

#   def init({port, index}) do
#     children = [
#       {Application, {port, index}}
#     ]
#     Logger.info("Starting application supervisor")
#     Supervisor.init(children, strategy: :one_for_one)
#   end
# end

# defmodule YourApplication do
#   require Logger
#   def start do
#     port = 5004  # Substitute with your own port
#     index = 1    # Substitute with your own index

#     children = [
#       {Application.Supervisor, {port, index}}
#     ]

#     opts = [strategy: :one_for_one, name: Application.Supervisor]
#     Logger.info("Starting yourapplication supervisor")
#     Supervisor.start_link(children, opts)
#   end
# end
