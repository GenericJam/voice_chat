defmodule ChatWeb.ScoreboardComponents do
  use Phoenix.Component

  attr :digit, :integer, required: true
  attr :value, :integer, required: true

  def seven_segment(assigns) do
    ~H"""
    <div class="relative w-28 h-40">
      <%!-- Segment layout:
           0: top
           1: top-right
           2: bottom-right
           3: bottom
           4: bottom-left
           5: top-left
           6: middle
      --%>

      <%!-- Top (segment 0) --%>
      <.segment
        digit={@digit}
        segment={0}
        active={0 in digit_segments(@value)}
        class="absolute top-0 left-5 w-18 h-4"
        horizontal={true}
      />

      <%!-- Top-right (segment 1) --%>
      <.segment
        digit={@digit}
        segment={1}
        active={1 in digit_segments(@value)}
        class="absolute top-3 right-0 w-4 h-16"
        horizontal={false}
      />

      <%!-- Bottom-right (segment 2) --%>
      <.segment
        digit={@digit}
        segment={2}
        active={2 in digit_segments(@value)}
        class="absolute bottom-3 right-0 w-4 h-16"
        horizontal={false}
      />

      <%!-- Bottom (segment 3) --%>
      <.segment
        digit={@digit}
        segment={3}
        active={3 in digit_segments(@value)}
        class="absolute bottom-0 left-5 w-18 h-4"
        horizontal={true}
      />

      <%!-- Bottom-left (segment 4) --%>
      <.segment
        digit={@digit}
        segment={4}
        active={4 in digit_segments(@value)}
        class="absolute bottom-3 left-0 w-4 h-16"
        horizontal={false}
      />

      <%!-- Top-left (segment 5) --%>
      <.segment
        digit={@digit}
        segment={5}
        active={5 in digit_segments(@value)}
        class="absolute top-3 left-0 w-4 h-16"
        horizontal={false}
      />

      <%!-- Middle (segment 6) --%>
      <.segment
        digit={@digit}
        segment={6}
        active={6 in digit_segments(@value)}
        class="absolute top-1/2 -translate-y-1/2 left-5 w-18 h-4"
        horizontal={true}
      />
    </div>
    """
  end

  attr :digit, :integer, required: true
  attr :segment, :integer, required: true
  attr :active, :boolean, required: true
  attr :class, :string, required: true
  attr :horizontal, :boolean, required: true

  defp segment(assigns) do
    ~H"""
    <button
      phx-click="toggle_segment"
      phx-value-digit={@digit}
      phx-value-segment={@segment}
      class={[
        @class,
        "cursor-pointer transition-all duration-200 rounded-sm",
        if(@active,
          do: "bg-red-500 shadow-lg shadow-red-500/50",
          else: "bg-gray-800 hover:bg-gray-700"
        )
      ]}
      style="z-index: 10;"
    >
    </button>
    """
  end

  defp digit_segments(0), do: [0, 1, 2, 3, 4, 5]
  defp digit_segments(1), do: [1, 2]
  defp digit_segments(2), do: [0, 1, 3, 4, 6]
  defp digit_segments(3), do: [0, 1, 2, 3, 6]
  defp digit_segments(4), do: [1, 2, 5, 6]
  defp digit_segments(5), do: [0, 2, 3, 5, 6]
  defp digit_segments(6), do: [0, 2, 3, 4, 5, 6]
  defp digit_segments(7), do: [0, 1, 2]
  defp digit_segments(8), do: [0, 1, 2, 3, 4, 5, 6]
  defp digit_segments(9), do: [0, 1, 2, 3, 5, 6]
end
