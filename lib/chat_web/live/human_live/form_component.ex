defmodule ChatWeb.HumanLive.FormComponent do
  use ChatWeb, :live_component

  alias Chat.Humans

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage human records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="human-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:hash]} type="text" label="Hash" />
        <.input field={@form[:photo]} type="text" label="Photo" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Human</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{human: human} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Humans.change_human(human))
     end)}
  end

  @impl true
  def handle_event("validate", %{"human" => human_params}, socket) do
    changeset = Humans.change_human(socket.assigns.human, human_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"human" => human_params}, socket) do
    save_human(socket, socket.assigns.action, human_params)
  end

  defp save_human(socket, :edit, human_params) do
    case Humans.update_human(socket.assigns.human, human_params) do
      {:ok, human} ->
        notify_parent({:saved, human})

        {:noreply,
         socket
         |> put_flash(:info, "Human updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_human(socket, :new, human_params) do
    case Humans.create_human(human_params) do
      {:ok, human} ->
        notify_parent({:saved, human})

        {:noreply,
         socket
         |> put_flash(:info, "Human created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
