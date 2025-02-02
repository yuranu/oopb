# oopb
Object Oriented Programming in bash

Just a proof of concept, that this is possible and even usable.

Disclaimer: bash is not intended for this.
Bash shall be used for writing short scritps, doing one task and doing it well.

If for some reason, you think you need to use bash OOP in production - think again.
This means your script is too complex. You likely need to rewrite it in another language.

Usage:

```shell
source ./oopb.bash

test() {
  # Declare base class
  ::class Base \
  method do_it
  Base::do_it() {
    echo -n "Base;"
  }

  # Declare derived class
  ::class Derived extend Base \
  method do_it
  Derived::do_it() {
    $self.super do_it
    echo -n "Derived;"
  }

  # Maybe another derived class
  ::class Derived2 extend Derived \
  method do_it
  Derived2::do_it() {
    $self.super do_it
    echo -n "Derived2;"
  }
  
  local obj
  ::new obj Derived2
  $obj.do_it
}

test
```

See oopb_test.bash for more examples.
