class Racer
  include Mongoid::Document

  field :fn, as: :first_name, type: String
  field :ln, as: :last_name, type: String
  field :dob, as: :date_of_birth, type: Date

  embeds_one :primary_address,  class_name: 'Address', as: :addressable

  def races
    Contest
      .where('entrants.racer_id': BSON::ObjectId.from_string(self.id))
      .map{ |contest| contest.entrants.where(racer_id: self.id).first }
  end

end
