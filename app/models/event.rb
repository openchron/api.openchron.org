class Event < ActiveRecord::Base

  attr_accessible :title, :from, :from_granularit, :to, :to_granularity, :duration, :from_range, :to_range
  
  validates_presence_of :title, :from, :to
  validate :granularity_does_not_exceed_duration
  validate :dates_are_not_in_the_future

  [:from, :to].each do |time|
    
    define_method "min_#{time}" do
      send(time) - (send("#{time}_granularity") / 2)
    end
    
    define_method "max_#{time}" do
      send(time) + (send("#{time}_granularity") / 2)
    end
    
    define_method "#{time}_range" do
      send("min_#{time}") .. send("max_#{time}")
    end
    
  end
  
  def from
    read_attribute(:from) ? read_attribute(:from) : write_attribute(:from,Time.now.utc)
  end
  
  def from=(new_from)
    write_attribute(:from, new_from.utc)  if new_from.is_a? Time
  end
  
  def to
    from + duration
  end
  
  def to=(new_to)
    write_attribute(:duration, (new_to.utc - from))  if new_to.is_a? Time
  end

  def range
    from .. to
  end

  def min_range
    max_from .. min_to
  end
  
  def max_range
    min_from .. max_to
  end

  # def duration=(new_duration)
  # end
  
  def has_duration?
    !duration.zero?
  end
  
  def duration
    read_attribute(:duration)
  end
  alias_method :length, :duration

  def min_duration
    min_to - max_from
  end
  
  def max_duration
    max_to - min_from
  end
  
  
  def attributes=(params)
    params = params.with_indifferent_access
    logger.debug params.inspect

    if params[:from].present? and params[:duration].present? and params[:to].present?
      params.delete(:to)
    end

    if params[:to].present? and params[:duration].present? and !params[:from].present?    
      params[:from] = params.delete(:to) - params[:duration]
    end

    logger.debug params.inspect

    super(params) # Mass Assigment
  end
  
  private
  
  def dates_are_not_in_the_future
    [:max_to, :min_to, :max_from, :min_from].each do |time|
      errors.add(time, 'Event times cannot be in the future') if send(time) > Time.now.utc
    end
  end
  
  # This method ensures that you cannot create a from or two datetime with a
  # granularity that exceeds the duration of the entire event (not encluding granularity)
  def granularity_does_not_exceed_duration
    
  end
  
end
