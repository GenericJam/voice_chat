defmodule ChatWeb.PageController do
  use ChatWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def avatar(conn, %{"filename" => filename}) do
    avatar_path = Path.join([:code.priv_dir(:chat), "static", "avatars", filename])

    if File.exists?(avatar_path) do
      conn
      |> put_resp_content_type("image/png")
      |> send_file(200, avatar_path)
    else
      conn
      |> put_status(:not_found)
      |> text("Avatar not found")
    end
  end
end
