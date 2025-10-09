defmodule ChatWeb.AutoLoginController do
  use ChatWeb, :controller

  alias Chat.Accounts
  alias ChatWeb.UserAuth

  def create(conn, _params) do
    # Get demo user and log them in
    user = Chat.Repo.get_by!(Accounts.User, email: "demo@example.com")

    conn
    |> put_flash(:info, "Welcome!")
    |> UserAuth.log_in_user(user)
  end
end
