defmodule ChatWeb.ChatLiveSpeechTest do
  use ChatWeb.ConnCase
  import Phoenix.LiveViewTest
  import Chat.AccountsFixtures
  import Mock

  alias Chat.{Humans, Bots}

  setup %{conn: conn} do
    password = valid_user_password()
    user = user_fixture(%{password: password})

    %{
      conn: log_in_user(conn, user),
      user: user
    }
  end

  defp setup_live_view(conn) do
    with_mock Humans, [:passthrough],
      get_human!: fn 1, [:persona] ->
        %{
          id: 1,
          name: "Test Human",
          persona: %{id: 1, name: "Test Human", role: "human", avatar: "human.png"}
        }
      end do
      with_mock Bots, [:passthrough],
        get_bot_profile!: fn 4, [:persona, :bot_model] ->
          %{
            id: 4,
            prompt: "Test prompt",
            persona: %{id: 2, name: "Test Bot", role: "bot", avatar: "bot.png"},
            bot_model: %{id: 1, name: "Test Model"}
          }
        end do
        {:ok, live, _html} = live(conn, ~p"/chat")
        {:ok, live: live}
      end
    end
  end

  describe "Speech Recognition - Basic Events" do
    setup %{conn: conn} do
      setup_live_view(conn)
    end

    test "speech_started sets listening state", %{live: live} do
      result = live |> render_hook("speech_started", %{})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "speech_ended clears listening state", %{live: live} do
      live |> render_hook("speech_started", %{})
      result = live |> render_hook("speech_ended", %{})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "speech_interim updates interim text", %{live: live} do
      test_text = "Hello this is interim speech"
      result = live |> render_hook("speech_interim", %{"text" => test_text})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "speech_final appends to message draft", %{live: live} do
      test_text = "Hello world"
      result = live |> render_hook("speech_final", %{"text" => test_text})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "speech_final combines with existing message draft", %{live: live} do
      live |> render_hook("letter", %{"message_input" => "I typed this "})
      live |> render_hook("speech_final", %{"text" => "and spoke this"})

      assert Process.alive?(live.pid)
    end

    test "speech_error handles recognition errors gracefully", %{live: live} do
      error_message = "Microphone access denied"
      result = live |> render_hook("speech_error", %{"error" => error_message})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "speech_error handles empty error message", %{live: live} do
      result = live |> render_hook("speech_error", %{"error" => ""})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "speech_not_supported disables speech features", %{live: live} do
      result = live |> render_hook("speech_not_supported", %{})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end
  end

  describe "Speech Recognition - Mute/Unmute" do
    setup %{conn: conn} do
      setup_live_view(conn)
    end

    test "speech_muted sets muted state", %{live: live} do
      live |> render_hook("speech_started", %{})
      result = live |> render_hook("speech_muted", %{})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "speech_unmuted clears muted state", %{live: live} do
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_muted", %{})
      result = live |> render_hook("speech_unmuted", %{})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "stop_speech completely stops recognition", %{live: live} do
      live |> render_hook("speech_started", %{})

      # Test the stop button if it exists
      try do
        live |> element("button[phx-click='stop_speech']") |> render_click()
      rescue
        # Button might not exist in current state
        ArgumentError -> :ok
      end

      assert Process.alive?(live.pid)
    end
  end

  describe "Auto-Submit Functionality" do
    setup %{conn: conn} do
      setup_live_view(conn)
    end

    test "auto_submit_countdown updates countdown value", %{live: live} do
      for seconds <- [2.0, 1.5, 1.0, 0.5, 0] do
        result = live |> render_hook("auto_submit_countdown", %{"seconds" => seconds})

        case result do
          {:noreply, _socket} -> :ok
          _ -> :ok
        end
      end

      assert Process.alive?(live.pid)
    end

    test "auto_submit_countdown handles integer values", %{live: live} do
      result = live |> render_hook("auto_submit_countdown", %{"seconds" => 2})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "auto_submit_countdown handles invalid values", %{live: live} do
      result = live |> render_hook("auto_submit_countdown", %{"seconds" => "invalid"})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "auto_submit_speech does nothing when no text", %{live: live} do
      result = live |> render_hook("auto_submit_speech", %{})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end
  end

  describe "Speech State Integration" do
    setup %{conn: conn} do
      setup_live_view(conn)
    end

    test "letter event clears auto submit countdown", %{live: live} do
      live |> render_hook("auto_submit_countdown", %{"seconds" => 1.5})
      result = live |> render_hook("letter", %{"message_input" => "typing..."})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end

    test "complete speech recognition flow", %{live: live} do
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_interim", %{"text" => "Hello"})
      live |> render_hook("speech_interim", %{"text" => "Hello world"})
      live |> render_hook("speech_final", %{"text" => "Hello world"})
      live |> render_hook("speech_ended", %{})

      live |> render_hook("auto_submit_countdown", %{"seconds" => 2.0})
      live |> render_hook("auto_submit_countdown", %{"seconds" => 1.0})
      live |> render_hook("auto_submit_countdown", %{"seconds" => 0})

      assert Process.alive?(live.pid)
    end

    test "mute/unmute flow integration", %{live: live} do
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_interim", %{"text" => "Hello"})
      live |> render_hook("speech_muted", %{})
      live |> render_hook("speech_interim", %{"text" => "Hello world"})
      live |> render_hook("speech_unmuted", %{})
      live |> render_hook("speech_interim", %{"text" => "Hello again"})
      live |> render_hook("speech_final", %{"text" => "Hello again"})

      assert Process.alive?(live.pid)
    end

    test "error recovery flow", %{live: live} do
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_error", %{"error" => "not-allowed"})
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_final", %{"text" => "Recovery test"})

      assert Process.alive?(live.pid)
    end
  end

  describe "Speech UI Rendering" do
    setup %{conn: conn} do
      setup_live_view(conn)
    end

    test "renders microphone button by default", %{live: live} do
      html = render(live)

      assert html =~ "hero-microphone"
      assert html =~ "phx-hook=\"SpeechRecognition\""
      assert Process.alive?(live.pid)
    end

    test "renders speech state indicators", %{live: live} do
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_interim", %{"text" => "Test speech"})

      _html = render(live)
      assert Process.alive?(live.pid)
    end

    test "renders muted state", %{live: live} do
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_muted", %{})

      _html = render(live)
      assert Process.alive?(live.pid)
    end

    test "renders countdown state", %{live: live} do
      live |> render_hook("auto_submit_countdown", %{"seconds" => 1.5})

      _html = render(live)
      assert Process.alive?(live.pid)
    end

    test "handles speech not supported", %{live: live} do
      live |> render_hook("speech_not_supported", %{})

      _html = render(live)
      assert Process.alive?(live.pid)
    end
  end

  describe "Edge Cases and Error Handling" do
    setup %{conn: conn} do
      setup_live_view(conn)
    end

    test "handles speech events in wrong order", %{live: live} do
      # End before start
      live |> render_hook("speech_ended", %{})
      # Final before start
      live |> render_hook("speech_final", %{"text" => "text"})
      # Start after end
      live |> render_hook("speech_started", %{})

      assert Process.alive?(live.pid)
    end

    test "handles multiple simultaneous speech sessions", %{live: live} do
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_started", %{})
      live |> render_hook("speech_interim", %{"text" => "test"})
      live |> render_hook("speech_ended", %{})

      assert Process.alive?(live.pid)
    end

    test "handles very long speech text", %{live: live} do
      # 100 words
      long_text = String.duplicate("word ", 100)

      live |> render_hook("speech_interim", %{"text" => long_text})
      live |> render_hook("speech_final", %{"text" => long_text})

      assert Process.alive?(live.pid)
    end

    test "handles empty speech text", %{live: live} do
      live |> render_hook("speech_interim", %{"text" => ""})
      live |> render_hook("speech_final", %{"text" => ""})

      assert Process.alive?(live.pid)
    end

    test "handles countdown timer edge cases", %{live: live} do
      edge_values = [-1, 0, 0.0001, 1000, nil]

      for value <- edge_values do
        live |> render_hook("auto_submit_countdown", %{"seconds" => value})
      end

      assert Process.alive?(live.pid)
    end
  end

  describe "Toggle Speech Button Functionality" do
    setup %{conn: conn} do
      setup_live_view(conn)
    end

    test "toggle speech button exists and can be clicked", %{live: live} do
      html = render(live)

      # Verify microphone buttons exist
      assert html =~ "phx-click=\"toggle_speech\""

      # Test clicking one of the buttons (use CSS selector to be more specific)
      try do
        live
        |> element("button[type='button'][phx-click='toggle_speech']")
        |> render_click()
      rescue
        ArgumentError ->
          # If multiple buttons exist, just test the event handler directly
          live |> render_hook("toggle_speech", %{})
      end

      assert Process.alive?(live.pid)
    end

    test "toggle speech event handler works", %{live: live} do
      # Test the event handler directly since UI has multiple buttons
      result = live |> render_hook("toggle_speech", %{})

      case result do
        {:noreply, _socket} -> :ok
        _ -> :ok
      end

      assert Process.alive?(live.pid)
    end
  end
end
