defmodule ChatWeb.Components.SideBar do
  use ChatWeb, :live_view

  use Phoenix.Component

  def conversations_sidebar(assigns) do
    ~H"""
    <aside class={[
      "mt-[-45px]",
      if(@open,
        do:
          "w-full md:w-1/4 md:min-w-[250px] min-h-screen bg-gray-200 dark:bg-gray-800 flex flex-col",
        else: "w-[0px]"
      )
    ]}>
      <div class={["p-4 ", if(@open, do: "border-b border-gray-300 dark:border-gray-700", else: "")]}>
        <.button
          phx-click={JS.push("toggle-conversations", value: %{open: !@open})}
          class={["float-right ", if(@open, do: "mr-[55px] md:mr-0", else: "fixed left-[3px] top-3")]}
        >
          <.icon
            name={
              if(@open, do: "hero-arrow-left-start-on-rectangle", else: "hero-chat-bubble-left-right")
            }
            class="h-5 w-5"
          />
        </.button>
        <%= if @open do %>
          <h1 class="text-xl font-semibold">Conversations</h1>
        <% end %>
      </div>
      <%= if @open do %>
        <nav class="flex-1 overflow-y-auto p-4 space-y-2">
          <a
            href={~p"/chat/new"}
            class="w-full text-left px-4 py-2 bg-gray-300 dark:bg-gray-700 rounded hover:bg-gray-400 dark:hover:bg-gray-600 pb-100"
          >
            New Chat
          </a>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1 min-h-2"></p>
          <div :for={conversation <- @conversations} class="mt-4 space-y-2">
            <a
              href={~p"/chat/#{conversation.id}"}
              class="truncate w-full text-left px-4 py-2 bg-gray-300 dark:bg-gray-700 rounded hover:bg-gray-400 dark:hover:bg-gray-600"
            >
              {conversation.name}
            </a>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {conversation.inserted_at |> Timex.format!("{0M}/{0D} {h12}:{0m}:{0s} {am}")}
            </p>
          </div>
        </nav>
      <% end %>
    </aside>
    """
  end

  def bots_sidebar(assigns) do
    ~H"""
    <aside
      id="bot-info"
      class={[
        " p-4 fixed inset-y-0 right-0 overflow-y-auto min-h-screen",
        if(@open,
          do: "w-11/12 md:w-1/4 md:min-w-[250px] bg-gray-200 dark:bg-gray-800",
          else: "w-[100px] bg-transparent"
        )
      ]}
    >
      <%!-- <header class="bg-gray-200 dark:bg-gray-800 p-4 shadow-md sticky top-0 z-10"> --%>
      <div class="flex flex-col">
        <div class="col-span-1">
          <.button phx-click={JS.push("toggle-bots", value: %{open: !@open})}>
            <img src={~p"/avatars/#{@bot_selected.persona.avatar}"} class="min-h-12 max-h-24" />
          </.button>
        </div>
        <div class={[if(@open, do: "", else: "hidden")]}>
          <div class="col-span-1">
            <div class="grid grid-cols-6">
              <div class="col-span-1">
                <p class="text-lg font-semibold m-3 mt-5">
                  <.form for={@bot_profiles} phx-change="allow_bot_response_change" class="">
                    <.input
                      class="bg-gray-100 text-gray-900  px-3 py-2 rounded shadow-sm border border-gray-300 dark:border-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500"
                      name="allow_bot_response"
                      type="checkbox"
                      value={@allow_bot_response}
                    />
                  </.form>
                </p>
              </div>
              <div class="col-span-5">
                <p class="text-lg font-semibold m-3">Allow bots to respond to each other.</p>
              </div>
            </div>
          </div>
          <div class="col-span-1">
            <h2 class="text-lg font-semibold m-3">
              <a href={~p"/bot_profiles"} class="">
                <.icon name="hero-cog-6-tooth-solid" /> Chat With
              </a>
            </h2>
            <.form for={@bot_profiles} phx-change="bot_profile_change" class="">
              <.input
                class="bg-gray-100 text-gray-900  px-3 py-2 rounded shadow-sm border border-gray-300 dark:border-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500"
                name="bot_profile_name"
                type="select"
                options={@bot_profiles}
                value={@bot_selected.persona.name}
              />
            </.form>
          </div>
          <div class="col-span-1">
            <h2 class="text-lg font-semibold m-3">Chat Model</h2>
            <p class="bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-200 px-3 py-2 rounded shadow-sm border border-gray-300 dark:border-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 dark:focus:ring-gray-400">
              {@bot_selected.bot_model.name}
            </p>
          </div>
        </div>
      </div>
      <%!-- </header> --%>
    </aside>
    """
  end
end
