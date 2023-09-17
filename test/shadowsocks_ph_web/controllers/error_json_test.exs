defmodule ShadowsocksPhWeb.ErrorJSONTest do
  use ShadowsocksPhWeb.ConnCase, async: true

  test "renders 404" do
    assert ShadowsocksPhWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ShadowsocksPhWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
