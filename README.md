# Attributor

An Attribute management, self documenting framework, designed for getting rid of most of your parameter handling boilerplate.
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

* Check out the latest "master" branch to make sure the feature hasn't been
  implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it
  and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it.
  ** This is important to ensure it's not broken in a future version. **
* Please try not to mess with the Rakefile, version, or history.
  If you want your own version, or if it is otherwise necessary, that is fine,
  but please isolate to its own commit so we can cherry-pick around it.



## License

This software is released under the [MIT License](http://www.opensource.org/licenses/MIT). Please see  [LICENSE](LICENSE) for further details.

Copyright (c) 2014 RightScale
