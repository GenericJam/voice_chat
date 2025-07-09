# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Chat.Repo.insert!(%Chat.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

client = Ollama.init()

{:ok,
 %{
   "models" => models
 }} =
  Ollama.list_models(client)

models
|> Enum.map(fn
  %{
    "name" => name
  } = model ->
    # Create initial persona
    {:ok, persona} = Chat.Conversations.create_persona(%{name: name, role: "bot"})

    {:ok, bot_model} = Chat.Bots.create_bot_model(%{name: name, specs: model})

    {:ok, bot_profile} =
      Chat.Bots.create_bot_profile(%{
        prompt: "You are a helpful assistant.",
        bot_model_id: bot_model.id,
        persona_id: persona.id
      })

    bot_profile
end)

{:ok, human} = Chat.Humans.create_human(%{name: "Steve"})

{:ok, human_persona} = Chat.Conversations.create_persona(%{name: human.name, role: "human"})
