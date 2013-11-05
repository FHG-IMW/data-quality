module DataQuality

  module Model

    def self.included(base)
      base.send :extend, InitialClassMethods
    end


    module InitialClassMethods

      def has_quality_tests

        class_attribute :quality_tests
        class_attribute :execute_quality_tests

        self.execute_quality_tests = false

        self.quality_tests=[]

        send :extend, ExtendedClassMethods
        send :include, InstanceMethods



        yield if block_given?

        has_many :quality_test_states, :as => :testable, :class_name => 'DataQuality::QualityTestState'
        before_save -> { self.run_quality_tests if self.class.execute_quality_tests }

      end

      def has_quality_tests?
          self.quality_tests.any? if self.respond_to?(:quality_tests)
      end
    end



    module ExtendedClassMethods

      def quality_test(identifier,args={},&block)
        if block_given?
          self.quality_tests << DataQuality::QualityTest.new(identifier, args.merge(:block => block))
        else
          self.quality_tests << DataQuality::QualityTest.new(identifier, args)
        end
      end

      def max_achievable_quality_score
        self.quality_tests.count * 3
      end

    end




    module InstanceMethods

      def run_quality_tests(save=false)
        return nil unless self.class.quality_tests
        result = QualityTestResult.new

        self.class.quality_tests.each do |quality_test|
          new_result = quality_test.run_for(self)
          result.quality_tests << new_result if new_result
        end

        self.quality_score=calculate_quality_score(result)
        self.failed_tests=result.failed_tests.length

        self.save if save

        result
      end




      def calculate_quality_score(test_results)
        score=0
        test_results.quality_tests.each do |test|
          case test.state
            when :pass
              score += 3
            when :not_applicable
              score +=1
          end
        end
        score
      end

    end

  end

end
