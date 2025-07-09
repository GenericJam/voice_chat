defmodule ChatWeb.BotModelLive.Index do
  use ChatWeb, :live_view

  alias Chat.Bots
  alias Chat.Bots.BotModel

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :bot_models, Bots.list_bot_models())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Bot model")
    |> assign(:bot_model, Bots.get_bot_model!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Bot model")
    |> assign(:bot_model, %BotModel{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Bot models")
    |> assign(:bot_model, nil)
  end

  @impl true
  def handle_info({ChatWeb.BotModelLive.FormComponent, {:saved, bot_model}}, socket) do
    {:noreply, stream_insert(socket, :bot_models, bot_model)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bot_model = Bots.get_bot_model!(id)
    {:ok, _} = Bots.delete_bot_model(bot_model)

    {:noreply, stream_delete(socket, :bot_models, bot_model)}
  end
end
