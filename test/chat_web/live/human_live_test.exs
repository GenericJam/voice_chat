defmodule ChatWeb.HumanLiveTest do
  use ChatWeb.ConnCase

  import Phoenix.LiveViewTest
  import Chat.HumansFixtures
  import Chat.AccountsFixtures

  @create_attrs %{name: "some name", hash: "some hash", photo: "some photo"}
  @update_attrs %{
    name: "some updated name",
    hash: "some updated hash",
    photo: "some updated photo"
  }
  @invalid_attrs %{name: nil, hash: nil, photo: nil}

  defp create_human(_) do
    human = human_fixture()
    %{human: human}
  end

  setup %{conn: conn} do
    password = valid_user_password()
    user = user_fixture(%{password: password})
    %{conn: log_in_user(conn, user), user: user, password: password}
  end

  describe "Index" do
    setup [:create_human]

    test "lists all humans", %{conn: conn, human: human} do
      {:ok, _index_live, html} = live(conn, ~p"/humans")

      assert html =~ "Listing Humans"
      assert html =~ human.name
    end

    test "saves new human", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/humans")

      assert index_live |> element("a", "New Human") |> render_click() =~
               "New Human"

      assert_patch(index_live, ~p"/humans/new")

      assert index_live
             |> form("#human-form", human: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#human-form", human: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/humans")

      html = render(index_live)
      assert html =~ "Human created successfully"
      assert html =~ "some name"
    end

    test "updates human in listing", %{conn: conn, human: human} do
      {:ok, index_live, _html} = live(conn, ~p"/humans")

      assert index_live |> element("#humans-#{human.id} a", "Edit") |> render_click() =~
               "Edit Human"

      assert_patch(index_live, ~p"/humans/#{human}/edit")

      assert index_live
             |> form("#human-form", human: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#human-form", human: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/humans")

      html = render(index_live)
      assert html =~ "Human updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes human in listing", %{conn: conn, human: human} do
      {:ok, index_live, _html} = live(conn, ~p"/humans")

      assert index_live |> element("#humans-#{human.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#humans-#{human.id}")
    end
  end

  describe "Show" do
    setup [:create_human]

    test "displays human", %{conn: conn, human: human} do
      {:ok, _show_live, html} = live(conn, ~p"/humans/#{human}")

      assert html =~ "Show Human"
      assert html =~ human.name
    end

    test "updates human within modal", %{conn: conn, human: human} do
      {:ok, show_live, _html} = live(conn, ~p"/humans/#{human}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Human"

      assert_patch(show_live, ~p"/humans/#{human}/show/edit")

      assert show_live
             |> form("#human-form", human: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#human-form", human: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/humans/#{human}")

      html = render(show_live)
      assert html =~ "Human updated successfully"
      assert html =~ "some updated name"
    end
  end
end
