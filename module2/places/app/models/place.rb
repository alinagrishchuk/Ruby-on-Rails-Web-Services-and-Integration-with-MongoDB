class Place
  PLACE_COLLECTION = 'places'

  attr_accessor :id, :formatted_address, :location, :address_components

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    Place.mongo_client[PLACE_COLLECTION]
  end

  def self.load_all(f)
    if f
      Place.collection.delete_many
      js_collection = JSON.parse( f.read )
      Place.collection.insert_many js_collection
     end
  end

  def self.create_indexes
    Place.collection.indexes.create_one(:'geometry.geolocation' => '2dsphere')
  end

  def self.remove_indexes
    Place.collection.indexes.drop_one('geometry.geolocation_2dsphere')
  end

  def self.find_by_short_name(short_name)
    Place.collection.find(:'address_components.short_name' => short_name)
  end

  #accept a Mongo::Collection::View and return a collection of Place instances.
  def self.to_places(values)
    places = []
    values.each do |place|
      places << ( Place.new(place) )
    end
    return places
  end

  def self.find(id)
    _id = BSON::ObjectId.from_string(id)
    place = Place.collection.find(:_id => _id).first
    Place.new(place) unless place.nil?
  end

  def self.all(offset = 0, limit = nil)
    result = Place.collection.find.skip(offset)
    result = result.limit(limit) unless limit.nil?
    Place.to_places(result)
  end

  def self.get_address_components(sort = {}, offset = 0, limit = nil)
    pipe =
      [{:$unwind => '$address_components'},
       {:$project =>
         {:address_components => 1,
          :formatted_address => 1,
          :'geometry.geolocation' => 1}}]

    pipe << {:$sort => sort} unless sort.length == 0
    pipe << {:$skip => offset} unless offset == 0
    pipe << {:$limit => limit} unless limit.nil?

    Place.collection.aggregate(pipe)
  end

  def self.get_country_names
    Place.collection.aggregate([
      {:$unwind => '$address_components'},
      {:$unwind => '$address_components.types'},
      {:$project => {address_components: {long_name: 1, types: 1}}},
      {:$match => {:"address_components.types" => 'country'}},
      {:$group => {:_id => "$address_components.long_name"}}
    ]).to_a.map {|h| h[:_id]}
  end

  def self.find_ids_by_country_code(country_code)
    Place.collection.
      find.aggregate([
        {:$match => {:'address_components.short_name' => country_code}},
        {:$project=> {:_id => 1}}
      ]).to_a.map {|h| h[:_id].to_s}
  end

  def self.near(point, max_meters = nil)
    pipe = {:$near => point.to_hash}
    pipe[:$maxDistance] = max_meters unless max_meters.nil?
    Place.collection.find('geometry.geolocation': pipe)

  end

  def initialize(place)
    @id = place[:_id].to_s
    @formatted_address = place[:formatted_address]
    @location = Point.new(place[:geometry][:geolocation])

    @address_components = []
    place[:address_components].each do |address_component|
      @address_components << (AddressComponent.new address_component)
    end unless  place[:address_components].nil?
  end

  def destroy
    id =  BSON::ObjectId.from_string(@id)
    Place.collection.find(_id: id).delete_one
  end

  def near(maximum_distance = nil)
    Place.to_places(
      Place.near(@location.to_hash,maximum_distance)
    )
  end


end




