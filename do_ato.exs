defmodule EnvyScript do

  def run_ato([]) do
    """
    Account Takeover Tool v1.0

    Example usage, default rate limit (60 requests per minute):
    mix run do_ato.exs credentials_10.txt
    
    Example usage, custom rate limit (100 requests per minute): 
    mix run do_ato.exs credentials_10.txt 100
    """
  end

  def run_ato([filename]) do
    pairs = parse_file(filename)
    Envy.ato(pairs)
  end
  
  def run_ato([filename, rate_limit]) do
    pairs = parse_file(filename)
    irl = String.to_integer(rate_limit)
    Envy.ato(pairs, irl)
  end
  
  def run_ato(_), do: "Error: too many arguments"
  
  def parse_file(filename) do
    filename
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(fn x -> String.split(x, ",", trim: true) end)
  end
end

System.argv()
|> EnvyScript.run_ato()
|> IO.puts()
