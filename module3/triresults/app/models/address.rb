class Address
  attr_accessor :city, :state, :location
  def initialize(city, state, location)
    @city = city
    @state = state
    @location = location
  end

  def mongoize
    { city: "#{@city}",
      state: "#{@state}",
      loc: (@location.mongoize) }
  end

  def self.mongoize(object)
    object.instance_of?(Address) ? object.mongoize : object
  end

  def self.demongoize(object)
    if object.kind_of? (Hash)
      Address.new( object[:city],
                   object[:state],
                   Point.demongoize(object[:loc]) )
    end
  end

  def self.evolve(object)
    Address.mongoize object
  end
end