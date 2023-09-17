defmodule ShadowsocksPhWeb.HelloJSON do
  def index(assings) do
    %{message: "Hello JSON", params: assings.message}
  end
end
