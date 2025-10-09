defmodule ChatWeb.UserLoginLive do
  use ChatWeb, :live_view

  def render(assigns) do
    ~H"""
    <div
      class="min-h-screen bg-gradient-to-b from-gray-800 to-gray-900 flex items-center justify-center"
      phx-hook="AutoLogin"
      id="login-page"
    >
      <div class="text-center">
        <%= if @timer_done do %>
          <div class="space-y-6">
            <p class="text-2xl text-white mb-8">Click to verify you're human</p>
            <label class="inline-flex items-center space-x-3 cursor-pointer">
              <input
                type="checkbox"
                name="verify"
                class="w-6 h-6 cursor-pointer"
                checked={@checked}
                phx-click="check_box"
              />
              <span class="text-xl text-white">I am human</span>
            </label>
          </div>
        <% else %>
          <div class="text-4xl text-white font-bold">
            <%= @seconds %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :tick, 1000)
    end

    {:ok,
     assign(socket,
       seconds: 3,
       timer_done: false,
       checked: false
     )}
  end

  def handle_info(:tick, socket) do
    seconds = socket.assigns.seconds - 1

    if seconds > 0 do
      Process.send_after(self(), :tick, 1000)
      {:noreply, assign(socket, seconds: seconds)}
    else
      {:noreply, assign(socket, timer_done: true)}
    end
  end

  def handle_event("check_box", _params, socket) do
    if socket.assigns.checked do
      # Already checked, uncheck it
      {:noreply, assign(socket, checked: false)}
    else
      # Check it and trigger login via JavaScript
      {:noreply,
       socket
       |> assign(checked: true)
       |> push_event("auto_login", %{})}
    end
  end
end
