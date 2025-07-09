defmodule ChatWeb.HumanLive.Index do
  use ChatWeb, :live_view

  alias Chat.Humans
  alias Chat.Humans.Human

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :humans, Humans.list_humans())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Human")
    |> assign(:human, Humans.get_human!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Human")
    |> assign(:human, %Human{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Humans")
    |> assign(:human, nil)
  end

  @impl true
  def handle_info({ChatWeb.HumanLive.FormComponent, {:saved, human}}, socket) do
    {:noreply, stream_insert(socket, :humans, human)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    human = Humans.get_human!(id)
    {:ok, _} = Humans.delete_human(human)

    {:noreply, stream_delete(socket, :humans, human)}
  end
end
