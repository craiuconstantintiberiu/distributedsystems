IEx.configure(inspect: [limit: :infinity])
Application.put_env(:elixir, :ansi_enabled, true)
IEx.configure(
  colors: [enabled: true, eval_result: [ :cyan, :bright ] ],
  default_prompt: [
    "\e[G",    # ANSI CHA, move cursor to column 1
    :blue,
    "%prefix", # IEx prompt variable
    ">",       # plain string
    :reset
  ] |> IO.ANSI.format |> IO.chardata_to_string
)
IO.puts("Hello world!")
