defmodule ChatWeb.BotModelLive.Show do
  use ChatWeb, :live_view

  alias Chat.Bots

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:bot_model, Bots.get_bot_model!(id))}
  end

  defp page_title(:show), do: "Show Bot model"
  defp page_title(:edit), do: "Edit Bot model"
end
