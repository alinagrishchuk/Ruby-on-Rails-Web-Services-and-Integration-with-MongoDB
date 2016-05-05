class AddressComponent
  attr_reader :long_name, :short_name, :types

  def initialize address
    @long_name = address[:long_name] || ''
    @short_name = address[:short_name] || ''
    @types = address[:types] || []
  end

end