require './assignment.rb'

Solution.collection.insert_one({})

s=Solution.new
r=s.load_collection('./race_results.json')
pp r.inserted_count
pp r.inserted_ids.slice(0,2)