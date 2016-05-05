class Point
  attr_accessor :longitude, :latitude

  def initialize ( point = {} )
    if point[:type] == 'Point'              #GeoJSON Point format
      @longitude = point[:coordinates][0]
      @latitude = point[:coordinates][1]
    else                                    #hash with keys lat and lng
      @longitude, @latitude = point.values_at(:lng, :lat)
    end
  end

  def to_hash #GeoJSON Point
    geoJS = {}
    geoJS[:type] = 'Point'
    geoJS[:coordinates] = [@longitude,@latitude]
    geoJS
  end
end
