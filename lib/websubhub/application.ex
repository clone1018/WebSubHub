defmodule WebSubHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      WebSubHub.Repo,
      # Start the Telemetry supervisor
      WebSubHubWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: WebSubHub.PubSub},
      # Start the Endpoint (http/https)
      WebSubHubWeb.Endpoint,
      # Start a worker by calling: WebSubHub.Worker.start_link(arg)
      # {WebSubHub.Worker, arg}
      {Oban, oban_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebSubHub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebSubHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Conditionally disable queues or plugins here.
  defp oban_config do
    Application.fetch_env!(:websubhub, Oban)
  end
end
