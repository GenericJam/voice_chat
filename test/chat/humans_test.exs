defmodule Chat.HumansTest do
  use Chat.DataCase

  alias Chat.Humans

  describe "humans" do
    alias Chat.Humans.Human

    import Chat.HumansFixtures

    @invalid_attrs %{name: nil, hash: nil, photo: nil}

    test "list_humans/0 returns all humans" do
      human = human_fixture()
      assert Humans.list_humans() == [human]
    end

    test "get_human!/1 returns the human with given id" do
      human = human_fixture()
      assert Humans.get_human!(human.id) == human
    end

    test "create_human/1 with valid data creates a human" do
      valid_attrs = %{name: "some name", hash: "some hash", photo: "some photo"}

      assert {:ok, %Human{} = human} = Humans.create_human(valid_attrs)
      assert human.name == "some name"
      assert human.hash == "some hash"
      assert human.photo == "some photo"
    end

    test "create_human/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Humans.create_human(@invalid_attrs)
    end

    test "update_human/2 with valid data updates the human" do
      human = human_fixture()

      update_attrs = %{
        name: "some updated name",
        hash: "some updated hash",
        photo: "some updated photo"
      }

      assert {:ok, %Human{} = human} = Humans.update_human(human, update_attrs)
      assert human.name == "some updated name"
      assert human.hash == "some updated hash"
      assert human.photo == "some updated photo"
    end

    test "update_human/2 with invalid data returns error changeset" do
      human = human_fixture()
      assert {:error, %Ecto.Changeset{}} = Humans.update_human(human, @invalid_attrs)
      assert human == Humans.get_human!(human.id)
    end

    test "delete_human/1 deletes the human" do
      human = human_fixture()
      assert {:ok, %Human{}} = Humans.delete_human(human)
      assert_raise Ecto.NoResultsError, fn -> Humans.get_human!(human.id) end
    end

    test "change_human/1 returns a human changeset" do
      human = human_fixture()
      assert %Ecto.Changeset{} = Humans.change_human(human)
    end
  end
end
