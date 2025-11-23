defmodule Chat.SetIp do
  def run do
    current_ipv4 = get_ipv4()
    current_ipv6 = get_ipv6()

    IO.puts("\n📡 Current IPs:")
    IO.puts("  IPv4: #{current_ipv4 || "N/A"}")
    IO.puts("  IPv6: #{current_ipv6 || "N/A"}")

    # First, check if the current IPs are different from what's in DNS
    records_response = list_dns_records()

    case records_response do
      {:ok, %{body: %{"records" => records}}} ->
        IO.inspect(records, label: "DNS Records")

        # Find A record (IPv4)
        chat_a =
          Enum.find(records, fn record ->
            record["type"] == "A" and record["name"] == "chat.boltbrain.ca"
          end)

        # Find AAAA record (IPv6)
        chat_aaaa =
          Enum.find(records, fn record ->
            record["type"] == "AAAA" and record["name"] == "chat.boltbrain.ca"
          end)

        results = []

        # Check and update IPv4
        results =
          if chat_a && current_ipv4 do
            current_dns_ipv4 = chat_a["content"]
            record_id = chat_a["id"]

            IO.puts("\n🔍 IPv4 Status:")
            IO.puts("  Current IPv4: #{current_ipv4}")
            IO.puts("  DNS IPv4:     #{current_dns_ipv4}")

            result =
              if current_ipv4 == current_dns_ipv4 do
                IO.puts("  ✅ IPv4 DNS is already up to date!")
                {:ipv4, :already_current}
              else
                IO.puts("  🔄 Updating IPv4 DNS record...")
                update_result = update_dns_record(record_id, "A", current_ipv4)
                {:ipv4, update_result}
              end

            [result | results]
          else
            if !chat_a do
              IO.puts("\n❌ Could not find A record for chat.boltbrain.ca")
            end

            if !current_ipv4 do
              IO.puts("\n⚠️  Could not get current IPv4")
            end

            results
          end

        # Check and update IPv6
        results =
          if chat_aaaa && current_ipv6 do
            current_dns_ipv6 = chat_aaaa["content"]
            record_id = chat_aaaa["id"]

            IO.puts("\n🔍 IPv6 Status:")
            IO.puts("  Current IPv6: #{current_ipv6}")
            IO.puts("  DNS IPv6:     #{current_dns_ipv6}")

            result =
              if current_ipv6 == current_dns_ipv6 do
                IO.puts("  ✅ IPv6 DNS is already up to date!")
                {:ipv6, :already_current}
              else
                IO.puts("  🔄 Updating IPv6 DNS record...")
                update_result = update_dns_record(record_id, "AAAA", current_ipv6)
                {:ipv6, update_result}
              end

            [result | results]
          else
            if !chat_aaaa do
              IO.puts("\n❌ Could not find AAAA record for chat.boltbrain.ca")
            end

            if !current_ipv6 do
              IO.puts("\n⚠️  Could not get current IPv6")
            end

            results
          end

        case results do
          [] -> {:error, :no_records_updated}
          results -> {:ok, results}
        end

      error ->
        IO.puts("❌ Could not retrieve DNS records")
        IO.inspect(error)
        {:error, error}
    end
  end

  # Test function to manually update DNS record
  def test_update(record_id, type, ip) do
    update_dns_record(record_id, type, ip)
  end

  defp update_dns_record(record_id, type, ip) do
    response =
      Req.post("https://api.porkbun.com/api/json/v3/dns/edit/boltbrain.ca/#{record_id}",
        json: %{
          secretapikey: System.get_env("PORKBUN_SECRET_API_KEY"),
          apikey: System.get_env("PORKBUN_API_KEY"),
          name: "chat",
          type: type,
          content: ip,
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
