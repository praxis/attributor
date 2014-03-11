Attributor Changelog
============================

next
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
  