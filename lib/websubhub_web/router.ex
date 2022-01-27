defmodule WebSubHubWeb.Router do
  use WebSubHubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {WebSubHubWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :websub_hub do
    plug :accepts, ["x-www-form-urlencoded"]
  end

  pipeline :admin do
    plug :auth
  end

  scope "/", WebSubHubWeb do
    pipe_through :browser

    live_session :default do
      live "/", Live.IndexPage
      live "/status", Live.StatusPage
    end
  end

  scope "/hub", WebSubHubWeb do
    pipe_through :websub_hub

    post "/", HubController, :action
  end

  # Other scopes may use custom stacks.
  # scope "/api", WebSubHubWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    if Mix.env() in [:dev, :test] do
      pipe_through [:browser, :admin]
    else
      pipe_through [:browser]
    end

    live_dashboard "/dashboard", metrics: WebSubHubWeb.Telemetry
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp auth(conn, _) do
    Plug.BasicAuth.basic_auth(conn,
      username: "admin",
      password: System.fetch_env!("ADMIN_PASSWORD")
    )
  end
end
