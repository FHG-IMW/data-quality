module DataQuality
  class QualityTest

    attr_reader :identifier, :if_condition, :block, :method_name, :attr, :since, :function
    attr_accessor :state, :message, :description, :failed_objects

    def initialize(identifier,args={})
      @identifier=identifier
      @description=args[:description] || nil

      @method_name = args[:method_name] || nil
      @attr = args[:attr] || nil

      @state= args[:state] || :undefined
      @message=args[:message] || nil

      @if_condition = args[:if] || nil

      @function = args[:function] || nil
      @failed_objects = args[:failed_objects] || []

      @since = args[:since] || nil

      @block = args[:block] || nil
    end


    def run_for(object)
      if if_condition.instance_of?(Proc)
        return nil unless if_condition.call(object)
      end

      if block
        test_block(object)
      else

        if method_name and attr

          return self.send(method_name,object)
        else
          raise "Arguments Missing: :method_name and :attr is needed"
        end
      end
    end

    def set_not_applicable_for object
      if object.class.has_quality_tests?
        object.quality_test_states.find_or_create_by(:identifier => identifier, :not_applicable => true) # if object.class.quality_tests.include?(self)
      else
        raise StandardError.new("Object does not include quality tests!")
      end
    end

    private

    def not_empty(object)
      raise NoMethodError.new("No method '#{attr}' for #{object.to_s}", object.to_s) unless object.class.instance_methods.include?(attr)

      desc = description
      desc ||=  "\"#{object.class.human_attribute_name(attr)}\" should have a value"


      if element=object.read_attribute(attr)
        if element.instance_of?(String)
          return create_result(object,:fail,"No Value available",desc) if element.blank?
        end

        return create_result(object, :pass, "Value available", desc)
      elsif object.class.instance_methods.include?(attr)
        return create_result(object, :pass, "Value available", desc) if !object.send(attr).blank?
      end


      create_result(object,:fail,"No Value available",desc)
    end


    def each_not_empty(object)
      raise NoMethodError.new("No method '#{function}' for #{object.to_s}", object.to_s) unless object.class.instance_methods.include?(function)

      desc = description || "\"#{object.class.human_attribute_name(attr)}\" in all #{function.to_s.humanize} should have a value"

      objects=function ? object.send(function) : []
      
      return create_result(object, :fail, "No Objects available", desc) if objects.size == 0
      
      failed=[]
      objects.each do |one_of_many|
        raise NoMethodError.new("No method '#{attr}' for #{one_of_many.to_s}", one_of_many.to_s) unless one_of_many.class.instance_methods.include?(attr)
        failed << one_of_many if one_of_many.read_attribute(attr).blank?
      end
      
      return create_result(object,:pass,"All Values available",desc) if failed.empty?
      create_result(object,:fail, "#{failed.length} Values not available", desc, failed)

    end



    def not_expired(object)
      bound = since ? since : 1.year.ago

      desc= description ? description : "#{object.class.human_attribute_name(attr)} should not be expired"


      if object.read_attribute(attr)
        return create_result(object, :pass, "Date not expired", desc) if object.read_attribute(attr) > bound
        return create_result(object, :fail, "Date expired", desc)
      end
      create_result(object, :fail, "No Value available", desc)
    end


    def test_block(object)
      desc = description ? description : "Given Block should return true"

      if block.call(object)
        create_result(object,:pass,"Returned True",desc)
      else
        create_result(object,:fail,"Returned False",desc)
      end
    end


    def create_result(object,state,message,description,failed=[])

      result=self.dup

      if test=object.quality_test_states.find_by_identifier(identifier)
        if test.not_applicable

          if state == :pass
            test.not_applicable= false
            test.save

          else
            state = :not_applicable
          end
        end
      end

      result.state=state
      result.message=message
      result.description=description
      result.failed_objects=failed
      result

    end

  end
end