defmodule IascElixirCrdtHordeWeb.PageController do
  use IascElixirCrdtHordeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
