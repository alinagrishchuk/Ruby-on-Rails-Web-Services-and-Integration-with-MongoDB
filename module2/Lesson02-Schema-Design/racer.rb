require 'mongo'
require 'json'
require 'pp'
Mongo::Logger.logger.level = ::Logger::INFO
#Mongo::Logger.logger.level = ::Logger::DEBUG

class Racer
  MONGO_URL='mongodb://localhost:27017'
  MONGO_DATABASE='test'
  RACE_COLLECTION='race2'
  RACER_COLLECTION='racer2'

  # helper function to obtain connection to server and set connection to use specific DB
  # set environment variables MONGO_URL and MONGO_DATABASE to alternate values if not
  # using the default.
  def self.mongo_client
    url=ENV['MONGO_URL'] ||= MONGO_URL
    database=ENV['MONGO_DATABASE'] ||= MONGO_DATABASE 
    db = Mongo::Client.new(url)
    @@db=db.use(database)
  end

  # helper method to obtain collection used to make race results. set environment
  # variable RACE_COLLECTION to alternate value if not using the default.
  def self.collection
    collection=ENV['RACE_COLLECTION'] ||= RACE_COLLECTION
    return mongo_client[collection]
  end
  def self.races_collection
    collection
  end
  def self.racers_collection
    collection=ENV['RACER_COLLECTION'] ||= RACER_COLLECTION
    return mongo_client[collection]
  end
  
  # helper method that will load a file and return a parsed JSON document as a hash
  def self.load_hash(file_path) 
    file=File.read(file_path)
    JSON.parse(file)
  end

  # drop the current contents of the collection and reload from data file
  def self.reset(file_path=nil) 
    dir_name = File.dirname(File.expand_path(__FILE__))
    file_path ||= "#{dir_name}/race2_results.json"
    if !File.exists?(file_path)
      puts "cannot find bootstrap at #{file_path}"
      return 0
    else
      collection.delete_many({})
      racers_collection.delete_many({})
      hash=load_hash(file_path)
      r=collection.insert_many(hash)
      return r.inserted_count
    end
  end
end

#Racer.reset
#Racer.reset ./student-start/race2_results.json"

Racer.reset
racer = Racer.collection

#Consistent Field Types
racer.find(number: {:$type => 2}).each do |r|
  racer.update_one({:_id => r[:_id]},
                   {:$set => {:number => r[:number].to_i}})
end

Racer.reset
racer = Racer.collection

#Consistent Fields Supplied
Racer.collection.find(gender: $nil).
    update_many(:$set=>{:gender=>"F"})

Racer.reset
racers = Racer.collection

#Normalized Fields
racers.find(:name=>{:$exists=>true}).each do |r|
  matches = /(\w+) (\w+)/.match r[:name]
  first_name = matches[1]
  last_name = matches[2]
  racers.update_one({:_id=>r[:_id]},
                    {:$set=>{:first_name=>first_name, :last_name=>last_name},
                     :$unset=>{:name=>""}})
end

Racer.reset
racers = Racer.racers_collection
races = Racer.races_collection

#Creating a Linked Relationship
races.find(:name=>{:$exists=>true}).each do |r|
  result = racers.update_one({:name=>r[:name]}, {:name=>r[:name]}, {:upsert=>true})
  id = result.upserted_id
  races.update_one({:_id=>r[:_id]},{:$set=>{:racer_id=>id},:$unset=>{:name=>""}})
end

Racer.reset
racers = Racer.racers_collection
races = Racer.races_collection

#Creating an Embedded Relationship
races.find(:name=>{:$exists=>true}).each do |r|
  result = racers.update_one( { :name => r[:name]} ,
                           { :name=>r[:name],
                             :races=>[
                                { :_id=>r[:_id],
                                  :number => r[:number],
                                  :group => r[:group],
                                  :time => r[:time] }
                            ]},   { :upsert => true} )
  races.find(:_id=>r[:_id]).delete_one
end