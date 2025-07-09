defmodule Chat.Ollama do
  defstruct client: nil, task: nil, parent_pid: nil

  alias LangChain.ChatModels.ChatOllamaAI
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias LangChain.MessageDelta

  @default_model_name "llama4:latest"

  def chat(parent_pid, messages, model_name \\ @default_model_name) when is_list(messages) do
    handler = %{
      on_llm_new_message: fn model, message ->
        # Doesn't seem to do anything in ollama at least
        IO.inspect(model: model)
        IO.inspect(on_llm_new_message: message)
      end,
      on_llm_new_delta: fn
        _model, %MessageDelta{} = data ->
          send(parent_pid, {:token, data.content})
          IO.inspect(token: data.content)
      end,

      # Other possible handlers
      # on_message_processed: chain_message_processed(),
      # on_message_processing_error: chain_message_processing_error(),
      # on_error_message_created: chain_error_message_created(),
      # on_tool_response_created: chain_tool_response_created(),
      # on_retries_exceeded: chain_retries_exceeded()
      on_message_processed: fn
        _chain, %Message{} = data ->
          # the message was assmebled and is processed

          send(parent_pid, {:full_response, data.content})
      end,
      on_message_processing_error: fn _chain, error ->
        IO.inspect(error: error)
      end
    }

    {:ok, _updated_chain} =
      %{
        # llm config for streaming and the deltas callback
        llm: ChatOllamaAI.new!(%{model: model_name, stream: true, callbacks: [handler]}),
        # chain callbacks
        callbacks: [handler]
      }
      |> LLMChain.new!()
      |> LLMChain.add_messages(messages)
      |> LLMChain.run()
  end
end
