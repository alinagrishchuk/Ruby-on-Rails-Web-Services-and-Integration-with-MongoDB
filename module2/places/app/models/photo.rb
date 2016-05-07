class Photo
  attr_accessor :id, :location
  attr_writer :contents

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.find(id)
    if id
      _id =  BSON::ObjectId.from_string(id)
      photo = Photo.mongo_client.database.fs.find(:_id => _id).first
      Photo.new(photo)  unless photo.nil?
    end

  end

  def self.all(offset = 0, limit = nil)
    result = Photo.mongo_client.database.fs.find.skip(offset)
    result = result.limit(limit) unless limit.nil?
    result.map{ |p| Photo.new(p)}
  end

  def self.find_photos_for_place pl_id
    _pl_id = BSON::ObjectId.from_string(pl_id)
    Photo.mongo_client.database.fs.find(:'metadata.place' =>  _pl_id)
  end

  def initialize(photo = nil)
      if (photo)
        @id = photo[:_id].to_s unless photo[:_id].nil?
        @location =
        Point.new(photo[:metadata][:location]) if (photo[:metadata] && photo[:metadata][:location])
        @place = photo[:metadata][:place] if (photo[:metadata] && photo[:metadata][:place])
      end
  end

  def persisted?
    !@id.nil?
  end

  def contents
    _id = BSON::ObjectId.from_string(@id) unless @id.nil? || @id.empty?
    file = Photo.mongo_client.database.fs.find_one(:_id => _id)

    if file
      buffer = ""
      file.chunks.reduce([]) do |x,chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  def destroy
    _id = BSON::ObjectId.from_string(@id) unless @id.nil? || @id.empty?
    Photo.mongo_client.database.fs.find({:_id => _id }).delete_one
  end

  def save
    if !persisted? && @contents && EXIFR::JPEG.new(@contents).exif?
      @contents.rewind

      gps = EXIFR::JPEG.new(@contents).gps
      @location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)

      description = {}
      description[:content_type] = 'image/jpeg'
      description[:metadata] = {}
      description[:metadata][:location] = @location.to_hash
      description[:metadata][:place] =  @place unless @place.nil?

      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description )
      id = self.class.mongo_client.database.fs.insert_one(grid_file)
      @id = id.to_s
    else
      _id = BSON::ObjectId.from_string(@id)
      md = {:location => @location.to_hash}
      md[:place] = @place unless @place.nil?
      Photo.mongo_client.database.fs.find(:_id => _id)
        .update_one( :metadata => md)
    end
    @id
  end

  def find_nearest_place_id(max_meters)
    place = Place.near(@location, max_meters)
            .limit(1)
            .projection(:_id => 1).first
    place[:_id] unless place.nil?

  end


  def place
    Place.find(@place.to_s) unless @place.nil?
  end

  def place=(object) #accepting a BSON::ObjectId, String, or Place instance.
    if object.respond_to? :id
      @place = BSON::ObjectId.from_string(object.id)
    else
      @place = BSON::ObjectId.from_string(object)
    end

  end


end