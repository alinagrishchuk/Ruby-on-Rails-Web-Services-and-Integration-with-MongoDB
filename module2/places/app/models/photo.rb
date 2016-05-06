class Photo
  attr_accessor :id, :location
  attr_writer :contents

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.find id
    _id =  BSON::ObjectId.from_string(id)
    photo = Photo.mongo_client.database.fs.find(:_id => _id).first

    Photo.new(photo)  unless photo.nil?
  end

  def self.all(offset = 0, limit = nil)
    result = Photo.mongo_client.database.fs.find.skip(offset)
    result = result.limit(limit) unless limit.nil?
    result.map{ |p| Photo.new(p)}
  end

  def initialize(photo = nil)
      if (photo)
        @id = photo[:_id].to_s unless photo[:_id].nil?
        @location =
        Point.new(photo[:metadata][:location]) if (photo[:metadata] && photo[:metadata][:location])
      end
  end

  def persisted?
    !@id.nil?
  end

  def contents
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

      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description )
      id = self.class.mongo_client.database.fs.insert_one(grid_file)
      @id = id.to_s
    end
    @id
  end

  def _id
    BSON::ObjectId.from_string(@id) unless @id.nil?
  end

end