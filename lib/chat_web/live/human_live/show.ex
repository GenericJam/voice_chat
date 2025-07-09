defmodule ChatWeb.HumanLive.Show do
  use ChatWeb, :live_view

  alias Chat.Humans

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:human, Humans.get_human!(id))}
  end

  defp page_title(:show), do: "Show Human"
  defp page_title(:edit), do: "Edit Human"
end
