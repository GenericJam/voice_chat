defmodule ChatWeb.BotModelLiveTest do
  use ChatWeb.ConnCase

  import Phoenix.LiveViewTest
  import Chat.BotsFixtures
  import Chat.AccountsFixtures

  @create_attrs %{name: "some name", spec: %{}}
  @update_attrs %{name: "some updated name", spec: %{}}
  @invalid_attrs %{name: nil}

  defp create_bot_model(_) do
    bot_model = bot_model_fixture()
    %{bot_model: bot_model}
  end

  setup %{conn: conn} do
    password = valid_user_password()
    user = user_fixture(%{password: password})
    %{conn: log_in_user(conn, user), user: user, password: password}
  end

  describe "Index" do
    setup [:create_bot_model]

    test "lists all bot_models", %{conn: conn, bot_model: bot_model} do
      {:ok, _index_live, html} = live(conn, ~p"/bot_models")

      assert html =~ "Listing Bot models"
      assert html =~ bot_model.name
    end

    test "saves new bot_model", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/bot_models")

      assert index_live |> element("a", "New Bot model") |> render_click() =~
               "New Bot model"

      assert_patch(index_live, ~p"/bot_models/new")

      assert index_live
             |> form("#bot_model-form", bot_model: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bot_model-form", bot_model: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bot_models")

      html = render(index_live)
      assert html =~ "Bot model created successfully"
      assert html =~ "some name"
    end

    test "updates bot_model in listing", %{conn: conn, bot_model: bot_model} do
      {:ok, index_live, _html} = live(conn, ~p"/bot_models")

      assert index_live |> element("#bot_models-#{bot_model.id} a", "Edit") |> render_click() =~
               "Edit Bot model"

      assert_patch(index_live, ~p"/bot_models/#{bot_model}/edit")

      assert index_live
             |> form("#bot_model-form", bot_model: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bot_model-form", bot_model: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bot_models")

      html = render(index_live)
      assert html =~ "Bot model updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes bot_model in listing", %{conn: conn, bot_model: bot_model} do
      {:ok, index_live, _html} = live(conn, ~p"/bot_models")

      assert index_live |> element("#bot_models-#{bot_model.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#bot_models-#{bot_model.id}")
    end
  end

  describe "Show" do
    setup [:create_bot_model]

    test "displays bot_model", %{conn: conn, bot_model: bot_model} do
      {:ok, _show_live, html} = live(conn, ~p"/bot_models/#{bot_model}")

      assert html =~ "Show Bot model"
      assert html =~ bot_model.name
    end

    test "updates bot_model within modal", %{conn: conn, bot_model: bot_model} do
      {:ok, show_live, _html} = live(conn, ~p"/bot_models/#{bot_model}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Bot model"

      assert_patch(show_live, ~p"/bot_models/#{bot_model}/show/edit")

      assert show_live
             |> form("#bot_model-form", bot_model: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#bot_model-form", bot_model: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/bot_models/#{bot_model}")

      html = render(show_live)
      assert html =~ "Bot model updated successfully"
      assert html =~ "some updated name"
    end
  end
end
