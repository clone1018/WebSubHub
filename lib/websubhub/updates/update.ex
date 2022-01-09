defmodule WebSubHub.Updates.Update do
  use Ecto.Schema
  import Ecto.Changeset

  schema "updates" do
    belongs_to :topic, WebSubHub.Subscriptions.Topic

    field :body, :binary
    field :headers, WebSubHub.Updates.Headers
    field :content_type, :string
    field :links, {:array, :string}
    field :hash, :string

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:body, :headers, :content_type, :hash, :links])
    |> validate_required([:body, :content_type, :hash, :links])
  end
end
