require 'test/unit'
require 'test_helper'
require 'data_quality'

class TestDataQuality < Test::Unit::TestCase
  def test_companies_should_have_6_quality_tests
    assert_equal 6,Company.quality_tests.length
  end

  def test_company_should_respond_to_methods
    assert Company.quality_tests
    assert Company.first.run_quality_tests(false)
    assert Company.first.quality_test_states
  end

  def test_run_quality_tests
    company = Company.find_by_name("FullFeatured")
    test_result = company.run_quality_tests

    assert_equal 6, test_result.passed_tests.length
    assert_equal 0, test_result.failed_tests.length
    assert_equal 0, test_result.inapplicable_tests.length

    assert_equal 18, test_result.quality_score




    company = Company.last
    test_result = company.run_quality_tests

    assert_equal 3, test_result.passed_tests.length
    assert_equal "02", test_result.passed_tests.first.identifier  # The second test should pass

    assert_equal 2, test_result.failed_tests.length

    assert_equal 1, test_result.inapplicable_tests.length
    assert_equal "01", test_result.inapplicable_tests.first.identifier  # The second test should pass

    assert_equal 10, test_result.quality_score

  end

  def test_set_not_applicable
    company = Company.first
    test=Company.quality_tests.first

    test.set_not_applicable_for company

    state=company.quality_test_states.find_by_identifier(test.identifier)

    assert_equal true, state.not_applicable
  end
end