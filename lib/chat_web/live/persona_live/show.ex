defmodule ChatWeb.PersonaLive.Show do
  use ChatWeb, :live_view

  alias Chat.Conversations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:persona, Conversations.get_persona!(id))}
  end

  defp page_title(:show), do: "Show Persona"
  defp page_title(:edit), do: "Edit Persona"
end
