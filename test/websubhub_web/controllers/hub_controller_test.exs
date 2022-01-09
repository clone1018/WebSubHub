defmodule WebSubHubWeb.HubControllerTest do
  use WebSubHubWeb.ConnCase

  setup do
    {:ok, pid} = FakeServer.start(:my_server)
    subscriber_port = FakeServer.port!(pid)

    on_exit(fn ->
      FakeServer.stop(pid)
    end)

    [subscriber_pid: pid, subscriber_url: "http://localhost:#{subscriber_port}"]
  end

  test "subscribing to a specific topic", %{
    conn: conn,
    subscriber_pid: subscriber_pid,
    subscriber_url: subscriber_url
  } do
    :ok = FakeServer.put_route(subscriber_pid, "/callback", FakeServer.Response.ok("foo"))

    params = %{
      "hub.mode" => "subscribe",
      "hub.topic" => "http://localhost:1234/topic",
      "hub.callback" => "#{subscriber_url}/callback"
    }

    conn = form_post(conn, "/hub", params)

    assert response(conn, 202) =~ ""
  end

  test "subscribing with an invalid response", %{
    conn: conn,
    subscriber_pid: subscriber_pid,
    subscriber_url: subscriber_url
  } do
    :ok = FakeServer.put_route(subscriber_pid, "/callback", FakeServer.Response.ok("whut?"))

    params = %{
      "hub.mode" => "subscribe",
      "hub.topic" => "http://localhost:1234/topic",
      "hub.callback" => "#{subscriber_url}/callback"
    }

    conn = form_post(conn, "/hub", params)

    assert response(conn, 403) =~ "failed_challenge_body"
  end

  defp form_post(conn, path, params) do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/x-www-form-urlencoded")
    |> post(path, params)
  end
end
