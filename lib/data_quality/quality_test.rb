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


    def run_for(company)
      if if_condition.instance_of?(Proc)
        return nil unless if_condition.call(company)
      end

      if block
        test_block(company)
      else

        if method_name and attr

          return eval("#{method_name.to_s}(company)")
        else
          raise "Arguments Missing: :method_name and :attr is needed"
        end
      end
    end

    private

    def not_empty(company)
      raise NoMethodError.new("No method '#{attr}' for #{company.to_s}", company.to_s) unless company.class.instance_method_names.include?(attr.to_s)

      desc = description
      desc ||=  "\"#{company.class.human_attribute_name(attr)}\" should have a value"


      if element=company.read_attribute(attr)
        if element.instance_of?(String)
          return create_result(company,:fail,"No Value available",desc) if element.blank?
        end

        return create_result(company, :pass, "Value available", desc)
      elsif company.class.instance_methods.include?(attr)
        return create_result(company, :pass, "Value available", desc) if !company.send(attr).blank?
      end


      create_result(company,:fail,"No Value available",desc)
    end


    def each_not_empty(company)
      raise NoMethodError.new("No method '#{function}' for #{company.to_s}", company.to_s) unless company.class.instance_method_names.include?(function.to_s)

      desc = description || "\"#{company.class.human_attribute_name(attr)}\" in all #{function.to_s.humanize} should have a value"

      objects=[]
      if function
        objects=company.send(function)
      end

      if objects.length > 0

        failed=[]
        objects.each do |object|
          raise NoMethodError.new("No method '#{attr}' for #{object.to_s}", object.to_s) unless object.class.instance_method_names.include?(attr.to_s)

          failed << object if object.read_attribute(attr).blank?
        end

        if failed.empty?
          return create_result(company,:pass,"All Values available",desc)
        else
          return create_result(company,:fail, "#{failed.length} Values not available", desc, failed)
        end

      end

      create_result(company, :fail, "No Objects available", desc)
    end


    def not_expired(company)
      bound = since ? since : 1.year.ago

      desc= description ? description : "#{company.class.human_attribute_name(attr)} should not be expired"


      if company.read_attribute(attr)
        return create_result(company, :pass, "Date not expired", desc) if company.read_attribute(attr) > bound
        return create_result(company, :fail, "Date expired", desc)
      end
      create_result(company, :fail, "No Value available", desc)
    end


    def test_block(company)
      desc = description ? description : "Given Block should return true"

      if block.call(company)
        create_result(company,:pass,"Returned True",desc)
      else
        create_result(company,:fail,"Returned False",desc)
      end
    end


    def create_result(company,state,message,description,failed=[])

      result=self.dup

      if test=company.quality_test_states.find_by_identifier(identifier)
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