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
end
