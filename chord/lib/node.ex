defmodule Chord.Node do
  use GenServer

  @doc """
  start_link function
  """
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @doc """
  init function
  """
  def init(args) do
    {:ok, args}
  end

  @doc """
  adds the successor entry to the node state
  """
  def add_successor_id(id, pid, state) do
    Map.put(state, :successor, {id, pid})
  end

  @doc """
  adds the predecessor entry to the node state
  """
  def add_predecessor_id(id, pid, state) do
    Map.put(state, :predecessor, {id, pid})
  end

  @doc """
  adss the self details of id and pid to the node state
  """
  def add_self_id(id, pid, state) do
    Map.put(state, :id, {id, pid})
  end

  @doc """
  fixes fingers for each node
  """
  def fix_fingers(pair_list, state) do
    {self_id, _} = Map.get(state, :id)
    m = Map.get(state, :m)
    find_successor(0, m, self_id, pair_list, pair_list, state)
  end

  @doc """
  finds successors for entries in finger table
  """
  def find_successor(start, m, id, partial_pair_list, full_pair_list, state) do
    finger_id = id + :math.pow(2, start) |> round()
    mod_val = :math.pow(2, m) |> round()
    finger_id = rem(finger_id, mod_val)
    [head | rest] = partial_pair_list
    {head_id, head_pid} = head

    finger_table = Map.get(state, :finger_table)

    {start, state, partial_pair_list} =
    cond do
      start == m -> {start, state, partial_pair_list}

      finger_id == head_id ->
        finger_table = [{:math.pow(2, start) |> round(), head_id, head_pid}] ++ finger_table
        {start + 1, Map.put(state, :finger_table, finger_table), partial_pair_list}


      rest == [] and finger_id > head_id ->
        [{new_head_id, new_head_pid} | _] = full_pair_list
        finger_table = [{:math.pow(2, start) |> round(), new_head_id, new_head_pid}] ++ finger_table
        {start + 1, Map.put(state, :finger_table, finger_table), partial_pair_list}


      finger_id > head_id ->

        [next | _] = rest
        {next_id, next_pid} = next
        if next_id >= finger_id do
          finger_table = [{:math.pow(2, start) |> round(), next_id, next_pid}] ++ finger_table
          {start + 1, Map.put(state, :finger_table, finger_table), partial_pair_list}
        else
          {start, state, rest}
        end


      rest == [] and finger_id < head_id ->
        [new_head | _] = full_pair_list
        {new_head_id, new_head_pid} = new_head

        if new_head_id > finger_id do
          finger_table = [{:math.pow(2, start) |> round(), new_head_id, new_head_pid}] ++ finger_table
          {start + 1, Map.put(state, :finger_table, finger_table), partial_pair_list}
        else
          {start, state, full_pair_list}
        end

      finger_id < head_id -> {start, state, rest}

    end

    if start !== m  do
      find_successor(start, m, id, partial_pair_list, full_pair_list, state)
    else
      state
    end

  end

  @doc """
  searches for the keys
  """
  def search_keys(num_requests, num_positions, main_pid, state) do
    if num_requests > 0 do
      key_id = Enum.random(0..num_positions)
      find_successor(key_id, main_pid, 0, state)
      search_keys(num_requests - 1, num_positions, main_pid, state)
    end
  end

  @doc """
  finds successor
  """
  def find_successor(key_id, main_pid, num_hops, state) do

    {self_id, _} = Map.get(state, :id)
    {successor_id, _} = Map.get(state, :successor)
    m = Map.get(state, :m)
    ring_size = :math.pow(2, m) - 1
    cond do
      key_id == self_id -> send(main_pid, {:hops, num_hops})
      successor_id < self_id and key_id > self_id ->
        send(main_pid, {:hops, num_hops + 1})
      key_id <= successor_id and key_id > self_id ->
        send(main_pid, {:hops, num_hops + 1})
      true ->
        finger_table = Map.get(state, :finger_table)
        {closest_id, closest_pid} = find_closest_preceding_node(key_id, self_id, ring_size, main_pid, finger_table)
        if closest_id == self_id do
          send(main_pid, {:hops, num_hops})
        else
          GenServer.cast(closest_pid, {:find_successor, key_id, main_pid, num_hops + 1})
        end
    end
  end


  @doc """
  finds the closest preceding node for key_id in its finger table
  """
  def find_closest_preceding_node(key_id, self_id, ring_size, main_pid, [finger | finger_table]) do
    {_, finger_id, finger_pid} = finger
    new_key_id =
      if key_id < self_id do
        key_id + ring_size
      else
        key_id
      end

    cond do
      key_id < self_id and finger_id > self_id and new_key_id > finger_id -> {finger_id, finger_pid}

      key_id > finger_id and finger_id > self_id -> {finger_id, finger_pid}
      finger_table == [] -> {self_id, nil}
      true -> find_closest_preceding_node(key_id, self_id, ring_size, main_pid, finger_table)
    end

  end


  @doc """
  Callbacks
  """

  def handle_info({:kill_self}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:add_self_id, id, pid}, state) do
    state = add_self_id(id, pid, state)
    {:noreply, state}
  end

  def handle_info({:add_successor_id, id, pid}, state) do
    state = add_successor_id(id, pid, state)
    {:noreply, state}
  end

  def handle_info({:add_predecessor_id, id, pid}, state) do
    state = add_predecessor_id(id, pid, state)
    {:noreply, state}
  end

  def handle_info({:fix_fingers, pair_list}, state) do
    state = Map.put(state, :finger_table, [])
    state = fix_fingers(pair_list, state)
    {:noreply, state}
  end

  def handle_info({:search_keys, num_requests, num_positions, main_pid}, state) do
    search_keys(num_requests, num_positions, main_pid, state)
    {:noreply, state}
  end

  def handle_cast({:find_successor, key_id, main_pid, num_hops}, state) do
    find_successor(key_id, main_pid, num_hops, state)
    {:noreply, state}
  end

end
