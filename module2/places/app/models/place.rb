class Place
  attr_accessor :id, :formatted_address, :location, :address_components

  PLACE_COLLECTION = 'places'

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    Place.mongo_client[PLACE_COLLECTION]
  end

  def self.load_all f
    if f
      Place.collection.delete_many
      jsCollection = JSON.parse f.read
      Place.collection.insert_many jsCollection
     end
  end

  def initialize place
    @id = place[:_id].to_s
    @formatted_address = place[:formatted_address]
    @location = Point.new place[:geometry][:geolocation]

    @address_components = []
    place[:address_components].each do |address_component|
      @address_components << (AddressComponent.new address_component)
    end
  end

  def self.find_by_short_name short_name
    Place.collection.find(:"address_components.short_name" => short_name)
  end


#accept a Mongo::Collection::View and return a collection of Place instances.
  def self.to_places (values)
    places = []
    values.each do |place|
      places << (Place.new place)
    end
    places
  end

  def self.find id
    _id = BSON::ObjectId.from_string(id)
    place = Place.collection.find(:_id => _id).first
    Place.new place unless place.nil?
  end

  def self.all (offset=0, limit=nil)
    result = Place.collection.find.skip(offset)
    result = result.limit(limit) unless limit.nil?
    Place.to_places(result)
  end

  def destroy
    id =  BSON::ObjectId.from_string(@id)
    Place.collection.find(_id: id).delete_one
  end

end




