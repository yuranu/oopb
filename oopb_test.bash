# This uses https://github.com/pgrange/bash_unit

source ./oopb.bash

test_sanity_scenario() {
  # Declare some classes
  ::class Car \
    method Drive \
    method Honk \
    var name
  assert_equals $? 0
  Car::init() {
    ::set $self name $1
  }
  Car::Drive() {
    echo "Driving car named $(::get $self name)"
  }
  Car::Honk() {
    echo "Hooonk"
  }
  ::bless Car
  assert_equals $? 0

  ::class Truck extend Car \
    method Honk \
    method Load \
    method FreeSpaceLeft \
    var max_load \
    var load
  assert_equals $? 0
  Truck::init() {
    ::super $self init $1
    ::set $self max_load $2
    ::set $self load 0
  }
  Truck::Honk() {
    echo "Boooooooop"
  }
  Truck::Load() {
    ::set $self load $(($(::get $self load) + $1))
  }
  Truck::FreeSpaceLeft() {
    echo "$(($(::get $self max_load) - $(::get $self load)))"
  }
  ::bless Truck
  assert_equals $? 0

  # Create some instances
  local car
  ::new car Car Bumblebee
  assert_equals $? 0
  local truck
  ::new truck Truck Optimus 10
  assert_equals $? 0

  assert_equals "Driving car named Bumblebee" "$(::call $car Drive)"
  assert_equals "Hooonk" "$(::call $car Honk)"

  assert_equals "Driving car named Optimus" "$(::call $truck Drive)"
  assert_equals "Boooooooop" "$(::call $truck Honk)"
  ::call $truck Load 3
  assert_equals 7 "$(::call $truck FreeSpaceLeft)"

  assert "::is_a $car Car"
  assert_fail "::is_a $car Truck"
  assert "::is_a $truck Car"
  assert "::is_a $truck Truck"

  assert "::typeof $car Car"
  assert "::typeof $truck Truck"

  declare -n name_ref=$(::ref $truck name)
  assert_equals "Optimus" "$name_ref"
  ::del $truck
  assert_equals $? 0
  assert_equals "" "$name_ref"

  ::del $car
  assert_equals $? 0

}
