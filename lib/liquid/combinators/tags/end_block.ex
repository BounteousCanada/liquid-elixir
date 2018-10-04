defmodule Liquid.Combinators.Tags.EndBlock do
  @moduledoc """
  Verifies when block is closed and send the AST to end the block
  """
  alias Liquid.Combinators.General

  import NimbleParsec

  def tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("end"))
    |> concat(General.valid_tag_name())
    |> tag(:tag_name)
    |> parsec(:end_tag)
    |> tag(:end_block)
  end
end