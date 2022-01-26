defmodule WebSubHub.Updates do
  @moduledoc """
  The Updates context.
  """
  require Logger

  import Ecto.Query, warn: false
  alias WebSubHub.Repo

  alias WebSubHub.Subscriptions
  alias WebSubHub.Subscriptions.Topic

  alias WebSubHub.Updates.Update
  alias WebSubHub.Updates.SubscriptionUpdate

  def publish(topic_url) do
    case Subscriptions.get_topic_by_url(topic_url) do
      # Get all active subscriptions and publish the update to them
      %Subscriptions.Topic{} = topic ->
        case HTTPoison.get(topic.url) do
          {:ok, %HTTPoison.Response{status_code: code, body: body, headers: headers}}
          when code >= 200 and code < 300 ->
            {:ok, update} = create_update(topic, body, headers)

            # Realistically we should do all of this async, for now we'll do querying line and dispatch async
            subscribers = Subscriptions.list_active_topic_subscriptions(topic)

            Enum.each(subscribers, fn subscription ->
              Logger.debug("Queueing dispatch to #{subscription.callback_url}")

              WebSubHub.Jobs.DispatchPlainUpdate.new(%{
                callback_url: subscription.callback_url,
                update_id: update.id,
                subscription_id: subscription.id,
                secret: subscription.secret
              })
              |> Oban.insert()
            end)

            {:ok, update}

          _ ->
            {:error, "Publish URL did not return a successful status code."}
        end

      nil ->
        # Nothing found
        {:error, "Topic not found for topic URL."}

      _ ->
        {:error, "Unknown error."}
    end
  end

  def create_update(%Topic{} = topic, body, headers) do
    %Update{
      topic: topic
    }
    |> Update.changeset(%{
      body: body,
      headers: headers,
      content_type: get_content_type_header(headers),
      links: get_link_headers(headers),
      hash: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
    })
    |> Repo.insert()
  end

  @doc """
  Create a subscription update, uses ID's for quick insertion
  """
  def create_subscription_update(update_id, subscription_id, status_code)
      when is_integer(update_id) and is_integer(subscription_id) do
    %SubscriptionUpdate{
      update_id: update_id,
      subscription_id: subscription_id
    }
    |> SubscriptionUpdate.changeset(%{
      pushed_at: NaiveDateTime.utc_now(),
      status_code: status_code
    })
    |> Repo.insert()
  end

  def get_update(id) do
    Repo.get(Update, id)
  end

  def get_subscription_update(id) do
    Repo.get(SubscriptionUpdate, id)
  end

  defp get_content_type_header(headers) do
    content_type? = &(&1 in ["Content-Type", "content-type"])
    found = for {k, v} <- headers, content_type?.(k), do: v

    case found do
      [content_type] ->
        content_type

      _ ->
        "application/octet-stream"
    end
  end

  defp get_link_headers(headers) do
    content_type? = &(&1 in ["Link", "link"])
    for {k, v} <- headers, content_type?.(k), do: v
  end

  def count_30min_updates do
    now = NaiveDateTime.utc_now()
    time_ago = NaiveDateTime.add(now, -1800)

    Repo.one(
      from u in Update,
        where: u.inserted_at > ^time_ago and u.inserted_at < ^now,
        select: count(u.id)
    )
  end

  def count_30min_subscription_updates do
    now = NaiveDateTime.utc_now()
    time_ago = NaiveDateTime.add(now, -1800)

    Repo.one(
      from u in SubscriptionUpdate,
        where: u.inserted_at > ^time_ago and u.inserted_at < ^now,
        select: count(u.id)
    )
  end
end
