defmodule WebSubHub.Repo.Migrations.LongerEverything do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      modify :url, :text
    end

    alter table(:subscriptions) do
      modify :callback_url, :text
    end
  end
end
