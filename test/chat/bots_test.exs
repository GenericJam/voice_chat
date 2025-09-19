defmodule Chat.BotsTest do
  use Chat.DataCase

  alias Chat.Bots

  describe "bot_models" do
    alias Chat.Bots.BotModel

    import Chat.BotsFixtures

    @invalid_attrs %{name: nil, spec: nil}

    test "list_bot_models/0 returns all bot_models" do
      bot_model = bot_model_fixture()
      assert Bots.list_bot_models() == [bot_model]
    end

    test "get_bot_model!/1 returns the bot_model with given id" do
      bot_model = bot_model_fixture()
      assert Bots.get_bot_model!(bot_model.id) == bot_model
    end

    test "create_bot_model/1 with valid data creates a bot_model" do
      valid_attrs = %{name: "some name", spec: %{}}

      assert {:ok, %BotModel{} = bot_model} = Bots.create_bot_model(valid_attrs)
      assert bot_model.name == "some name"
      assert bot_model.spec == %{}
    end

    test "create_bot_model/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bots.create_bot_model(@invalid_attrs)
    end

    test "update_bot_model/2 with valid data updates the bot_model" do
      bot_model = bot_model_fixture()
      update_attrs = %{name: "some updated name", spec: %{}}

      assert {:ok, %BotModel{} = bot_model} = Bots.update_bot_model(bot_model, update_attrs)
      assert bot_model.name == "some updated name"
      assert bot_model.spec == %{}
    end

    test "update_bot_model/2 with invalid data returns error changeset" do
      bot_model = bot_model_fixture()
      assert {:error, %Ecto.Changeset{}} = Bots.update_bot_model(bot_model, @invalid_attrs)
      assert bot_model == Bots.get_bot_model!(bot_model.id)
    end

    test "delete_bot_model/1 deletes the bot_model" do
      bot_model = bot_model_fixture()
      assert {:ok, %BotModel{}} = Bots.delete_bot_model(bot_model)
      assert_raise Ecto.NoResultsError, fn -> Bots.get_bot_model!(bot_model.id) end
    end

    test "change_bot_model/1 returns a bot_model changeset" do
      bot_model = bot_model_fixture()
      assert %Ecto.Changeset{} = Bots.change_bot_model(bot_model)
    end
  end

  describe "bot_profiles" do
    alias Chat.Bots.BotProfile

    import Chat.BotsFixtures
    import Chat.ConversationsFixtures

    @invalid_attrs %{prompt: nil, bot_model_id: nil, persona_id: nil}

    test "list_bot_profiles/0 returns all bot_profiles" do
      bot_profile = bot_profile_fixture()
      assert Bots.list_bot_profiles() == [bot_profile]
    end

    test "list_bot_profiles/1 with preloads returns bot_profiles with associations" do
      bot_profile = bot_profile_fixture()
      [result] = Bots.list_bot_profiles([:bot_model, :persona])

      assert result.id == bot_profile.id
      assert %Chat.Bots.BotModel{} = result.bot_model
      assert %Chat.Conversations.Persona{} = result.persona
    end

    test "get_bot_profile!/1 returns the bot_profile with given id" do
      bot_profile = bot_profile_fixture()
      assert Bots.get_bot_profile!(bot_profile.id) == bot_profile
    end

    test "get_bot_profile!/2 with preloads returns bot_profile with associations" do
      bot_profile = bot_profile_fixture()
      result = Bots.get_bot_profile!(bot_profile.id, [:bot_model, :persona])

      assert result.id == bot_profile.id
      assert %Chat.Bots.BotModel{} = result.bot_model
      assert %Chat.Conversations.Persona{} = result.persona
    end

    test "get_bot_profile_by_name/2 returns bot_profile by persona name" do
      persona = persona_fixture(%{name: "TestBot", role: "bot"})
      bot_profile = bot_profile_fixture(%{persona: persona})

      result = Bots.get_bot_profile_by_name("TestBot")
      assert result.id == bot_profile.id
    end

    test "get_bot_profile_by_name/2 with preloads returns bot_profile with associations" do
      persona = persona_fixture(%{name: "TestBot", role: "bot"})
      bot_profile = bot_profile_fixture(%{persona: persona})

      result = Bots.get_bot_profile_by_name("TestBot", [:bot_model, :persona])
      assert result.id == bot_profile.id
      assert %Chat.Bots.BotModel{} = result.bot_model
      assert %Chat.Conversations.Persona{} = result.persona
    end

    test "get_bot_profile_by_name/2 returns nil for non-existent name" do
      bot_profile_fixture()
      assert Bots.get_bot_profile_by_name("NonExistentBot") == nil
    end

    test "create_bot_profile/1 with valid data creates a bot_profile" do
      bot_model = bot_model_fixture()
      persona = persona_fixture(%{role: "bot"})

      valid_attrs = %{
        prompt: "You are a helpful test assistant.",
        bot_model_id: bot_model.id,
        persona_id: persona.id
      }

      assert {:ok, %BotProfile{} = bot_profile} = Bots.create_bot_profile(valid_attrs)
      assert bot_profile.prompt == "You are a helpful test assistant."
      assert bot_profile.bot_model_id == bot_model.id
      assert bot_profile.persona_id == persona.id
    end

    test "create_bot_profile/1 with nested persona creation" do
      bot_model = bot_model_fixture()

      valid_attrs = %{
        prompt: "You are a helpful test assistant.",
        bot_model_id: bot_model.id,
        persona: %{
          name: "NestedBot",
          role: "bot",
          avatar: "nested_bot.png"
        }
      }

      assert {:ok, %BotProfile{} = bot_profile} = Bots.create_bot_profile(valid_attrs)
      assert bot_profile.prompt == "You are a helpful test assistant."
      assert bot_profile.bot_model_id == bot_model.id
      assert bot_profile.persona.name == "NestedBot"
      assert bot_profile.persona.role == "bot"
    end

    test "create_bot_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bots.create_bot_profile(@invalid_attrs)
    end

    test "create_bot_profile/1 without required prompt returns error changeset" do
      bot_model = bot_model_fixture()
      persona = persona_fixture(%{role: "bot"})

      attrs = %{bot_model_id: bot_model.id, persona_id: persona.id}
      assert {:error, changeset} = Bots.create_bot_profile(attrs)
      assert %{prompt: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_bot_profile/1 without required bot_model_id returns error changeset" do
      persona = persona_fixture(%{role: "bot"})

      attrs = %{prompt: "Test prompt", persona_id: persona.id}
      assert {:error, changeset} = Bots.create_bot_profile(attrs)
      assert %{bot_model_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_bot_profile/1 with non-existent bot_model_id returns error changeset" do
      persona = persona_fixture(%{role: "bot"})

      attrs = %{
        prompt: "Test prompt",
        bot_model_id: -1,
        persona_id: persona.id
      }

      assert {:error, changeset} = Bots.create_bot_profile(attrs)
      assert %{bot_model: ["does not exist"]} = errors_on(changeset)
    end

    test "create_bot_profile/1 with non-existent persona_id returns error changeset" do
      bot_model = bot_model_fixture()

      attrs = %{
        prompt: "Test prompt",
        bot_model_id: bot_model.id,
        persona_id: -1
      }

      assert {:error, changeset} = Bots.create_bot_profile(attrs)
      assert %{persona: ["does not exist"]} = errors_on(changeset)
    end

    test "update_bot_profile/2 with valid data updates the bot_profile" do
      bot_profile = bot_profile_fixture()
      update_attrs = %{prompt: "Updated prompt for the bot"}

      assert {:ok, %BotProfile{} = bot_profile} =
               Bots.update_bot_profile(bot_profile, update_attrs)

      assert bot_profile.prompt == "Updated prompt for the bot"
    end

    test "update_bot_profile/2 with new bot_model updates association" do
      bot_profile = bot_profile_fixture()
      new_bot_model = bot_model_fixture(%{name: "New Model"})

      update_attrs = %{bot_model_id: new_bot_model.id}

      assert {:ok, %BotProfile{} = updated_profile} =
               Bots.update_bot_profile(bot_profile, update_attrs)

      assert updated_profile.bot_model_id == new_bot_model.id
    end

    test "update_bot_profile/2 with nested persona update" do
      bot_profile = bot_profile_fixture()

      update_attrs = %{
        persona: %{
          id: bot_profile.persona_id,
          name: "Updated Bot Name"
        }
      }

      assert {:ok, %BotProfile{} = updated_profile} =
               Bots.update_bot_profile(bot_profile, update_attrs)

      updated_profile = Chat.Repo.preload(updated_profile, :persona)
      assert updated_profile.persona.name == "Updated Bot Name"
    end

    test "update_bot_profile/2 with invalid data returns error changeset" do
      bot_profile = bot_profile_fixture()
      assert {:error, %Ecto.Changeset{}} = Bots.update_bot_profile(bot_profile, @invalid_attrs)
      assert bot_profile == Bots.get_bot_profile!(bot_profile.id)
    end

    test "delete_bot_profile/1 deletes the bot_profile" do
      bot_profile = bot_profile_fixture()
      assert {:ok, %BotProfile{}} = Bots.delete_bot_profile(bot_profile)
      assert_raise Ecto.NoResultsError, fn -> Bots.get_bot_profile!(bot_profile.id) end
    end

    test "change_bot_profile/1 returns a bot_profile changeset" do
      bot_profile = bot_profile_fixture()
      assert %Ecto.Changeset{} = Bots.change_bot_profile(bot_profile)
    end

    test "change_bot_profile/2 returns a bot_profile changeset with changes" do
      bot_profile = bot_profile_fixture()
      attrs = %{prompt: "New prompt"}
      changeset = Bots.change_bot_profile(bot_profile, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes[:prompt] == "New prompt"
    end
  end

  describe "bot_profiles changeset validation" do
    alias Chat.Bots.BotProfile

    import Chat.BotsFixtures
    import Chat.ConversationsFixtures

    test "changeset with valid attributes" do
      bot_model = bot_model_fixture()
      persona = persona_fixture(%{role: "bot"})

      attrs = %{
        prompt: "Test prompt",
        bot_model_id: bot_model.id,
        persona_id: persona.id
      }

      changeset = BotProfile.changeset(%BotProfile{}, attrs)
      assert changeset.valid?
    end

    test "changeset requires prompt" do
      bot_model = bot_model_fixture()
      persona = persona_fixture(%{role: "bot"})

      attrs = %{bot_model_id: bot_model.id, persona_id: persona.id}
      changeset = BotProfile.changeset(%BotProfile{}, attrs)

      refute changeset.valid?
      assert %{prompt: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires bot_model_id" do
      persona = persona_fixture(%{role: "bot"})

      attrs = %{prompt: "Test prompt", persona_id: persona.id}
      changeset = BotProfile.changeset(%BotProfile{}, attrs)

      refute changeset.valid?
      assert %{bot_model_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset allows missing persona_id" do
      bot_model = bot_model_fixture()

      attrs = %{prompt: "Test prompt", bot_model_id: bot_model.id}
      changeset = BotProfile.changeset(%BotProfile{}, attrs)

      # persona_id is not required by the changeset validation
      assert changeset.valid?
    end

    test "changeset casts persona association" do
      bot_model = bot_model_fixture()

      attrs = %{
        prompt: "Test prompt",
        bot_model_id: bot_model.id,
        persona: %{
          name: "Test Bot",
          role: "bot",
          avatar: "test.png"
        }
      }

      changeset = BotProfile.changeset(%BotProfile{}, attrs)
      assert changeset.valid?

      # Check that persona changeset is included
      assert %Ecto.Changeset{} = changeset.changes[:persona]
      assert changeset.changes[:persona].changes[:name] == "Test Bot"
    end

    test "changeset handles invalid persona data" do
      bot_model = bot_model_fixture()

      attrs = %{
        prompt: "Test prompt",
        bot_model_id: bot_model.id,
        persona: %{
          # Invalid - name is required for persona
          name: nil,
          role: "bot"
        }
      }

      changeset = BotProfile.changeset(%BotProfile{}, attrs)
      refute changeset.valid?
    end

    test "changeset ignores unknown fields" do
      bot_model = bot_model_fixture()
      persona = persona_fixture(%{role: "bot"})

      attrs = %{
        prompt: "Test prompt",
        bot_model_id: bot_model.id,
        persona_id: persona.id,
        unknown_field: "should be ignored"
      }

      changeset = BotProfile.changeset(%BotProfile{}, attrs)
      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end
  end
end
