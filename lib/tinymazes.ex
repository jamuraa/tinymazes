require Board
require Integer

defmodule TinyMazes do
  @moduledoc """
  Documentation for TinyMazes.
  """

  @doc """
  A program to make tiny mazes.

  ## Examples

      iex> TinyMazes.make_basic(5, 5)

  """
  def hello do
    :world
  end

  defp empty_spots(spots, board) do
    Enum.reduce(spots, board, fn ([x, y], b) -> Board.empty(b, x, y) end)
  end

  def open_startend(%Board{rows: rows, cols: cols} = board) do
    top_slots = Enum.filter_map(0..cols-1, &Integer.is_odd/1, fn (x) -> [0, x] end)
    lside_slots = Enum.filter_map(0..rows-1, &Integer.is_odd/1, fn (x) -> [x, 0] end)
    bottom_slots = Enum.filter_map(0..cols-1, &Integer.is_odd/1, fn (x) -> [rows-1, x] end)
    rside_slots = Enum.filter_map(0..rows-1, &Integer.is_odd/1, fn (x) -> [x, cols-1] end)
    (top_slots ++ bottom_slots ++ lside_slots ++ rside_slots) |> Enum.take_random(2) |> empty_spots(board)
  end

  def fill_trees(board, count \\ ?0) do
    blank_spaces = Board.find(board)
    cond do
      length(blank_spaces) == 0 -> board
      count == ?x -> fill_trees(board, count + 1)
      true -> blank_spaces |> List.first |> (fn([x, y]) -> Board.flood_fill(board, x, y, count) end).() |> fill_trees(count + 1)
    end
  end

  def find_spots(%Board{rows: rows, cols: cols} = b) do
    Board.find(b, ?x) |> Enum.map(fn([x, y]) ->
      tb = Board.get(b, [[x-1, y], [x+1, y]]) |> Enum.reject(fn(x) -> x == ?x end) |> Enum.uniq
      lr = Board.get(b, [[x, y-1], [x, y+1]]) |> Enum.reject(fn(x) -> x == ?x end) |> Enum.uniq
      cond do
        x < 1 || x >= rows || y < 1 || y >= cols -> {[x, y], :error}
        length(tb) > 1 -> {[x, y], tb}
        length(lr) > 1 -> {[x, y], lr}
        true -> {[x, y], :error}
      end
    end) |> Enum.filter(fn ({_, val}) -> val != :error end)
  end

  def reconcile_spots(from, to, spots) do
    Enum.filter_map(spots, fn
                      {_, [nextfrom, nextto]} when nextfrom == from and nextto == to -> false
                      {_, [nextfrom, nextto]} when nextfrom == to and nextto == from -> false
                      _ -> true
    end, fn
      {coord, [nextfrom, nextto]} when nextto == from -> {coord, [nextfrom, to]}
      {coord, [nextfrom, nextto]} when nextfrom == from -> {coord, [to, nextto]}
      val -> val
    end)
  end

  def empty_trees(%Board{rows: rows, cols: cols} = b) do
    Enum.reduce(Board.find(b, ?x), Board.make(rows, cols), fn([x, y], b) -> Board.fill(b, x, y) end)
  end

  defp complete_maze(%Board{} = board, valid_spots \\ :gen) do
    board |> empty_trees |> Board.print_unicode
    case valid_spots do
      :gen -> complete_maze(board, Enum.shuffle(find_spots(board)))
      [] -> board
      [{[x, y], [from, to]} | rest] -> complete_maze(Board.fill(board, x, y, to) |> Board.replace(from, to), reconcile_spots(from, to, rest))
    end
  end

  def make_basic(rows \\ 43, cols \\ 43) do
    Board.make_grid(rows, cols) |> open_startend |> fill_trees |> complete_maze
  end
end
