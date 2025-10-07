defmodule Chat.SetIp do
  def run do
    current_ipv6 = get_ipv6()

    # First, check if the current IP is different from what's in DNS
    records_response = list_dns_records()

    case records_response do
      {:ok, %{body: %{"records" => records}}} ->
        IO.inspect(records, label: "DNS Records")
        chat_aaaa =
          Enum.find(records, fn record ->
            record["type"] == "AAAA" and record["name"] == "chat.boltbrain.ca"
          end)

        if chat_aaaa do
          current_dns_ip = chat_aaaa["content"]
          record_id = chat_aaaa["id"]

          IO.puts("Current IPv6: #{current_ipv6}")
          IO.puts("DNS IPv6:     #{current_dns_ip}")

          if current_ipv6 == current_dns_ip do
            IO.puts("✅ DNS is already up to date!")
            :already_current
          else
            IO.puts("🔄 Updating DNS record...")
            update_dns_record(record_id, current_ipv6)
          end
        else
          IO.puts("❌ Could not find AAAA record for boltbrain.ca")
          {:error, :record_not_found}
        end

      error ->
        IO.puts("❌ Could not retrieve DNS records")
        IO.inspect(error)
        {:error, error}
    end
  end

  # Test function to manually update DNS record
  def test_update(record_id, ipv6) do
    update_dns_record(record_id, ipv6)
  end

  defp update_dns_record(record_id, ipv6) do
    response =
      Req.post("https://api.porkbun.com/api/json/v3/dns/edit/boltbrain.ca/#{record_id}",
        json: %{
          secretapikey: System.get_env("PORKBUN_SECRET_API_KEY"),
          apikey: System.get_env("PORKBUN_API_KEY"),
          name: "chat",
          type: "AAAA",
          content: ipv6,
          ttl: "600"
        }
      )

    case response do
      {:ok, %{status: 200, body: %{"status" => "SUCCESS"} = body}} ->
        IO.inspect(body)
        IO.puts("✅ DNS record updated successfully!")
        :ok

      {:ok, %{status: status, body: body}} ->
        IO.puts("❌ DNS update failed (status #{status})")
        IO.inspect(body)
        {:error, {status, body}}

      error ->
        IO.puts("❌ Request failed")
        IO.inspect(error)
        {:error, error}
    end
  end

  def list_dns_records do
    response =
      Req.post("https://api.porkbun.com/api/json/v3/dns/retrieve/boltbrain.ca",
        json: %{
          secretapikey: System.get_env("PORKBUN_SECRET_API_KEY"),
          apikey: System.get_env("PORKBUN_API_KEY")
        }
      )

    case response do
      {:ok, %{status: 200, body: %{"records" => records}}} ->
        IO.puts("✅ Found #{length(records)} DNS records:")

        Enum.each(records, fn record ->
          IO.puts(
            "  - #{record["type"]} #{record["name"]} -> #{record["content"]} (ID: #{record["id"]})"
          )
        end)

      {:ok, %{status: status, body: body}} ->
        IO.puts("❌ Failed to retrieve DNS records (status #{status})")
        IO.inspect(body)

      error ->
        IO.puts("❌ Request failed")
        IO.inspect(error)
    end

    response
  end

  @services [
    "https://api.ipify.org",
    "https://ipinfo.io/ip",
    "https://icanhazip.com",
    "https://ident.me",
    "https://checkip.amazonaws.com"
  ]

  def get_ipv4 do
    @services
    |> Enum.find_value(fn service ->
      case Req.get(service, receive_timeout: 5000) do
        {:ok, %{body: ip}} when is_binary(ip) ->
          String.trim(ip)

        _ ->
          nil
      end
    end)
  end

  def get_ipv6 do
    Req.get("https://api64.ipify.org",
      connect_options: [transport_opts: [inet6: true]],
      receive_timeout: 5000
    )
    |> case do
      {:ok, %{body: ip}} -> String.trim(ip)
      _ -> nil
    end
  end

  def get_both do
    %{
      ipv4: get_ipv4(),
      ipv6: get_ipv6()
    }
  end
end
