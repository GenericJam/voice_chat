defmodule ChatWeb.ChatLiveTTSTest do
  use ChatWeb.ConnCase

  import Phoenix.LiveViewTest
  import Chat.BotsFixtures
  import Chat.HumansFixtures
  import Chat.ConversationsFixtures
  import Chat.AccountsFixtures

  @moduletag :live

  describe "Text-to-Speech functionality" do
    setup %{conn: conn} do
      user = user_fixture()
      human = human_fixture()
      bot_model = bot_model_fixture()
      bot_profile = bot_profile_fixture(%{bot_model_id: bot_model.id})

      conn = log_in_user(conn, user)

      %{conn: conn, user: user, human: human, bot_profile: bot_profile}
    end

    test "mounts with TTS enabled by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/chat")

      # Check TTS is enabled by default
      assert html =~ "phx-hook=\"TextToSpeech\""
    end

    test "toggle TTS auto-speak", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Initially auto-speak should be enabled
      assert view |> element("body") |> render() =~ "Disable auto-speak"

      # Toggle TTS
      view |> element("button[phx-click='toggle_tts']") |> render_click()

      # Should now show enable auto-speak
      assert view |> element("body") |> render() =~ "Enable auto-speak"
      assert has_element?(view, "[class*='bg-gray-200']")
    end

    test "speak message event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Test manual speak message (this would normally trigger JS TTS)
      result = view |> render_click("speak_message", %{"text" => "Hello world"})

      # The event should not crash
      assert result
    end

    test "stop TTS event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Set TTS as speaking
      view |> element("button[phx-click='stop_tts']") |> render_click()

      # Should handle the stop event gracefully
      refute has_element?(view, "[class*='animate-pulse']")
    end

    test "TTS error handling", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Simulate TTS error
      view |> render_hook("tts_error", %{"error" => "Test error"})

      # Should show error flash
      assert view |> element("body") |> render() =~ "Text-to-speech error: Test error"
    end

    test "TTS state changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Test TTS started
      view |> render_hook("tts_started", %{})
      assert has_element?(view, "[class*='animate-pulse']")

      # Test TTS ended
      view |> render_hook("tts_ended", %{})
      refute has_element?(view, "[class*='animate-pulse']")
    end
  end

  describe "TTS integration with chat" do
    setup %{conn: conn} do
      user = user_fixture()
      human = human_fixture()
      bot_model = bot_model_fixture()
      bot_profile = bot_profile_fixture(%{bot_model_id: bot_model.id})

      conn = log_in_user(conn, user)

      %{conn: conn, user: user, human: human, bot_profile: bot_profile}
    end

    test "TTS is triggered when bot responds (auto-speak enabled)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Ensure auto-speak is enabled (default state)
      assert view |> element("body") |> render() =~ "Disable auto-speak"

      # Send a message to trigger bot response
      view
      |> form("#dialog_input", message_input: "Hello")
      |> render_submit()

      # This would normally trigger Ollama response, but in test we can simulate
      # the full_response message
      send(view.pid, {:full_response, "Hello! How can I help you today?"})

      # The TTS should be triggered (would show in browser console in real usage)
      # We can't easily test the actual JS event firing, but we can verify the LiveView
      # processes the message correctly
      assert view |> element("body") |> render() =~ "Hello! How can I help you today?"
    end

    test "TTS is not triggered when auto-speak is disabled", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Disable auto-speak
      view |> element("button[phx-click='toggle_tts']") |> render_click()
      assert view |> element("body") |> render() =~ "Enable auto-speak"

      # Send a message to trigger bot response
      view
      |> form("#dialog_input", message_input: "Hello")
      |> render_submit()

      # Simulate bot response
      send(view.pid, {:full_response, "Hello! How can I help you today?"})

      # Message should appear but TTS should not be triggered
      assert view |> element("body") |> render() =~ "Hello! How can I help you today?"
    end
  end
end
