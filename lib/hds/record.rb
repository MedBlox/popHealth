class Record
  include Mongoid::Document
  
  # ===========================================================
  # = This record extends the record in health data standards =
  # ===========================================================
  
  field :measures, type: Hash

  [:allergies, :care_goals, :conditions, :encounters, :immunizations, :medical_equipment,
   :medications, :procedures, :results, :social_history, :vital_signs].each do |section|
    embeds_many section, as: :entry_list, class_name: "Entry"
  end
  
  
  
  scope :alphabetical, order_by([:last, :asc], [:first, :asc])
  scope :with_provider, where(:provider_performances.ne => nil).or(:provider_proformances.ne => [])
  scope :without_provider, any_of({provider_performances: nil}, {provider_performances: []})
  scope :provider_performance_between, ->(effective_date) { where("provider_performances.start_date" => {"$lt" => effective_date}).and('$or' => [{'provider_performances.end_date' => nil}, 'provider_performances.end_date' => {'$gt' => effective_date}]) }
  
  def self.update_or_create(data)
    existing = Record.by_patient_id(data.medical_record_number).first
    if existing
      existing.update_attributes!(data.attributes.except('_id'))
      existing
    else
      data.save!
      data
    end
  end
  
  def language_names
    values = []
    unless (self['languages'].nil?)
      lang_codes = self['languages'].map { |l| l.gsub(/\-[A-Z]*$/, "") }
      values = Language.ordered.by_code(lang_codes).map(&:name)
    end
    values
  end
  
  private 
  
  def self.provider_queries(provider_id, effective_date)
   {'$or' => [provider_query(provider_id, effective_date,effective_date), provider_query(provider_id, nil,effective_date), provider_query(provider_id, effective_date,nil)]}
  end
  def self.provider_query(provider_id, start_before, end_after)
    {'provider_performances' => {'$elemMatch' => {'provider_id' => provider_id, 'start_date'=> {'$lt'=>start_before}, 'end_date'=> {'$gt'=>end_after} } }}
  end
  
end
