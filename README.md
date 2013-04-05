# DataQuality

This is a gem that makes your models data quality testable.
You can define quality tests that specify the desired data quality.


## Installation

Add this line to your application's Gemfile:

    gem 'data_quality'

Execute:

    $ bundle

And then run:

    rails g data_quality:data_quality :MyModel

This generator will generate the migrations that setup the table required for DataQuality and add the fields `failed_tests` and `quality_score` to MyModel
This field must be added to every model that will use DataQuality tests.

Finally run:

    rake db:migrate

## Configuration

To add DataQuality tests to your models

```ruby
class Car < ActiveRecord::Base
    has_quality_tests do
        ...
    end
end
```


### Adding DataQuality tests

Inside the `has_quality_tests` block you are now able to specify your QualityTests.
You add a test by calling:

```ruby
    quality_test "Identifier", :method => :method_name, :attr => :attribute_name, [:if => condition] # to add a predefined quality test
    quality_test "Identifier, :description => "Description", [:if => condition] do |object|
        object.name.length > 3  # to add a custom quality test
    end
```
Currently there are 3 different types of predefined DataQuality test methods.

#### :not_empty

This test should be used if you want to test whether the content of a single attribute ist set/not blank

```ruby
quality_test "Identifier", :method => :not_empty, :attr => :name
```

#### :each_not_empty

This test should be used if your model has associated objects through `has_many` or `has_and_belongs_to_many`. The tests checks the specified attribute of every object associated through the defined association.
**Note:** the `:function` parameter has to be set as it defines the association that shall be tested.
```ruby
quality_test "Identifier", :method => :each_not_empty, :function => :wheels, :attr => :size
```

#### :not_expired

This test should be called if you want to decrease the quality score of an object if the last update is expired
**Note:** The `:since` parameter is optional. Default is 1.year.ago
```ruby
quality_test "Identifier", :method => :not_expired, :since => 2.month.ago
```

#### block

This method can be used if you want to specify custom quality conditions. The block should return either `true` which will make to test pass or `false` which will make it fail.
**Note:** The `:description` parameter is required, since there is no other way to build the test description automatically.
```ruby
quality_test "Identifier", :description => "Test the car has 4 wheels" do |car|
    car.wheels.count == 4
end
```

#### parameters

* **"Identifier"** This parameter is needed to identify the quality test globally (always required, must be uniq)
* **:method** Specifies the predefined test method `:not_empty :each_not_empty not_expired`
* **:attr** Specifies the model attribute that will be tested (required for `:each_not_empty` and `:not_empty`)
* **:function** specifies the association that will be called before testing the attributes (required for `:each_not_empty`)
* **:if** A bunch of code that will be called to eval if the test will be ignored (optional)
* **:description**  Adds a description that will be passed with the result (required for block tests)
* **:since** Used to determin the date when the object expires (optionally for `:not_expired`)


## Usage

Once you have specified all quality tests your model will automatically calculate its quality score when the object is saved.
You can get the current quality score of an object by calling

```ruby
Car.first.quality_score #=> 10
```

Currently every passed quality test increases the quality score by 3. Every test that was set to :not_applicable will increase it by 1

If you want to run the DataQuality tests manually you can do this by calling:

```ruby
Car.first.run_quality_tests
```

This will return an instance of `DataQuality::QualityTestResult` this object stores all infomration about the objects data quality

```ruby
result = Car.first.run_quality_tests(true) #=> true means that the result will be saved to the database
result.passed_tests #=> returns an array with all tests that passed the last check
result.failed_tests #=> returns an array with all tests that failed the last check
result.inapplicable_tests #=> returns an array with all tests that were previously set to not_applicable
result.quality_score #=> returns the objects quality_score
```

You can inspect every single quality_test inside a result by accessing it through one of the QualityTestResult array:

```ruby
result = Car.first.run_quality_tests(true) #=> true means that the result will be saved to the database
passed_test=result.passed_tests.first #=> returns an instance of DataQuality::QualityTest

passed_test.identifier #=> return the tests identifier
passed_test.description #=> returns the description
passed_test.state #=> returns the tests state :pass, :fail, :not_applicable
passed_test.message #=> returns the message the test result answered
```

If you want to test whether a Model uses DataQuality, run:

```ruby
Car.has_quality_tests?
```

Tests can have 3 states: `:pass` means that the test was successfull and `:fail` means the test failed the last time.

The third state is `:not_applicable`. This state means, that the data checked by the test can't be applied to the tested object.
You can assign that state to an object by calling:

```ruby
test=Car.quality_tests.first
test.set_not_applicable_for Car.first
```

Now the first test will be ignored for the specified instance of car. This state will automatically switch to `:pass` if the test passes one time.




