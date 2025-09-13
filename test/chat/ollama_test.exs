defmodule Chat.OllamaTest do
  use ExUnit.Case, async: true
  import Mock

  alias Chat.Ollama
  alias LangChain.Message
  alias LangChain.MessageDelta
  alias LangChain.ChatModels.ChatOllamaAI
  alias LangChain.Chains.LLMChain

  describe "chat/3" do
    setup do
      # Sample messages for testing
      messages = [
        Message.new_user!("Hello, how are you?"),
        Message.new_assistant!("I'm doing well, thank you!"),
        Message.new_user!("What's the weather like?")
      ]

      %{messages: messages}
    end

    test "uses default model when none specified", %{messages: messages} do
      parent_pid = self()

      # Mock LangChain to capture configuration
      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          send(parent_pid, {:config_captured, config})
          # Return a minimal mock
          %{model: config.model, stream: config.stream}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn chain -> {:ok, chain} end do
          # Call with default model (no third parameter)
          Ollama.chat(parent_pid, messages)

          # Verify default model was used
          assert_receive {:config_captured, config}
          assert config.model == "llama3.2:1b"
          assert config.stream == true
          assert is_list(config.callbacks)
        end
      end
    end

    test "uses specified model when provided", %{messages: messages} do
      parent_pid = self()
      custom_model = "llama3:8b-instruct-q2_K"

      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          send(parent_pid, {:config_captured, config})
          %{model: config.model, stream: config.stream}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, messages, custom_model)

          # Verify custom model was used
          assert_receive {:config_captured, config}
          assert config.model == custom_model
          assert config.stream == true
        end
      end
    end

    test "configures streaming and callbacks correctly", %{messages: messages} do
      parent_pid = self()

      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          send(parent_pid, {:config_captured, config})
          %{model: config.model, stream: config.stream, callbacks: config.callbacks}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn config ->
            send(parent_pid, {:chain_config_captured, config})
            %{}
          end,
          add_messages: fn chain, msgs ->
            send(parent_pid, {:messages_added, length(msgs)})
            chain
          end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, messages)

          # Verify ChatOllamaAI configuration
          assert_receive {:config_captured, ollama_config}
          assert ollama_config.stream == true
          assert is_list(ollama_config.callbacks)
          assert length(ollama_config.callbacks) == 1

          # Verify LLMChain configuration
          assert_receive {:chain_config_captured, chain_config}
          assert Map.has_key?(chain_config, :llm)
          assert Map.has_key?(chain_config, :callbacks)
          assert is_list(chain_config.callbacks)

          # Verify messages were added
          assert_receive {:messages_added, 3}
        end
      end
    end

    test "handles empty messages list" do
      parent_pid = self()

      with_mock ChatOllamaAI, [:passthrough], new!: fn _config -> %{} end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, msgs ->
            send(parent_pid, {:messages_added, length(msgs)})
            chain
          end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, [])

          # Should still process with empty messages
          assert_receive {:messages_added, 0}
        end
      end
    end

    test "token callback sends streaming tokens to parent process" do
      parent_pid = self()
      test_content = "Hello world"

      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          # Extract the callback handler to test it
          [handler] = config.callbacks

          # Simulate the on_llm_new_delta callback
          delta = %MessageDelta{content: test_content}
          handler.on_llm_new_delta.(nil, delta)

          %{}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, [])

          # Verify token was sent to parent
          assert_receive {:token, ^test_content}
        end
      end
    end

    test "completion callback sends full response to parent process" do
      parent_pid = self()
      test_response = "This is the complete response"

      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          # Extract the callback handler to test it
          [handler] = config.callbacks

          # Simulate the on_message_processed callback
          message = %Message{content: test_response}
          handler.on_message_processed.(nil, message)

          %{}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, [])

          # Verify full response was sent to parent
          assert_receive {:full_response, ^test_response}
        end
      end
    end

    test "new message callback sends notification to parent process" do
      parent_pid = self()

      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          # Extract the callback handler to test it
          [handler] = config.callbacks

          # Simulate the on_llm_new_message callback
          message = %Message{content: "test message"}
          handler.on_llm_new_message.(nil, message)

          %{}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, [])

          # Verify new message notification was sent to parent
          assert_receive :new_message
        end
      end
    end

    test "error callback sends error message to parent process" do
      parent_pid = self()
      test_error = "Connection timeout"

      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          # Extract the callback handler to test it
          [handler] = config.callbacks

          # Simulate the on_message_processing_error callback
          handler.on_message_processing_error.(nil, test_error)

          %{}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, [])

          # Verify error was sent to parent process (inspect() adds quotes)
          assert_receive {:error, "\"Connection timeout\""}
        end
      end
    end

    test "processes messages and calls LangChain with correct parameters", %{messages: messages} do
      parent_pid = self()

      with_mock ChatOllamaAI, [:passthrough], new!: fn _config -> %{model: "test_model"} end do
        with_mock LLMChain, [:passthrough],
          new!: fn config ->
            send(parent_pid, {:chain_new, config})
            %{test: :chain}
          end,
          add_messages: fn chain, msgs ->
            send(parent_pid, {:chain_add_messages, chain, msgs})
            chain
          end,
          run: fn chain ->
            send(parent_pid, {:chain_run, chain})
            {:ok, chain}
          end do
          Ollama.chat(parent_pid, messages)

          # Verify the full chain of LangChain calls
          assert_receive {:chain_new, config}
          assert Map.has_key?(config, :llm)
          assert Map.has_key?(config, :callbacks)

          assert_receive {:chain_add_messages, %{test: :chain}, received_messages}
          assert received_messages == messages

          assert_receive {:chain_run, %{test: :chain}}
        end
      end
    end

    test "crashes on LangChain errors due to pattern matching (current behavior)", %{
      messages: messages
    } do
      parent_pid = self()

      with_mock ChatOllamaAI, [:passthrough], new!: fn _config -> %{} end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn _chain -> {:error, "LangChain error"} end do
          # The current implementation has a bug - it uses {:ok, _} pattern matching
          # which will crash if LangChain.run returns an error
          assert_raise MatchError, ~r/no match of right hand side value: \{:error/, fn ->
            Ollama.chat(parent_pid, messages)
          end
        end
      end
    end

    test "callback handlers are correctly formatted and send messages to parent" do
      parent_pid = self()

      with_mock ChatOllamaAI, [:passthrough],
        new!: fn config ->
          [handler] = config.callbacks

          # Test all callback functions exist and are callable
          assert is_function(handler.on_llm_new_message, 2)
          assert is_function(handler.on_llm_new_delta, 2)
          assert is_function(handler.on_message_processed, 2)
          assert is_function(handler.on_message_processing_error, 2)

          # Test that they send appropriate messages to parent process
          handler.on_llm_new_message.(nil, %Message{})
          handler.on_llm_new_delta.(nil, %MessageDelta{content: "test"})
          handler.on_message_processed.(nil, %Message{content: "test"})
          handler.on_message_processing_error.(nil, "test error")

          send(parent_pid, :callbacks_tested)
          %{}
        end do
        with_mock LLMChain, [:passthrough],
          new!: fn _config -> %{} end,
          add_messages: fn chain, _messages -> chain end,
          run: fn chain -> {:ok, chain} end do
          Ollama.chat(parent_pid, [])

          # Verify all expected messages were received
          assert_receive :new_message
          assert_receive {:token, "test"}
          assert_receive {:full_response, "test"}
          assert_receive {:error, "\"test error\""}
          assert_receive :callbacks_tested
        end
      end
    end
  end

  describe "integration with actual LangChain (requires network)" do
    @moduletag :integration

    test "can create valid LangChain configuration" do
      # This test verifies that our configuration is valid for LangChain
      # but doesn't actually make network calls
      _messages = [Message.new_user!("Hello")]

      # Test that the configuration doesn't crash LangChain initialization
      assert_nothing_raised(fn ->
        # Just test the ChatOllamaAI configuration creation
        config = %{
          model: "llama3.2:1b",
          stream: true,
          callbacks: [
            %{
              on_llm_new_message: fn _, _ -> :ok end,
              on_llm_new_delta: fn _, _ -> :ok end,
              on_message_processed: fn _, _ -> :ok end,
              on_message_processing_error: fn _, _ -> :ok end
            }
          ]
        }

        # This should not raise an exception
        ChatOllamaAI.new!(config)
      end)
    end
  end

  # Helper function to assert no exceptions are raised
  defp assert_nothing_raised(fun) do
    try do
      fun.()
    rescue
      e -> flunk("Expected no exception, but got: #{inspect(e)}")
    end
  end
end
