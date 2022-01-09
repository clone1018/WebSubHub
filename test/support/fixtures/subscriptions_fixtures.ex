defmodule WebSubHub.SubscriptionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WebSubHub.Subscriptions` context.
  """

  @doc """
  Generate a topic.
  """
  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        url: "some url"
      })
      |> WebSubHub.Subscriptions.create_topic()

    topic
  end

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(%{
        callback_url: "some callback_url",
        lease_seconds: 42,
        secret: "some secret",
        topic_id: 42
      })
      |> WebSubHub.Subscriptions.create_subscription()

    subscription
  end
end
