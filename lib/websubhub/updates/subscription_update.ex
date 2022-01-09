defmodule WebSubHub.Updates.SubscriptionUpdate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscription_updates" do
    belongs_to :update, WebSubHub.Updates.Update
    belongs_to :subscription, WebSubHub.Subscriptions.Subscription

    field :pushed_at, :naive_datetime
    field :status_code, :integer

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:pushed_at, :status_code])
    |> validate_required([:pushed_at, :status_code])
  end
end
