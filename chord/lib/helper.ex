defmodule Chord.Helper do

  @doc """
  converts the given 20 byte hashed value into an integer by considering
  the least significant num_bits bits
  """
  def byte_to_integer(bytes, num_bits) do
    cond do
      num_bits == 0 -> 0

      rem(num_bits, 8) == 0 ->
        posn = div(num_bits, 8)

        <<byte::8>> = binary_part(bytes, 20-posn, 1)
        (byte * :math.pow(16, posn - 1) |> round()) + byte_to_integer(bytes, num_bits - 8)

      true ->
        posn = div(num_bits, 8) + 1
        num_odd_bits = rem(num_bits, 8)

        <<byte::8>> = binary_part(bytes, 20-posn, 1)

        valid_value = rem(byte, :math.pow(2, num_odd_bits) |> round())
        (valid_value * :math.pow(16, posn) |> round()) + byte_to_integer(bytes, num_bits - num_odd_bits)
    end
  end
end

