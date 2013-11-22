# Attributor

An Attribute management, self documenting framework, designed for getting rid of most of your parameter handling boylerplate.
While initially designed to be the backbone for parameter handling in REST services, attribute management can be applied in many other areas.

With Attributor you can:
* Express complex and type-rich attribute structures using an elegant ruby DSL
* Process incoming values against those designs:
    * By verifying they follow constraints and available options specified in your design
    * By coercing values into the specified types when there's a type impedance mismatch
    * By checking presence requirements and conditional dependencies
    * and all with a powerful error reporting system that describes with great detail what errors were encountered
* Export structured information (in JSON) about your attribute definitions which allows you to:
    * easily consume it to generate human consumable documentation about parameter expectations
    * easily aggregate it across different systems.

## How does it work?

You first design the attribute structure you desire into an attributor object.

An attribute can be a simple as a single element type. For example, defining a simple Integer that can range from 0 to 100:

```ruby
Attributor::Integer.new "percentage", :min=>0, :max=>100
```

or a complex hierarchical structure which tells much more about types, restrictions, descriptions, etc.

```ruby
Attributor::Hash.new("person") do
  # Social Security Number as a string, required
  attribute 'ssn', String, :required => true, :description => 'Sociall Security Number'
  # Sex as a string. Only allowing two possible values
  attribute 'sex', String, :values => ['male','female']
  # An address parameter with 3 typed sub-parameters
  attribute 'address', Hash do
    attribute 'street',  String
    attribute 'city',    String
	attribute 'zipcode', Integer
  end
  # A Boolean parameter indicating it the person is an admin, false by default
  attribute 'is_admin?', Boolean, :default => false
  # An array of tags represented as strings, allowing a maximum of 10 within the array
  attribute 'tags',  Array, :element_type => String, :max_size => 10
end
```
With those defintion in place you can then start processing objects against them. From a simple Integer:

```ruby
percentage = Attributor::Integer.new "percentage", :min=>0, :max=>100
percentage.parse(50)
=> [:object => 50, :errors => [] ]

percentage.parse(999)
=> [:object => nil, :errors => [value is larger than the allowed max (100)] ]

```

to larger definitions like the one above:

```ruby
incoming_hash = {
  'ssn' => "123-45-678",
  'sex' => 'male',
  'tags' => ['tag1','tag2']
}
person.parse(incoming_hash)
=> [:object => {
          'ssn' => "123-45-678",
          'sex' => 'male',
          'is_admin?' => false            <=== Note that the while not specified, it filled the attribute with the default
          'tags' => ['tag1','tag2']
        },
     :errors => [] ]
```



While many of the options allowed for each attribute are type-specific, there are a few options that apply to all types. All attributes can specify:
* :description => Simply a human readable string describing this attribute. Used for documentation purposes"
* :default => "the default value to use when not specified (and not required)". Value must be expressed in the native type of the attribute.
* :values => an array of the only possible values allowed for the attribute. Each value in the array must be of the native type of the attribute.
* :required => true|false
* :required_if => A conditional requirement based on existence or values of other attributes, or even custom made functions. Currently supported definitions:
    * :required_if => 'security.use_authentication'  : required if the 'use_authentication' sub-attribute under 'security' has been passed in.
    * :required_if => { 'repository.cvs_type' => 'git' }  : required if the 'cvs_type' sub-attribute under 'repository' is exactly equal to "git".
    * :required_if => { 'repository.cvs_type' => /git/ }  : required if the 'cvs_type' sub-attribute under 'repository' matches the regular expression /git/ .
    * :required_if => { 'repository.cvs_type' => lambda{|val| !x.nil? } }: required if passing the value of 'cvs_type' sub-attribute under 'repository' into the defined function returns true.


## General Help

### Running specs:

    `bundle exec rake spec`

Note: This should also compute code coverage. See below for details on viewing code coverage.

### Generating documentation:

    `bundle exec yard`

### Computing documentation coverage:

    `bundle exec yardstick 'lib/**/*.rb'`

### Computing code coverage:

    `bundle exec rake spec`

    `open coverage/index.html`


## Contributing to attributor

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


## Copyright

Copyright (c) 2013 RightScale. See LICENSE.txt for further details.

