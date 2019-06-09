defmodule Chord do
  [num_nodes, num_requests] = System.argv()
  num_nodes = String.to_integer(num_nodes)
  num_requests = String.to_integer(num_requests)
  Chord.API.main(num_nodes, num_requests)

end
