class Point
  attr_accessor :longitude, :latitude

  def initialize (lon, lat)
    @longitude = lon
    @latitude = lat
  end

  def mongoize
    { type: 'Point',
      coordinates: [@longitude, @latitude] }
  end

  def self.demongoize object
    if object.instance_of?(Hash) && object[:type] == "Point"
      Point.new(object[:coordinates][0],
                object[:coordinates][1])
    end
  end

  def self.mongoize object
    if object.instance_of?(Hash)
      object = Point.demongoize(object)
    end
    object.mongoize if object.instance_of?(Point)
  end

  def self.evolve object
    Point.mongoize object
  end

end

