class Event
  include Mongoid::Document
  field :o, as: :order, type: Integer
  field :n, as: :name, type: String
  field :d, as: :distance, type: Float
  field :u, as: :units, type: String

  embedded_in :parent, polymorphic: true, touch: true

  validates_presence_of :name, :order

  def miles
    case  self.units
    when 'meters'
      self.distance*0.000621371
    when 'kilometers'
      self.distance*0.621371
    when 'yards'
      self.distance*0.000568182
    when 'miles'
      self.distance
    else
      nil
    end
  end

  def meters
    dist_miles =  miles
    dist_miles * 1609.344 if dist_miles
  end
end
