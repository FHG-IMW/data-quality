module DataQuality
  class QualityTestResult
    attr_accessor :quality_tests

    def initialize
      @quality_tests=[]
    end

    def failed_tests
      @quality_tests.select {|test| test.state==:fail}
    end

    def passed_tests
      @quality_tests.select {|test| test.state==:pass}
    end

    def inapplicable_tests
      @quality_tests.select {|test| test.state==:not_applicable}
    end

    def quality_score
      passed_tests.count * 3 + inapplicable_tests.count
    end
  end
end