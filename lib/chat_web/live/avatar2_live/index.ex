defmodule ChatWeb.Avatar2Live.Index do
  use ChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "HeadTTS Avatar Demo")

    {:ok, socket, layout: false}
  end
end
