defmodule WebSubHubWeb.Live.StatusPage do
  use WebSubHubWeb, :live_view

  alias WebSubHub.Updates
  alias WebSubHub.Subscriptions

  def render(assigns) do
    ~H"""
    <div>
      <h1>Status</h1>

      <p>Current:</p>
      <ul>
        <li>Known Topics: <%= @topics %></li>
        <li>Active Subscriptions: <%= @active_subscriptions %></li>
      </ul>

      <p>Last 30 Minutes:</p>
      <ul>
        <li>Publishes: <%= @publishes %></li>
        <li>Published to Subscribers: <%= @subscription_updates %></li>
      </ul>

    </div>
    """
  end

  def mount(_params, _, socket) do
    {:ok,
     socket
     |> assign(:topics, Subscriptions.count_topics())
     |> assign(:active_subscriptions, Subscriptions.count_active_subscriptions())
     |> assign(:publishes, Updates.count_30min_updates())
     |> assign(:subscription_updates, Updates.count_30min_subscription_updates())}
  end
end
