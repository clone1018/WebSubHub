defmodule WebSubHub.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    belongs_to :topic, WebSubHub.Subscriptions.Topic
    field :callback_url, :string
    field :lease_seconds, :float
    field :expires_at, :naive_datetime
    field :secret, :string

    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:callback_url, :lease_seconds, :expires_at, :secret])
    |> validate_required([:callback_url, :lease_seconds, :expires_at])
  end
end
