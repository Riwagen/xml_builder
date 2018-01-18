defmodule XmlBuilder.Format.Indented do
  def indentation(level, options) do
    IO.inspect option
    whitespace = Keyword.get(options, :whitespace, "")

    String.duplicate(whitespace, level)
  end

  def line_break(), do: "\n"
end
