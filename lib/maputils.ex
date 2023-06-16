defmodule MapUtils do
  def clean_map(map) do
    map
    |> Map.from_struct
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end
end
