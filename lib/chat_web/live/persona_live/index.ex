defmodule ChatWeb.PersonaLive.Index do
  use ChatWeb, :live_view

  alias Chat.Conversations
  alias Chat.Conversations.Persona

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :personas, Conversations.list_personas())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Persona")
    |> assign(:persona, Conversations.get_persona!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Persona")
    |> assign(:persona, %Persona{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Personas")
    |> assign(:persona, nil)
  end

  @impl true
  def handle_info({ChatWeb.PersonaLive.FormComponent, {:saved, persona}}, socket) do
    {:noreply, stream_insert(socket, :personas, persona)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    persona = Conversations.get_persona!(id)
    {:ok, _} = Conversations.delete_persona(persona)

    {:noreply, stream_delete(socket, :personas, persona)}
  end
end
