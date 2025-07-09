defmodule ChatWeb.BotModelLive.FormComponent do
  use ChatWeb, :live_component

  alias Chat.Bots

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage bot_model records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="bot_model-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Bot model</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{bot_model: bot_model} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Bots.change_bot_model(bot_model))
     end)}
  end

  @impl true
  def handle_event("validate", %{"bot_model" => bot_model_params}, socket) do
    changeset = Bots.change_bot_model(socket.assigns.bot_model, bot_model_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"bot_model" => bot_model_params}, socket) do
    save_bot_model(socket, socket.assigns.action, bot_model_params)
  end

  defp save_bot_model(socket, :edit, bot_model_params) do
    case Bots.update_bot_model(socket.assigns.bot_model, bot_model_params) do
      {:ok, bot_model} ->
        notify_parent({:saved, bot_model})

        {:noreply,
         socket
         |> put_flash(:info, "Bot model updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_bot_model(socket, :new, bot_model_params) do
    case Bots.create_bot_model(bot_model_params) do
      {:ok, bot_model} ->
        notify_parent({:saved, bot_model})

        {:noreply,
         socket
         |> put_flash(:info, "Bot model created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
