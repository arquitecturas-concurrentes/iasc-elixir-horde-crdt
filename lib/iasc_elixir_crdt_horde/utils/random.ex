defmodule IASC.Random do
  def random_string(n) do
    for _ <- 1..n, into: "", do: <<Enum.random('0123456789abcdef')>>
  end

  def current_node do
    get_node_name(Node.self())
  end

  def get_node_name(node) do
    node_name_splitted = String.split(Atom.to_string(node), "@")
    List.first(node_name_splitted)
  end

  def cluster_nodes do
    Enum.map([Node.self() | Node.list()], fn node -> IASC.Random.get_node_name(node) end )
  end
end