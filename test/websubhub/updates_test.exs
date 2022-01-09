defmodule WebSubHub.UpdatesTest do
  use WebSubHub.DataCase
  use Oban.Testing, repo: WebSubHub.Repo

  alias WebSubHub.Updates
  alias WebSubHub.Subscriptions

  setup do
    {:ok, pid} = FakeServer.start(:my_server)
    subscriber_port = FakeServer.port!(pid)

    on_exit(fn ->
      FakeServer.stop(pid)
    end)

    [subscriber_pid: pid, subscriber_url: "http://localhost:#{subscriber_port}"]
  end

  describe "updates" do
    test "publishing update dispatches jobs", %{
      subscriber_pid: subscriber_pid,
      subscriber_url: subscriber_url
    } do
      :ok = FakeServer.put_route(subscriber_pid, "/cb", FakeServer.Response.ok("foo"))

      topic_url = "https://topic/123"
      callback_url = subscriber_url <> "/cb"
      {:ok, _} = Subscriptions.subscribe(topic_url, callback_url)

      {:ok, update} = Updates.publish(topic_url)

      assert_enqueued(
        worker: WebSubHub.Jobs.DispatchPlainUpdate,
        args: %{update_id: update.id, callback_url: callback_url}
      )

      assert hits(subscriber_pid) == 1
    end
  end

  defp hits(subscriber_pid) do
    case FakeServer.Instance.access_list(subscriber_pid) do
      {:ok, access_list} -> length(access_list)
      {:error, _reason} -> 0
    end
  end
end
