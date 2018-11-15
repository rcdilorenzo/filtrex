defprotocol Filtrex.Encoders.Map do
  @doc "The function that performs enoding on value"
  @spec encode_map_value(any) :: String.t
  def encode_map_value(value)
end
