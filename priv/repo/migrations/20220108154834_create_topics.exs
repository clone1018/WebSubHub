defmodule WebSubHub.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :url, :string

      timestamps()
    end

    create unique_index(:topics, [:url])

    create table(:subscriptions) do
      add :topic_id, references(:topics)
      add :callback_url, :string
      add :lease_seconds, :float
      add :expires_at, :naive_datetime
      add :secret, :string, nullable: true

      timestamps()
    end

    create table(:updates) do
      add :topic_id, references(:topics)

      add :body, :binary
      add :headers, :binary
      add :content_type, :text
      add :links, {:array, :text}
      add :hash, :string

      timestamps()
    end

    create table(:subscription_updates) do
      add :update_id, references(:updates)
      add :subscription_id, references(:subscriptions)
      add :pushed_at, :naive_datetime
      add :status_code, :integer, nullable: true

      timestamps()
    end
  end
end
