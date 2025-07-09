defmodule ChatWeb.PersonaLiveTest do
  use ChatWeb.ConnCase

  import Phoenix.LiveViewTest
  import Chat.ConversationsFixtures
  import Chat.AccountsFixtures

  @create_attrs %{name: "some name", role: "human", avatar: "some_name_bot_white.png"}
  @update_attrs %{
    name: "some updated name",
    role: "human",
    avatar: "some updated avatar"
  }
  @invalid_attrs %{name: nil, role: nil, avatar: nil}

  defp create_persona(_) do
    persona = persona_fixture()
    %{persona: persona}
  end

  setup %{conn: conn} do
    password = valid_user_password()
    user = user_fixture(%{password: password})
    %{conn: log_in_user(conn, user), user: user, password: password}
  end

  describe "Index" do
    setup [:create_persona]

    test "lists all personas", %{conn: conn, persona: persona} do
      {:ok, _index_live, html} = live(conn, ~p"/personas")

      assert html =~ "Listing Personas"
      assert html =~ persona.name
    end

    test "saves new persona", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/personas")

      assert index_live |> element("a", "New Persona") |> render_click() =~
               "New Persona"

      assert_patch(index_live, ~p"/personas/new")

      assert index_live
             |> form("#persona-form", persona: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#persona-form", persona: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/personas")

      html = render(index_live)
      assert html =~ "Persona created successfully"
      assert html =~ "some name"
    end

    test "updates persona in listing", %{conn: conn, persona: persona} do
      {:ok, index_live, _html} = live(conn, ~p"/personas")

      assert index_live |> element("#personas-#{persona.id} a", "Edit") |> render_click() =~
               "Edit Persona"

      assert_patch(index_live, ~p"/personas/#{persona}/edit")

      assert index_live
             |> form("#persona-form", persona: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#persona-form", persona: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/personas")

      html = render(index_live)
      assert html =~ "Persona updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes persona in listing", %{conn: conn, persona: persona} do
      {:ok, index_live, _html} = live(conn, ~p"/personas")

      assert index_live |> element("#personas-#{persona.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#personas-#{persona.id}")
    end
  end

  describe "Show" do
    setup [:create_persona]

    test "displays persona", %{conn: conn, persona: persona} do
      {:ok, _show_live, html} = live(conn, ~p"/personas/#{persona}")

      assert html =~ "Show Persona"
      assert html =~ persona.name
    end

    test "updates persona within modal", %{conn: conn, persona: persona} do
      {:ok, show_live, _html} = live(conn, ~p"/personas/#{persona}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Persona"

      assert_patch(show_live, ~p"/personas/#{persona}/show/edit")

      assert show_live
             |> form("#persona-form", persona: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#persona-form", persona: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/personas/#{persona}")

      html = render(show_live)
      assert html =~ "Persona updated successfully"
      assert html =~ "some updated name"
    end
  end
end
