Attributor Changelog
============================

2.0.0
------

* Added new exception subtypes (load methods return more precise errors now)
* Changed ```Attributor::Model``` to be a class instead of module.
* Improved handling of ```Attributor::Model``` examples:
  * Support creating examples with specific values. i.e.:
  ```ruby
    person = Person.example(name: "Bob")
    person.name # => "Bob"
  ```
  * Example values are now lazily initialized when used.
  * Terminate sub-attribute generation after ```Attributor::Model::MAX_EXAMPLE_DEPTH``` levels to prevent infinite generation.
* Added additional options for Attribute :example values:
  * explicit nil values
  * procs that take 2 arguments now receive the context as the second argument.
* Circular references are now detected and handled in validation and dumping.
* Fixed bug with Model attribute accessors when using false values.

