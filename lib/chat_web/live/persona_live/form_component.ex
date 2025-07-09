defmodule ChatWeb.PersonaLive.FormComponent do
  use ChatWeb, :live_component

  alias Chat.Conversations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage persona records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="persona-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:avatar]} type="text" label="Avatar" />
        <.input field={@form[:role]} type="text" label="Role" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Persona</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{persona: persona} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Conversations.change_persona(persona))
     end)}
  end

  @impl true
  def handle_event("validate", %{"persona" => persona_params}, socket) do
    changeset = Conversations.change_persona(socket.assigns.persona, persona_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"persona" => persona_params}, socket) do
    save_persona(socket, socket.assigns.action, persona_params)
  end

  defp save_persona(socket, :edit, persona_params) do
    case Conversations.update_persona(socket.assigns.persona, persona_params) do
      {:ok, persona} ->
        notify_parent({:saved, persona})

        {:noreply,
         socket
         |> put_flash(:info, "Persona updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_persona(socket, :new, persona_params) do
    case Conversations.create_persona(persona_params) do
      {:ok, persona} ->
        notify_parent({:saved, persona})

        {:noreply,
         socket
         |> put_flash(:info, "Persona created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
