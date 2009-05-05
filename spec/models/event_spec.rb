require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Event do
  before(:each) do
    @valid_attributes = {
      :title => "value for title",
      :from => 10.years.ago,
      :from_granularity => 1.hour,
      :duration => 1.hour,
      :to_granularity => 10.minutes
    }
  end

  it "should create a new instance given valid attributes" do
    Event.create!(@valid_attributes)
  end
  
  it { should allow_mass_assignment_of(:title) }
  it { should allow_mass_assignment_of(:from) };
  # it { should allow_mass_assignment_of(:from_granularity) }
  it { should allow_mass_assignment_of(:to) }
  # it { should allow_mass_assignment_of(:to_granularity) }
  it { should allow_mass_assignment_of(:duration) }
  
  
  describe "datetime calculations" do
    before do
      @event = Event.create!(@valid_attributes)
    end
  
  
    [:from, :to].each do |time|
      
      describe "#min_#{time}" do
        it "should be to minus half to_granularity" do
          @event.send("#{time}=", 10.years.ago)
          @event.send("#{time}_granularity=", 1.year)
          @event.send("min_#{time}").should.eql? 10.years.ago - (1.years / 2)
        end
      end
    
      describe "#max_#{time}" do
        it "should be to minus half to_granularity" do
          @event.send("#{time}=", 10.years.ago)
          @event.send("#{time}_granularity=", 1.year)
          @event.send("max_#{time}").should.eql? 10.years.ago + (1.years / 2)
        end
      end
      
    end
    
    describe "#range" do
      it "should return from .. to" do
        range = @event.range
        range.first.should.eql? @event.from
        range.last.should.eql? @event.to
      end
    end
    
    describe "#max_range" do
      it "should return min_from .. max_to" do
        range = @event.max_range
        range.first.should.eql? @event.min_from
        range.last.should.eql? @event.max_to
      end
    end
    
    describe "#range" do
      it "should return max_from .. max_to" do
        range = @event.range
        range.first.should.eql? @event.max_from
        range.last.should.eql? @event.min_to
      end
    end
    
    describe "#duration" do
      it "should return to - from" do
        @event.duration.should.eql? @event.to - @event.from
      end
    end
    
    describe "#duration=" do
      it "should return modify Event#to" do
        @event.from = 12.hours.ago
        @event.duration = 1.hour
        @event.to.should.eql? 11.hours.ago
      end      
    end
  
  end
  
  it "should not allow times in the future to be save" do
    event = Event.new(@valid_attributes)
    event.from = 1.hour.ago
    event.from_granularity = 1
    event.to = 30.minutes.from_now
    event.to_granularity = 1.hour
    event.save
    event.errors.on(:max_to).should include("Event times cannot be in the future")
    event.should have(:no).errors_on(:min_to)
    
    
    event.from = 1.year.from_now
    event.to = 12.years.from_now
    event.save
    event.should have(1).error_on(:max_from)
    event.should have(1).error_on(:min_from)
    event.should have(1).error_on(:max_to)
    event.should have(1).error_on(:min_to)
  end
  
  describe "#attributes=" do
    before(:each) do
      @event = Event.new(@valid_attributes)
    end
    
    it "should ignore to when from and duration are both given" do
      @event.attributes = {
        :to => 1.year.ago,
        :from => 12.years.ago,
        :duration => 1.year,
      }
      @event.from.should.eql? 2.years.ago
    end
  
    it "should treat duration as reverse duration when to is given and from isn't" do
      @event.attributes = {
        :to => 1.month.ago,
        :duration => 1.month,
      }
      @event.from.should.eql? 2.months.ago
    end
  
  end
  
end
