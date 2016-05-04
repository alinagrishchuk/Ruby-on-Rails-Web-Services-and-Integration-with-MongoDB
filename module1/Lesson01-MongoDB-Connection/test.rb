require 'mongo'
require 'pp'
require_relative 'assignment'


s = Solution.new
pp s.sample
db = Solution.mongo_client
pp db[:zips].find.first