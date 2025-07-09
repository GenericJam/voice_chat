defmodule Chat.Conversations.Persona do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ["human", "bot"]

  schema "personas" do
    field :name, :string
    field :role, :string, default: "human"
    field :avatar, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(persona, attrs) do
    persona
    |> cast(attrs, [:name, :avatar, :role])
    |> validate_required([:name, :avatar, :role])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:name)
  end
end
