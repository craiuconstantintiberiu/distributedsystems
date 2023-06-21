defmodule Abstractionnaming do
  #obtain name, based on abstraction type, port and index

  def get_name(abstraction, port, index) do
    "#{abstraction}_#{port}_#{index}"
  end

  def get_queue_name(port, index) do
    get_name("queue", port, index)
  end

  def get_pl_name(port, index) do
    get_name("pl", port, index)
  end

  def get_pl_supervisor_name(port, index) do
    get_name("pl_supervisor", port, index)
  end

  def get_queue_supervisor_name(port, index) do
    get_name("queue_supervisor", port, index)
  end

  @spec get_beb_name(any, any) :: <<_::16, _::_*8>>
  def get_beb_name(port, index) do
    get_name("beb", port, index)
  end

  def get_beb_supervisor_name(port, index) do
    get_name("beb_supervisor", port, index)
  end

  def get_app_name(port, index) do
    get_name("app", port, index)
  end

  def get_app_supervisor_name(port, index) do
    get_name("app_supervisor", port, index)
  end
end
