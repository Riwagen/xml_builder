defmodule XmlBuilderTest do
  use ExUnit.Case
  doctest XmlBuilder

  import XmlBuilder, only: [doc: 1, doc: 2, doc: 3, doctype: 2]

  test "empty element" do
    assert doc(:person) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person/>|
  end

  test "document with DOCTYPE declaration and a system identifier" do
    assert doc([doctype("greeting", system: "hello.dtd"), {:greeting, "Hello, world!"}]) ==
            ~s|<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE greeting SYSTEM "hello.dtd">\n<greeting>Hello, world!</greeting>|
  end

  test "document with DOCTYPE declaration and a public identifier" do
    assert doc([doctype("html", public: ["-//W3C//DTD XHTML 1.0 Transitional//EN",
                "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"]), {:html, "Hello, world!"}]) ==
            ~s|<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html>Hello, world!</html>|
  end

  describe "#generate with options" do
    defp input,
      do: {:level1, nil, [{:level2, nil, "test_value"}]}

    test "when format = none, tab and nl formatting is not used" do
      expectation = "<level1><level2>test_value</level2></level1>"
      assert XmlBuilder.generate(input(), format: :none) == expectation
    end

    test "whitespace character option is used" do
      expectation = "<level1>\n\t<level2>test_value</level2>\n</level1>"
      assert XmlBuilder.generate(input(), whitespace: "\t") == expectation
    end
  end

  test "element with content" do
    assert doc(:person, "Josh") == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person>Josh</person>|
  end

  test "element with attributes" do
    assert doc(:person, %{occupation: "Developer", city: "Montreal"}) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person city="Montreal" occupation="Developer"/>|
    assert doc(:person, %{}) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person/>|
  end

  test "element with attributes and content" do
    assert doc(:person, %{occupation: "Developer", city: "Montreal"}, "Josh") == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person city="Montreal" occupation="Developer">Josh</person>|
    assert doc(:person, %{occupation: "Developer", city: "Montreal"}, nil) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person city="Montreal" occupation="Developer"/>|
    assert doc(:person, %{}, "Josh") == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person>Josh</person>|
    assert doc(:person, %{}, nil) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person/>|
  end

  test "element with ordered attributes" do
    assert doc(:person, [occupation: "Developer", city: "Montreal"], "Josh") == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person occupation="Developer" city="Montreal">Josh</person>|
    assert doc(:person, [occupation: "Developer", city: "Montreal"], nil) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person occupation="Developer" city="Montreal"/>|
    assert doc(:person, [occupation: "Developer", city: "Montreal"], nil) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person occupation="Developer" city="Montreal"/>|
    assert doc(:person, [], "Josh") == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person>Josh</person>|
    assert doc(:person, [], nil) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person/>|
  end

  test "element with children" do
    assert doc(:person, [{:name, %{id: 123}, "Josh"}]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person>\n  <name id="123">Josh</name>\n</person>|
    assert doc(:person, [{:first_name, "Josh"}, {:last_name, "Nussbaum"}]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person>\n  <first_name>Josh</first_name>\n  <last_name>Nussbaum</last_name>\n</person>|
  end

  test "element with attributes and children" do
    assert doc(:person, %{id: 123}, [{:name, "Josh"}]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person id="123">\n  <name>Josh</name>\n</person>|
    assert doc(:person, %{id: 123}, [{:first_name, "Josh"}, {:last_name, "Nussbaum"}]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person id="123">\n  <first_name>Josh</first_name>\n  <last_name>Nussbaum</last_name>\n</person>|
  end

  test "element with text content" do
    assert doc(:person, ["TextNode", {:name, %{id: 123}, "Josh"}, "TextNode"]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person>\n  TextNode\n  <name id="123">Josh</name>\n  TextNode\n</person>|
  end

  test "children elements" do
    assert doc([{:name, %{id: 123}, "Josh"}]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<name id="123">Josh</name>|
    assert doc([{:first_name, "Josh"}, {:last_name, "Nussbaum"}]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<first_name>Josh</first_name>\n<last_name>Nussbaum</last_name>|
  end

  test "quoting and escaping attributes" do
    assert element(:person, %{height: 12}) == ~s|<person height="12"/>|
    assert element(:person, %{height: ~s|10'|}) == ~s|<person height="10'"/>|
    assert element(:person, %{height: ~s|10"|}) == ~s|<person height='10"'/>|
    assert element(:person, %{height: ~s|<10'5"|}) == ~s|<person height="&lt;10'5&quot;"/>|
  end

  test "escaping content" do
    assert element(:person, "Josh") == "<person>Josh</person>"
    assert element(:person, "<Josh>") == "<person>&lt;Josh&gt;</person>"
    assert element(:data, "1 <> 2 & 2 <> 3") == "<data>1 &lt;&gt; 2 &amp; 2 &lt;&gt; 3</data>"
  end

  test "wrap content inside cdata and skip escaping" do
    assert element(:person, {:cdata, "john & <is ok>"}) == "<person><![CDATA[john & <is ok>]]></person>"
  end

  test "multi level indentation" do
    assert doc([person: [first: "Josh", last: "Nussbaum"]]) == ~s|<?xml version="1.0" encoding="UTF-8"?>\n<person>\n  <first>Josh</first>\n  <last>Nussbaum</last>\n</person>|
  end

  def element(name, arg),
    do: XmlBuilder.element(name, arg) |> XmlBuilder.generate

  def element(name, attrs, content),
    do: XmlBuilder.element(name, attrs, content) |> XmlBuilder.generate
end
