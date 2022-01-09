defmodule WebSubHubWeb.PageControllerTest do
  use WebSubHubWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Stable & Free WebSub Hub"
  end
end
