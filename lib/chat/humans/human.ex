defmodule Chat.Humans.Human do
  use Ecto.Schema
  import Ecto.Changeset

  schema "humans" do
    field :name, :string
    field :hash, :string
    field :photo, :string

    belongs_to :persona, Chat.Conversations.Persona

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(human, attrs) do
    human
    |> cast(attrs, [:name, :hash, :photo])
    |> validate_required([:name])
  end

  def persona_changeset(user, attrs) do
    user
    |> cast(attrs, [:persona_id])
    |> validate_required([:persona_id])
    |> foreign_key_constraint(:persona_id)
    |> assoc_constraint(:persona)
  end
end
