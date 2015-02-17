Attributor Changelog
============================

next
----

* Fixed bug in `example_mixin` where lazy_attributes were not evaluated.
* Fixed bug in `Hash` where the class would refuse to load from another `Attributor::Hash` when there were no keys defined and they were seemingly compatible.
* Fixed a `Hash.dump` bug where nil attribute values would transitively be `dumpe`d therefore causing a nil dereference.

2.5.0
----

* Partial support for defining `:default` values through Procs.
  * Note: this is only "partially" supported the `parent` argument of the Proc will NOT contain the correct attribute parent yet. It will contain a fake class, that will loudly complain about any attempt to use any of its methods.
* Fixed `Model.example` to properly handle the case when no attributes are defined on the class.
* `Model#dump` now issues a warning if its contents have keys for attributes not present on the class. The unknown contents are not dumped.
* `Hash.load` now supports loading any value that responds to `to_hash`.
* `Time`, `DateTime`, and `Date` now all return ISO 8601 formatted values from `.dump` (via calling `iso8601` on the value).
* Added `Type.id`, a unique value based on the type's class name.

2.4.0
------

* `Model` is now a subclass of `Hash`. 
  * The interface for `Model` instances is almost entirely unchanged, except for the addition of `Hash`-like methods (i.e., you can now do `some_model[:key]` to access attributes).
  * This fixes numerous incompatabilities between models and hashes, as well as confusing differences between the behavior when loading a model vs a hash.
* `String.load` now raises `IncompatibleTypeError` for `Enumerable` values.
* Added `Symbol` type, use with caution as it will automatically call `#to_sym` on anything loaded. 

2.3.0
------

* Added `recurse` option to `Type.load` that is used by `Model` and `Hash` to force the loading of values (specifically, so that default values are assigned) even if the loaded value is `nil`.
* Fix `Attributor::CSV` to dump `String` values and generate `String` examples.
* Default values of `false` now work correctly.
* Added `BigDecimal`, `Date` and `Time` types
* `DateTime.load` now raises `CoercionError` (instead of returning `nil`) if given values that can not coerced properly.
* `Hash.dump` now first calls `Hash.load`, and correctly uses defined value types for dumping.
* Added `Hash#get`, for retrieving keys using the same logic the `case_insensitive_load` and `allow_extra` with defined `extra` key.


2.2.1
------

* Dumping attributes will now load the values if they're not in the native type.
* `Model.valid_type?` now accepts hashes.
* `Hash`:
  * Added `:has_key?` to delegation

2.2.0
------

* Fix example generation for Hash and Collection to handle a non-Array context parameter.
* Hash:
  * Added additional options:
    * `:case_insensitive_load` for string-keyed hashes. This allows loading hashes with keys that do not exactly match the case defined in the hash.
    * Added `:allow_extras` option to allow handling of undefined keys when loading.
  * Added `Hash#set` to encapsulate the above options and attribute loading.
  * Added `extra` command in the `keys` DSL, which lets you define a key (whose value should be a Hash), to group any unspecified keys during load.

2.1.0
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
  * Truncate the length of values when reporting loading errors when they're long (i.e. >500 chars)
* `Model.attributes` may now be called more than once to set add or replace attributes. The exact behavior depends upon the types of the attributes being added or replaced. See [model_spec.rb](spec/types/model_spec.rb) for examples.
* Greately enhanced Hash type with individual key specification (rather than
  simply defining the types of keys)
  * Loaded Hash types now return instances of the class rather than a simple Ruby Hash.
* Introduced a new FileUpload type. This can be easily used in Web servers to map incoming multipart file uploads.
* Introduced a new Tempfile type.

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

