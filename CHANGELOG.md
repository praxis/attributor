# Attributor Changelog

## next

* Introduce the `Dumpable` (empty) module as an interface to indicate that instances of types that include it
will respond to the `.dump` method, as a way to convert their internal substructure to primitive Ruby objects.    * Currently the only two directly dumpable types are Collection and Hash (with the caveat that there are several others that derive from them..i.e., CSV, Model, etc...)
  * The rest of types have `native_types` that are already Ruby primitive Objects.


## 5.0.1

* Fix bug that made Struct/Models skip validation of requirements using the `requires` DSL

## 5.0

* Changed `FieldSelector` sub-attribute selection to use `{}` instead of `()`.


## 4.2.0

* Added an "anonymous" DSL for base `Attributor::Type` which is reported in its `.describe` call.
  * This is a simple documentation bit, that might help the clients to document the type properly (i.e. treat it as if the type was anonymously defined whenever is used, rather than reachable by id/name from anywhere)

* Built advanced attribute requirements for `Struct`,`Model` and `Hash` types. Those requirements allow you to define things like:
  * A list of attributes that are required (equivalent to defining the required: true bit at each of the attributes)
  * At most (n) attributes from a group can be passed in
  * At least (n) attributes from a group are required
  * Exactly (n) attributes from a group are required
  * Example:
  ```
  requires ‘id’, ‘name’
  requires.all ‘id’, ‘name’  # Equivalent to above
  requires.all.of ‘id’, ‘name’  # Equivalent to above again
  requires.at_most(2).of 'consistency', 'availability', 'partitioning'
  requires.at_least(1).of ‘rock’, ‘pop’
  requires.exactly(2).of ‘one’, ‘two’, ’three’
  ```
  * Same example expressed inside a block if so desired
  ```
  requires do
    all 'id', 'name
    all.of 'id', 'name # Equivalent
    at_most(2).of 'consistency', 'availability', 'partitioning'
    …
  end
  ```

## 4.1.0

* Added a `Class` type (useful to avoid demodulization coercions etc...)
* Added `Attributor::FieldSelector` type for parsing hierarchical field
  selection hashes from a string. This is similar to the partial `fields`
  parameter in Google APIs, or the `fields` parameter in the Facebook's Graph
  API.
    * For example: the string `'one,two(a,b)'` would select two top-level fields
      named 'one' and 'two', retrieving the entire contents of 'one', and only
      the 'a' and 'b' sub-fields for 'two'. The type will parse the above string
      into the hash: `{one: true, two: {a: true, b: true}}`.
    * This type is not automatically required by Attributor. To require it use:
      `require 'attributor/extras/field_selector'.
    * This type also depends upon the 'parslet' gem.

## 4.0.1

* `Attribute#check_option!` now calls `load` on any provided value.


## 4.0.0

* Changed the expectation of the value for an `:example` option of an attribute:
  * Before, passing an array of values would indicate that those were a few possible examples for it.
  * Now, any value (except the already existing special regexp or a proc) for an example will need to be of a native type (or coercible to it). This means that an attribute of type `Collection` can take an array example (and be taken as the whole thing)
  * If anybody wants to provide multiple examples for an attribute they can write a proc, and make it return the different ones.

## 3.0.1

* Fixed bug with example Hashes where `[]` with a key not in the hash would throw a `NoMethodError`.
* Fixed bug in `Hash#get` for Hashes without predefined keys. It would throw an error if given a key not present in the hash's contents.


## 3.0.0

* Small enhancements on `describe` for types
  * avoid creating empty `:attributes` key for `Model`
  * ensure embedding `key_type` in `Hash` using `shallow` mode
* Added `Hash#delete`.
* Changed the schema for describing `Hash` to use `attributes` instead of `keys`
  * It makes more sense, and it is compatible with Model and Structs too.
* Undefine JRuby package helper methods in `Model` (org, java...)
* Added support to `Collection.load` for any value that responds to `to_a`
* Fixed `Collection.validate` to complain when value object is not a valida type
* Fixed bug where defining an attribute that references a `Collection` would not properly support defining sub-attributes in a provided block.
* Enhanced the type/attribute `describe` methods of types so that they generate an example if an `example` argument is passed in.
  * Complex (sub-structured) types will not output examples, only 'leaf' ones.
* Improved handling of exceptions during attribute definitions for `Hash`/`Model` that would previously leave the set of attributes in an undefined state. Now, any attempts to use the type will throw an `InvalidDefinition` exception and include the original exception. (#127)
* Removed `undef :empty?` from `Model`
* Made `Collection` a subclass of Array, and `load` create new instances of it.
* Built in proper loading and validation of any `Attribute#example` when the `:example` option is used.


## 2.6.1

* Add the `:custom_data` option for attributes. This is a hash that is passed through to `describe` - Attributor does no processing or handling of this option.
* Added `Type.family` which returns a more-generic "family name". It's defined for all built-in types, and is included in `Type.describe`.
* Cleanup and bug fixes around example generation for `Model`, `Struct` and `Hash`.
  * Avoid creating method accessors for true `Hash` types (only `[]` accessors)
  * Fix common hash methods created for example instances (to play well with lazy attributes)
  * Avoid storing the `Hash#insensitive_map` unless insensitivity enabled

## 2.6.0

* Fixed bug in `example_mixin` where lazy_attributes were not evaluated.
* Fixed bug in `Hash` where the class would refuse to load from another `Attributor::Hash` when there were no keys defined and they were seemingly compatible.
* Fixed a `Hash.dump` bug where nil attribute values would transitively be `dumpe`d therefore causing a nil dereference.
* Hardened the `dump`ing of types to support nil values.
* Fix `attribute.example` to actually accept native types (that are not only Strings)
* Fixed bug where `Hash#get` would insert a nil value if asked for a key that was not present in the hash.
* Fixed bug in `Hash.from_hash` where it would add nil values for keys that are defined on the type but not present in the input.
* Added `Hash#merge` that works with two identically-typed hashes
* Added `Hash#each_pair` for better duck-type compatibility with ::Hash.


## 2.5.0

* Partial support for defining `:default` values through Procs.
  * Note: this is only "partially" supported the `parent` argument of the Proc will NOT contain the correct attribute parent yet. It will contain a fake class, that will loudly complain about any attempt to use any of its methods.
* Fixed `Model.example` to properly handle the case when no attributes are defined on the class.
* `Model#dump` now issues a warning if its contents have keys for attributes not present on the class. The unknown contents are not dumped.
* `Hash.load` now supports loading any value that responds to `to_hash`.
* `Time`, `DateTime`, and `Date` now all return ISO 8601 formatted values from `.dump` (via calling `iso8601` on the value).
* Added `Type.id`, a unique value based on the type's class name.


## 2.4.0

* `Model` is now a subclass of `Hash`.
  * The interface for `Model` instances is almost entirely unchanged, except for the addition of `Hash`-like methods (i.e., you can now do `some_model[:key]` to access attributes).
  * This fixes numerous incompatabilities between models and hashes, as well as confusing differences between the behavior when loading a model vs a hash.
* `String.load` now raises `IncompatibleTypeError` for `Enumerable` values.
* Added `Symbol` type, use with caution as it will automatically call `#to_sym` on anything loaded.

## 2.3.0

* Added `recurse` option to `Type.load` that is used by `Model` and `Hash` to force the loading of values (specifically, so that default values are assigned) even if the loaded value is `nil`.
* Fix `Attributor::CSV` to dump `String` values and generate `String` examples.
* Default values of `false` now work correctly.
* Added `BigDecimal`, `Date` and `Time` types
* `DateTime.load` now raises `CoercionError` (instead of returning `nil`) if given values that can not coerced properly.
* `Hash.dump` now first calls `Hash.load`, and correctly uses defined value types for dumping.
* Added `Hash#get`, for retrieving keys using the same logic the `case_insensitive_load` and `allow_extra` with defined `extra` key.


## 2.2.1

* Dumping attributes will now load the values if they're not in the native type.
* `Model.valid_type?` now accepts hashes.
* `Hash`:
  * Added `:has_key?` to delegation


## 2.2.0

* Fix example generation for Hash and Collection to handle a non-Array context parameter.
* Hash:
  * Added additional options:
    * `:case_insensitive_load` for string-keyed hashes. This allows loading hashes with keys that do not exactly match the case defined in the hash.
    * Added `:allow_extras` option to allow handling of undefined keys when loading.
  * Added `Hash#set` to encapsulate the above options and attribute loading.
  * Added `extra` command in the `keys` DSL, which lets you define a key (whose value should be a Hash), to group any unspecified keys during load.


## 2.1.0

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


## 2.0.0

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
