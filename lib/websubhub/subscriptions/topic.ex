defmodule WebSubHub.Subscriptions.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> unique_constraint([:url])
  end
end
