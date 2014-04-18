Attributor Changelog
============================

next
------

* Structs now inherit type-level options from their reference.
* Add Collection subclasses for CSVs and Ids
  * CSV type for Collection of values serialized as comma-separated strings.
  * Ids type. A helper for creating CSVs with members matching a given a type's :identity option.
* Allow instances of Models to be initialized with initial data. 
  * Supported formats for the data are equivalent to the loading formats (i.e. ruby Hash, a JSON string or another instance of the same model type).
* Improved context reporting in errors
  * Added contextual information while loading and dumping attributes.
    * `load` takes a new `context` argument (defaulting to a system-wide root) in the form of an array of parent segments.
    * `validate` takes a `context` argument that (instead of a string) is now an array of parent segments.
    * `dump` takes a `context:` option parameter of the same type
  * Enhanced error messages to report the correct context scope.
  * Make Attribute assignments in models to report a special context (not the attributor root) 
    * Instead of reporting "$." as the context , when doing model.field_name=value, they'll now report "assignment.of(field_name)" instead
  * Truncate the lenght of values when reporting loading errors when they're long (i.e. >500 chars)
* `Model.attributes` may now be called more than once to set add or replace attributes. The exact behavior depends upon the types of the attributes being added or replaced. See [model_spec.rb](spec/types/model_spec.rb) for examples.


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

