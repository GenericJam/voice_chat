defmodule ChatWeb.ScoreLive.Index do
  use ChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Generate random score (two numbers between 10 and 99)
    score1 = Enum.random(10..99)
    score2 = Enum.random(10..99)

    socket =
      socket
      |> assign(:page_title, "Score Verification")
      |> assign(:target_score1, score1)
      |> assign(:target_score2, score2)
      |> assign(:user_score1, 0)
      |> assign(:user_score2, 0)
      |> assign(:message, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_segment", %{"digit" => digit, "segment" => segment}, socket) do
    # Convert digit and segment to integers
    digit = String.to_integer(digit)
    segment = String.to_integer(segment)

    # Get current score for this digit (0-3, where 0-1 are score1, 2-3 are score2)
    {current_value, score_key} =
      if digit < 2 do
        {socket.assigns.user_score1, :user_score1}
      else
        {socket.assigns.user_score2, :user_score2}
      end

    # Get the digit position (tens or ones)
    digit_pos = rem(digit, 2)

    # Extract the tens and ones from current value
    tens = div(current_value, 10)
    ones = rem(current_value, 10)

    # Get the current digit value (tens or ones)
    current_digit = if digit_pos == 0, do: tens, else: ones

    # Toggle the segment and get new digit value
    new_digit = toggle_segment_value(current_digit, segment)

    # Reconstruct the full score
    new_value =
      if digit_pos == 0 do
        new_digit * 10 + ones
      else
        tens * 10 + new_digit
      end

    # Clamp to 0-99
    new_value = max(0, min(99, new_value))

    socket = assign(socket, score_key, new_value)

    # Check if they got it right
    socket = check_score(socket)

    {:noreply, socket}
  end

  defp toggle_segment_value(current_digit, segment) do
    # Seven segment display mapping
    # Each digit 0-9 has specific segments lit
    segments = digit_to_segments(current_digit)

    # Toggle the segment
    new_segments =
      if segment in segments do
        List.delete(segments, segment)
      else
        [segment | segments]
      end

    # Find which digit matches these segments
    segments_to_digit(Enum.sort(new_segments))
  end

  defp digit_to_segments(0), do: [0, 1, 2, 3, 4, 5]
  defp digit_to_segments(1), do: [1, 2]
  defp digit_to_segments(2), do: [0, 1, 3, 4, 6]
  defp digit_to_segments(3), do: [0, 1, 2, 3, 6]
  defp digit_to_segments(4), do: [1, 2, 5, 6]
  defp digit_to_segments(5), do: [0, 2, 3, 5, 6]
  defp digit_to_segments(6), do: [0, 2, 3, 4, 5, 6]
  defp digit_to_segments(7), do: [0, 1, 2]
  defp digit_to_segments(8), do: [0, 1, 2, 3, 4, 5, 6]
  defp digit_to_segments(9), do: [0, 1, 2, 3, 5, 6]

  defp segments_to_digit(segments) do
    sorted = Enum.sort(segments)

    cond do
      sorted == [0, 1, 2, 3, 4, 5] -> 0
      sorted == [1, 2] -> 1
      sorted == [0, 1, 3, 4, 6] -> 2
      sorted == [0, 1, 2, 3, 6] -> 3
      sorted == [1, 2, 5, 6] -> 4
      sorted == [0, 2, 3, 5, 6] -> 5
      sorted == [0, 2, 3, 4, 5, 6] -> 6
      sorted == [0, 1, 2] -> 7
      sorted == [0, 1, 2, 3, 4, 5, 6] -> 8
      sorted == [0, 1, 2, 3, 5, 6] -> 9
      true -> 0
    end
  end

  defp check_score(socket) do
    if socket.assigns.user_score1 == socket.assigns.target_score1 &&
         socket.assigns.user_score2 == socket.assigns.target_score2 do
      assign(socket, :message, "✓ VERIFIED! You are human!")
    else
      socket
    end
  end
end
