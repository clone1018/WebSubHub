defmodule WebSubHub.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """
  require Logger

  import Ecto.Query, warn: false
  alias WebSubHub.Repo

  alias WebSubHub.Subscriptions.Topic
  alias WebSubHub.Subscriptions.Subscription

  def subscribe(topic_url, callback_url, lease_seconds \\ 864_000, secret \\ nil) do
    with {:ok, _} <- validate_url(topic_url),
         {:ok, callback_uri} <- validate_url(callback_url),
         {:ok, topic} <- find_or_create_topic(topic_url),
         {:ok, :success} <- validate_subscription(topic, callback_uri, lease_seconds) do
      case Repo.get_by(Subscription, topic_id: topic.id, callback_url: callback_url) do
        %Subscription{} = subscription ->
          lease_seconds = convert_lease_seconds(lease_seconds)
          expires_at = NaiveDateTime.add(NaiveDateTime.utc_now(), lease_seconds, :second)

          Logger.info("Subscriptions.subscribe: Updating #{topic_url} for #{callback_url}")

          subscription
          |> Subscription.changeset(%{
            secret: secret,
            expires_at: expires_at,
            lease_seconds: lease_seconds
          })
          |> Repo.update()

        nil ->
          create_subscription(topic, callback_uri, lease_seconds, secret)
      end
    else
      {:subscribe_validation_error, some_error} ->
        # If (and when) the subscription is denied, the hub MUST inform the subscriber by sending an HTTP [RFC7231] (or HTTPS [RFC2818]) GET request to the subscriber's callback URL as given in the subscription request. This request has the following query string arguments appended (format described in Section 4 of [URL]):
        {:ok, callback_uri} = validate_url(callback_url)

        reason = Atom.to_string(some_error)
        deny_subscription(callback_uri, topic_url, reason)

        Logger.info(
          "Subscriptions.subscribe: Failed validation for #{callback_url} with #{reason}"
        )

        {:error, some_error}

      _ ->
        {:error, "something"}
    end
  end

  def unsubscribe(topic_url, callback_url) do
    with {:ok, _} <- validate_url(topic_url),
         {:ok, callback_uri} <- validate_url(callback_url),
         %Topic{} = topic <- get_topic_by_url(topic_url),
         %Subscription{} = subscription <-
           Repo.get_by(Subscription, topic_id: topic.id, callback_url: callback_url) do
      validate_unsubscribe(topic, callback_uri)

      Logger.info("Subscriptions.unsubscribe: Updating #{topic_url} for #{callback_url}")

      subscription
      |> Subscription.changeset(%{
        expires_at: NaiveDateTime.utc_now()
      })
      |> Repo.update()
    else
      _ -> {:error, :subscription_not_found}
    end
  end

  @doc """
  Find or create a topic.

  Topics can exist without any valid subscriptions. Additionally a subscription can fail to validate and a topic still exist.

  ## Examples

      iex> find_or_create_topic("https://some-topic-url")
      {:ok, %Topic{}}
  """
  def find_or_create_topic(topic_url) do
    case Repo.get_by(Topic, url: topic_url) do
      %Topic{} = topic ->
        {:ok, topic}

      nil ->
        %Topic{}
        |> Topic.changeset(%{
          url: topic_url
        })
        |> Repo.insert()
    end
  end

  def get_topic_by_url(topic_url) do
    Repo.get_by(Topic, url: topic_url)
  end

  def get_subscription_by_url(callback_url) do
    Repo.get_by(Subscription, callback_url: callback_url)
  end

  @doc """
  Validate a subscription by sending a HTTP GET to the subscriber's callback_url.
  """
  def validate_subscription(
        %Topic{} = topic,
        %URI{} = callback_uri,
        lease_seconds
      ) do
    challenge = :crypto.strong_rand_bytes(32) |> Base.url_encode64() |> binary_part(0, 32)

    params = %{
      "hub.mode" => "subscribe",
      "hub.topic" => topic.url,
      "hub.challenge" => challenge,
      "hub.lease_seconds" => lease_seconds
    }

    callback_url = append_our_params(callback_uri, params)

    case HTTPoison.get(callback_url) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}} when code >= 200 and code < 300 ->
        # Ensure the response body matches our challenge
        if challenge != String.trim(body) do
          {:subscribe_validation_error, :failed_challenge_body}
        else
          {:ok, :success}
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:subscribe_validation_error, :failed_404_response}

      {:ok, %HTTPoison.Response{}} ->
        {:subscribe_validation_error, :failed_unknown_response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Got unexpected error from validate subscription call: #{reason}")
        {:subscribe_validation_error, :failed_unknown_error}
    end
  end

  @doc """
  Validate a unsubscription by sending a HTTP GET to the subscriber's callback_url.
  """
  def validate_unsubscribe(
        %Topic{} = topic,
        %URI{} = callback_uri
      ) do
    challenge = :crypto.strong_rand_bytes(32) |> Base.url_encode64() |> binary_part(0, 32)

    params = %{
      "hub.mode" => "unsubscribe",
      "hub.topic" => topic.url,
      "hub.challenge" => challenge
    }

    callback_url = append_our_params(callback_uri, params)

    case HTTPoison.get(callback_url) do
      {:ok, %HTTPoison.Response{}} ->
        {:ok, :success}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Got unexpected error from validate unsubscribe call: #{reason}")
        {:unsubscribe_validation_error, :failed_unknown_error}
    end
  end

  def create_subscription(%Topic{} = topic, %URI{} = callback_uri, lease_seconds, secret) do
    lease_seconds = convert_lease_seconds(lease_seconds)
    expires_at = NaiveDateTime.add(NaiveDateTime.utc_now(), lease_seconds, :second)

    %Subscription{
      topic: topic
    }
    |> Subscription.changeset(%{
      callback_url: to_string(callback_uri),
      lease_seconds: lease_seconds,
      expires_at: expires_at,
      secret: secret
    })
    |> Repo.insert()
  end

  defp convert_lease_seconds(seconds) when is_binary(seconds) do
    String.to_integer(seconds)
  end

  defp convert_lease_seconds(seconds), do: seconds

  def deny_subscription(%URI{} = callback_uri, topic_url, reason) do
    params = %{
      "hub.mode" => "denied",
      "hub.topic" => topic_url,
      "hub.reason" => reason
    }

    final_url = append_our_params(callback_uri, params)

    # We don't especially care about a response on this one
    case HTTPoison.get(final_url) do
      {:ok, %HTTPoison.Response{}} ->
        {:ok, :success}

      {:error, %HTTPoison.Error{reason: _reason}} ->
        {:ok, :error}
    end
  end

  def list_active_topic_subscriptions(%Topic{} = topic) do
    now = NaiveDateTime.utc_now()

    Repo.all(
      from(s in Subscription,
        where: s.topic_id == ^topic.id and s.expires_at >= ^now
      )
    )
  end

  defp append_our_params(%URI{query: old_params} = uri, params) do
    query_addition = URI.encode_query(params)

    %{uri | query: merge_query_params(old_params, query_addition)}
    |> to_string()
  end

  defp merge_query_params(nil, new), do: new
  defp merge_query_params("", new), do: new
  defp merge_query_params(original, new), do: original <> "&" <> new

  defp validate_url(url) when is_binary(url) do
    case URI.new(url) do
      {:ok, uri} ->
        if uri.scheme in ["http", "https"] do
          {:ok, uri}
        else
          {:error, :url_not_http}
        end

      err ->
        err
    end
  end

  defp validate_url(_), do: {:error, :url_not_binary}

  def count_topics do
    Repo.one(
      from(u in Topic,
        select: count(u.id)
      )
    )
  end

  def count_active_subscriptions do
    now = NaiveDateTime.utc_now()

    Repo.one(
      from(s in Subscription,
        where: s.expires_at >= ^now,
        select: count(s.id)
      )
    )
  end

  def subscription_updates_chart do
    case Repo.query("""
         select date(pushed_at) as "date", count(*) as "count"
         from subscription_updates
         group by date(pushed_at)
         order by date(pushed_at) desc
         limit 30;
         """) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        flipped = Enum.reverse(rows)

        %{
          keys: Enum.map(flipped, fn [key, _] -> key end),
          values: Enum.map(flipped, fn [_, value] -> value end)
        }

      _ ->
        %{keys: [], values: []}
    end
  end
end
