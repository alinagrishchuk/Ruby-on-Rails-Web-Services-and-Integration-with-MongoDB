class Placing
  attr_accessor :name, :place
  def initialize (name, place)
    @name = name
    @place = place
  end

  def mongoize
    { name: "#{@name}",
      place: @place }
  end

  def self.mongoize object
    object.instance_of?(Placing) ? object.mongoize : object
  end

  def self.demongoize object
    if object.instance_of?(Hash)
      Placing.new( object[:name],
                   object[:place] )
    end
  end

  def self.evolve object
    Placing.mongoize object
  end
end

