defmodule Chord.API do
  @keys_to_nodes 5 #ratio
  @offset_for_m 3 #to avoid a dense ring

  @doc """
  main function
  """
  def main(num_nodes, num_requests) do
    num_keys = get_num_keys(num_nodes)
    m = get_ring_size(num_nodes, num_keys)
    hashmap = generate_nodes(num_nodes, m, %{})
    pair_list = join_nodes(hashmap)
    fix_fingers(pair_list)

    search_keys(num_requests, pair_list, (:math.pow(2, m) |> round()) - 1)
    total_hops = listen(num_requests * num_nodes, 0)
    average_hops_per_search = total_hops / (num_requests * num_nodes)
    IO.puts "Average number of hops to find keys are #{average_hops_per_search}"

    # Failure Model

    {random_node_id, random_node_pid} = Enum.random(pair_list)

    IO.puts "Implementing the failure model now by killing a random node from the ring. . ."

    send(random_node_pid, {:kill_self})

    killed_node_pid = inspect(random_node_pid)

    IO.puts "Killed node with PID: #{killed_node_pid}"

    new_pair_list = pair_list -- [{random_node_id, random_node_pid}]

    fix_fingers(new_pair_list)

    search_keys(num_requests, new_pair_list, (:math.pow(2, m) |> round()) - 1)

    total_hops = listen(num_requests * (num_nodes - 1), 0)
    average_hops_per_search = total_hops / (num_requests * (num_nodes - 1))
    IO.puts "Average number of hops to find keys after single node failure are #{average_hops_per_search}"


  end


  @doc """
  listens to the messages from nodes once the key is searched
  """
  def listen(remaining_requests, hops) do
    receive do
      {:hops, num_hops} ->
        remaining_requests = remaining_requests - 1

        if remaining_requests > 0 do
          listen(remaining_requests, hops + num_hops)
        else
          hops
        end
    end
  end

  @doc """
  returns number of keys to be inserted into the ring.
  """
  def get_num_keys(num_nodes) do
    num_nodes * @keys_to_nodes
  end

  @doc """
  returns the size of the ring in power of 2
  """
  def get_ring_size(num_nodes, num_keys) do
    :math.log2(num_nodes + num_keys) + @offset_for_m |> :math.ceil() |> round()
  end

  @doc """
  creates GenServers and returns the hashmap of hashed id and pid
  """
  def generate_nodes(n, m, hashmap) do
    if n > 0 do
      {:ok, pid} = Chord.Node.start_link(%{
        :predecessor => nil,
        :successor => nil,
        :id => nil,
        :m => m,
        :timer => 500,
        :finger_table => []
      })
      pid_hash = :crypto.hash(:sha, inspect(pid))
      id = Chord.Helper.byte_to_integer(pid_hash, m)
      hashmap_val = Map.get(hashmap, id)

      {hashmap, n} =
      if hashmap_val == nil do
        {Map.put(hashmap, id, pid), n - 1}
      else
        send(pid, {:kill_self})
        {hashmap, n}
      end
      generate_nodes(n, m, hashmap)
    else
      hashmap
    end
  end

  @doc """
  joins the floating nodes into one unit.
  returns the first node - node with smallest id
  """
  def join_nodes(hashmap) do
    pair_list = []

    pair_list =
    for {k, v} <- hashmap do
      pair_list ++ {k, v}
    end

    # sorted by id
    pair_list = pair_list |> List.keysort(0)

    {last_id, last_pid} = connect_two_nodes(pair_list)

    [{first_id, first_pid} | _] = pair_list

    send(first_pid, {:add_predecessor_id, last_id, last_pid})
    send(last_pid, {:add_successor_id, first_id, first_pid})

    pair_list
  end


  @doc """
  connects two nodes by adding successor for first node and predecessor
  for second node
  """
  def connect_two_nodes([{predecessor_id, predecessor_pid} | rest]) do

    if rest == [] do
      send(predecessor_pid, {:add_self_id, predecessor_id, predecessor_pid})
      {predecessor_id, predecessor_pid}
    else
      [{present_id, present_pid} | _] = rest

      # add self details for predecessor
      send(predecessor_pid, {:add_self_id, predecessor_id, predecessor_pid})

      # add successor for predecessor
      send(predecessor_pid, {:add_successor_id, present_id, present_pid})

      # add predecessor for successor
      send(present_pid, {:add_predecessor_id, predecessor_id, predecessor_pid})

      connect_two_nodes(rest)

    end

  end


  @doc """
  calls fix fingers on all the nodes
  """
  def fix_fingers(pair_list) do
    Enum.each pair_list, fn {_, pid} ->
      send(pid, {:fix_fingers, pair_list})
    end
  end

  def search_keys(num_requests, pair_list, num_positions) do
    Enum.each pair_list, fn {_, pid} ->
      send(pid, {:search_keys, num_requests, num_positions, self()})
    end
  end

end
