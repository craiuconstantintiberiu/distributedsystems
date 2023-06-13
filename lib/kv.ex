defmodule KV do
  use Protobuf, protoc_gen_elixir_version: "0.10.0", syntax: :proto3
  @moduledoc """
  Documentation for `KV`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> KV.hello()
      :world

  """
  def hello do
    :world
  end
end
