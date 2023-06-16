defmodule MapUtils do
  def clean_struct(map) do
    map
    |> Map.from_struct()
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end
end
