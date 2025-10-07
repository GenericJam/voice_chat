# lib/mix/tasks/echo.ex
defmodule Mix.Tasks.SetIp do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    # grab wan ip from canhazip and set variable to output
    IO.puts("Fetching current WAN IP from canhazip.com...")
    {:ok, %Req.Response{status: 200, body: ipv6}} = Req.get("http://canhazip.com")
    IO.inspect(ipv6)

    {:ok, %Req.Response{status: 200}} =
      Req.post("https://porkbun.com/api/json/v3/dns/editByNameType/chat.boltbrain.ca/AAAA/sub",
        json: %{
          secretapikey: "pk1_abaa9ebe1ba5e5bd1324ce03df4f703d505c91e47fe77638e6fa2f0b182e4913",
          apikey: "yobot",
          content: ipv6
        }
      )

  end
end
