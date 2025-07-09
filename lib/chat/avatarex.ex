defmodule Chat.Avatarex do
  @moduledoc """
   This involves using the `Avatarex` module and invoking the `Avatarex.set/2` macro for
  each: set name, module.
  """

  use Avatarex

  @renders_path "/priv/static/avatars"

  @replace_chars ["@", ".", "-", ":", " ", "+"]

  alias Avatarex.Sets.{
    Robot,
    BotBlue,
    BotBrown,
    BotGreen,
    BotGrey,
    BotOrange,
    BotPink,
    BotPurple,
    BotRed,
    BotWhite,
    BotYellow
  }

  for {name, module} <- [
        robot: Robot,
        bot_blue: BotBlue,
        bot_brown: BotBrown,
        bot_green: BotGreen,
        bot_grey: BotGrey,
        bot_orange: BotOrange,
        bot_pink: BotPink,
        bot_purple: BotPurple,
        bot_red: BotRed,
        bot_white: BotWhite,
        bot_yellow: BotYellow
      ] do
    set(name, module)
  end

  def avatar!(name, set \\ :bot_white) do
    result =
      %Avatarex{
        name: _,
        set: _,
        renders_path: _
      } =
      generate(name |> String.replace(@replace_chars, "_"), set)
      |> then(fn %Avatarex{} = av ->
        # Have to do this hacky bullshit to inject this value that's otherwise set by a macro at compile time so doesn't work in release
        %Avatarex{
          image: av.image,
          name: av.name,
          set: av.set,
          renders_path: Application.app_dir(:chat, @renders_path),
          images: av.images
        }
      end)
      |> render()
      |> write()

    "#{result.name}_#{result.set}.png"
  end

  def name!(name, set \\ :bot_white) do
    result =
      %Avatarex{
        name: _,
        set: _,
        renders_path: _
      } =
      generate(name |> String.replace(@replace_chars, "_"), set)

    "#{result.name}_#{result.set}.png"
  end
end
