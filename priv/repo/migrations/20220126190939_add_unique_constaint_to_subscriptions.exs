defmodule WebSubHub.Repo.Migrations.AddUniqueConstaintToSubscriptions do
  use Ecto.Migration

  def change do
    create unique_index(:subscriptions, [:topic_id, :callback_url])
  end
end
