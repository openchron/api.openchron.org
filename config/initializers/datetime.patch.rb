# This Patch fixes the following rails bugs
#  http://dev.rubyonrails.org/ticket/8983
# and
#  http://dev.rubyonrails.org/ticket/10352
class ActiveRecord::Base
  def execute_callstack_for_multiparameter_attributes(callstack)
    errors = []
    callstack.each do |name, values|
      klass = (self.class.reflect_on_aggregation(name.to_sym) || column_for_attribute(name)).klass rescue Time
      if values.empty?
        send(name + "=", nil)
      else
        begin
          value = if Time == klass
            instantiate_time_object(name, values)
          elsif Date == klass
            begin
              Date.new(*values)
            rescue ArgumentError => ex # if Date.new raises an exception on an invalid date
              instantiate_time_object(name, values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
            end
          else
            klass.new(*values)
          end

          send(name + "=", value)
        rescue => ex
          errors << AttributeAssignmentError.new("error on assignment #{values.inspect} to #{name}", ex, name)
        end
      end
    end
    unless errors.empty?
      raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
    end
  end
end