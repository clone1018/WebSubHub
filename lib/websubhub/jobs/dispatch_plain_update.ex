defmodule WebSubHub.Jobs.DispatchPlainUpdate do
  use Oban.Worker, queue: :updates, max_attempts: 3
  require Logger

  alias WebSubHub.Updates

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "update_id" => update_id,
          "subscription_id" => subscription_id,
          "callback_url" => callback_url,
          "secret" => secret
        }
      }) do
    Logger.info("Sending #{update_id} to #{callback_url}")

    update = WebSubHub.Updates.get_update(update_id)

    headers = %{
      "content-type" => update.content_type,
      "link" => Enum.join(update.links, ", ")
    }

    headers =
      if secret do
        hmac = :crypto.mac(:hmac, :sha256, secret, update.body) |> Base.encode16(case: :lower)
        Map.put(headers, "X-Hub-Signature", "sha256=" <> hmac)
      else
        headers
      end

    perform_request(callback_url, update.body, headers)
    |> log_request(update.id, subscription_id)
  end

  defp perform_request(callback_url, body, headers) do
    case HTTPoison.post(callback_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: code}} when code >= 200 and code < 300 ->
        Logger.info("Get OK response from #{callback_url}")

        {:ok, code}

      {:ok, %HTTPoison.Response{status_code: 410}} ->
        # Invalidate this subscription
        {:ok, 410}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:failed, status_code}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Get error response from #{callback_url}: #{reason}")
        {:error, reason}
    end
  end

  defp log_request(res, update_id, subscription_id) do
    status_code =
      case res do
        {_, code} when is_integer(code) ->
          code

        _ ->
          nil
      end

    Updates.create_subscription_update(update_id, subscription_id, status_code)

    res
  end
end
