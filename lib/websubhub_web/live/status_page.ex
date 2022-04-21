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

      <p>Past 30 days:</p>
      <canvas id="updates-chart" phx-hook="UpdatesChart"></canvas>

    </div>
    """
  end

  def mount(_params, _, socket) do
    send(self(), :load_chart_data)

    {:ok,
     socket
     |> assign(:topics, Subscriptions.count_topics())
     |> assign(:active_subscriptions, Subscriptions.count_active_subscriptions())}
  end

  def handle_info(:load_chart_data, socket) do
    {:noreply,
     socket
     |> push_event("chart_data", Subscriptions.subscription_updates_chart())}
  end
end
