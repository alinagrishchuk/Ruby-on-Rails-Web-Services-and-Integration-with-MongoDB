class Entrant
  include Mongoid::Document

  field :_id, type: Integer
  field :name, type: String
  field :group, type: String
  field :secs, type: Float

  belongs_to :racer, validate: true
  embedded_in :contest

  before_create do
    if self.racer
      self.name = "#{self.racer[:last_name]}, #{self.racer[:first_name]}"
    end
  end



end
