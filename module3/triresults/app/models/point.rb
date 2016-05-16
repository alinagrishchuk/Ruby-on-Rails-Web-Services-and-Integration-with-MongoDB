class Point
  attr_accessor :longitude, :latitude

  def initialize(lon, lat)
    @longitude = lon
    @latitude = lat
  end

  def mongoize
    { type: 'Point',
      coordinates: [@longitude, @latitude] }
  end

  def self.mongoize(object)
    object.instance_of?(Point) ? object.mongoize : object
  end

  def self.demongoize(object)
    if object.kind_of?(Hash) && object[:type] == "Point"
      Point.new(object[:coordinates][0],
                object[:coordinates][1])
    end
  end

  def self.evolve(object)
    Point.mongoize object
  end

end