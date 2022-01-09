defmodule WebSubHub.Updates.Headers do
  @behaviour Ecto.Type
  def type, do: :binary

  # Provide our own casting rules.
  def cast(term) do
    {:ok, term}
  end

  def embed_as(_format) do
    :self
  end

  def equal?(a, b) do
    a == b
  end

  # When loading data from the database, we are guaranteed to
  # receive an integer (as databases are strict) and we will
  # just return it to be stored in the schema struct.
  def load(binary), do: {:ok, :erlang.binary_to_term(binary)}

  # When dumping data to the database, we *expect* an integer
  # but any value could be inserted into the struct, so we need
  # guard against them.
  def dump(term), do: {:ok, :erlang.term_to_binary(term)}
end
