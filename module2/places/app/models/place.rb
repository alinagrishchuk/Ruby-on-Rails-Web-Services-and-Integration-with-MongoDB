require 'point'
class Place

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

end


