class Entrant
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: 'results'

  field :bib, type: Integer
  field :secs, type: Float
  field :o, as: :overall, type: Placing
  field :gender, type: Placing
  field :group, type: Placing

  embeds_many :results, class_name: 'LegResult',order: [:'event.o'.asc],
              after_add: :update_total, after_remove: :update_total
  embeds_one :race, class_name: 'RaceRef'
  embeds_one :racer, as: :parent, class_name: 'RacerInfo'

  def update_total(result)
    self.secs = results.inject(0){|sum,x| x.secs ? sum + x.secs : sum}
  end

  def the_race
    self.race.race if self.race
  end
end