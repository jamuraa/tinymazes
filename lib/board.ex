defmodule Board do
  @moduledoc """
  A tiny module for manipulating boards.
  A board is a grid of items represented by integers.
  Normally, boards are blank and are filled with .
  Filled spaxes are represented with x
  """

  defstruct [:cols, :rows, :pixels]

  defp list_x(num, list) do
    List.duplicate(list, num) |> List.flatten
  end

  defp make_pixels(rows, cols) do
    List.duplicate(?., rows * cols)
  end

  def make(rows \\ 43, cols \\ 43) do
    %Board{rows: rows, cols: cols, pixels: make_pixels(rows, cols)}
  end

  def fill(%Board{rows: rows, cols: cols, pixels: p} = board, x, y, char \\ ?x) when x >= 0 and x < rows and y >= 0 and y < cols do
    %Board{board | pixels: List.replace_at(p, x * cols + y, char)}
  end

  def replace(%Board{pixels: p} = board, from, to) do
    %Board{board | pixels: Enum.map(p, fn (x) -> if(x == from, do: to, else: x) end) }
  end

  defp flood_fill_queue(board, [], _) do
    board
  end

  defp flood_fill_queue(%Board{rows: rows, cols: cols} = board, [[x, y] | rest], char) do
    cond do
      x < 0 || y < 0 || x >= rows || y >= cols -> flood_fill_queue(board, rest, char)
      at(board, x, y) != ?. -> flood_fill_queue(board, rest, char)
      true -> fill(board, x, y, char) |> flood_fill_queue([[x-1, y], [x+1, y], [x, y-1], [x, y+1]] ++ rest, char)
    end
  end

  def flood_fill(%Board{} = board, x, y, char \\ ?x) do
    flood_fill_queue(board, [[x, y]], char)
  end

  def coords(%Board{rows: rows, cols: cols}) do
    Enum.zip([0..rows-1 |> Enum.map(&List.duplicate(&1, cols)) |> List.flatten, Enum.to_list(0..cols-1) |> List.duplicate(rows) |> List.flatten]) |> Enum.map(&Tuple.to_list/1)
  end

  def find(%Board{} = board, char \\ ?.) do
    Enum.filter(coords(board), fn([x, y]) -> at(board, x, y) == char end)
  end

  def empty(%Board{} = board, x, y) do
    Board.fill(board, x, y, ?.)
  end

  def at(%Board{pixels: p, rows: rows, cols: cols}, x, y) when x >= 0 and y >= 0 and x < rows and y < cols do
    Enum.at(p, x * cols + y)
  end

  def get(%Board{rows: rows, cols: cols} = b, coords) do
    case coords do
      [] -> []
      [[x, y] | rest] when x >= 0 and y >= 0 and x < rows and y < cols -> [at(b, x, y) | get(b, rest)]
      [_ | rest] -> get(b, rest)
    end
  end

  def square(%Board{} = board, x1, y1, x2, y2) do
    Enum.reduce(y1..y2, Enum.reduce(x1..x2, board, fn(x, board) -> Board.fill(board, x, y1) |> Board.fill(x, y2) end), fn(y, board) -> Board.fill(board, x1, y) |> Board.fill(x2, y) end)
  end

  def print(%Board{pixels: p, cols: cols}) do
    String.codepoints(p) 
    |> Enum.chunk(cols) 
    |> Enum.map(fn(row) -> Enum.join(row) end)
    |> Enum.map(fn(x) -> x <> "\n" end) 
    |> Enum.join |> IO.puts
  end

  def print_unicode(%Board{} = b) do
    b |> unicode |> IO.puts
  end

  def area(%Board{pixels: p, rows: rows, cols: cols}, x1, y1, x2, y2) when x2 >= x1 and y2 >= y1 and x2 < rows and y2 < cols do
    %Board{rows: x2 - x1 + 1, cols: y2 - y1 + 1, pixels: Enum.flat_map(x1..x2, fn (x) -> Enum.slice(p, x * cols + y1, y2 - y1 + 1) end)}
  end

  def unicode(%Board{pixels: p, rows: 2, cols: 2}) do
    case p do
      'x...' -> "\u2598"
      '.x..' -> "\u259D"
      '..x.' -> "\u2596"
      '...x' -> "\u2597"
      'xx..' -> "\u2580"
      '..xx' -> "\u2585"
      'x.x.' -> "\u258C"
      '.x.x' -> "\u2590"
      '.xx.' -> "\u259E"
      'x..x' -> "\u259A"
      '.xxx' -> "\u259F"
      'x.xx' -> "\u2599"
      'xx.x' -> "\u259C"
      'xxx.' -> "\u259B"
      '....' -> "\u2591"
      'xxxx' -> "X"
    end
  end

  def unicode(%Board{pixels: p, rows: 1, cols: 2}) do
    case p do
      '..' -> "\u2591"
      'x.' -> "\u2598"
      '.x' -> "\u259D"
      'xx' -> "\u2580"
    end
  end

  def unicode(%Board{pixels: p, rows: 2, cols: 1}) do
    case p do
      '..' -> "\u2591"
      'x.' -> "\u2598"
      '.x' -> "\u2596"
      'xx' -> "\u258C"
    end
  end

  def unicode(%Board{pixels: p, rows: 1, cols: 1}) do
    case p do
      '.' -> "\u2591"
      'x' -> "\u2598"
    end
  end

  def unicode(%Board{rows: 1, cols: cols} = b) when cols > 2 do
    unicode(Board.area(b, 0, 0, 0, 1)) <> unicode(Board.area(b, 0, 2, 0, cols - 1))
  end

  def unicode(%Board{rows: 2, cols: cols} = b) when cols > 2 do
    unicode(Board.area(b, 0, 0, 1, 1)) <> unicode(Board.area(b, 0, 2, 1, cols - 1))
  end

  def unicode(%Board{rows: rows, cols: cols} = b) when rows > 2 and cols > 2 do
    unicode(Board.area(b, 0, 0, 1, cols - 1)) <> "\r\n" <> unicode(Board.area(b, 2, 0, rows - 1, cols - 1))
  end

  def make_grid(rows, cols) when rem(rows, 2) == 1 and rem(cols, 2) == 1 do
    %Board{rows: rows, cols: cols, pixels: list_x(div(rows,2), list_x(cols, ['x']) ++ list_x(div(cols,2), ['x','.']) ++ ['x']) ++ list_x(cols, ['x'])}
  end

end

