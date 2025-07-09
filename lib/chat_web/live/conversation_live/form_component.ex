defmodule ChatWeb.ConversationLive.FormComponent do
  use ChatWeb, :live_component

  alias Chat.Conversations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage conversation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="conversation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Conversation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{conversation: conversation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Conversations.change_conversation(conversation))
     end)}
  end

  @impl true
  def handle_event("validate", %{"conversation" => conversation_params}, socket) do
    changeset =
      Conversations.change_conversation(socket.assigns.conversation, conversation_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"conversation" => conversation_params}, socket) do
    save_conversation(socket, socket.assigns.action, conversation_params)
  end

  defp save_conversation(socket, :edit, conversation_params) do
    case Conversations.update_conversation(socket.assigns.conversation, conversation_params) do
      {:ok, conversation} ->
        notify_parent({:saved, conversation})

        {:noreply,
         socket
         |> put_flash(:info, "Conversation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_conversation(socket, :new, conversation_params) do
    case Conversations.create_conversation(conversation_params) do
      {:ok, conversation} ->
        notify_parent({:saved, conversation})

        {:noreply,
         socket
         |> put_flash(:info, "Conversation created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
