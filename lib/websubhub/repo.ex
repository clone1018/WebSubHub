defmodule WebSubHub.Repo do
  use Ecto.Repo,
    otp_app: :websubhub,
    adapter: Ecto.Adapters.Postgres
end
