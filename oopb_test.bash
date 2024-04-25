# This uses https://github.com/pgrange/bash_unit

source ./oopb.bash

test_chain_inheritance() {
  ::class Base \
  method do_it
  
  Base::do_it() {
    echo -n "Base;"
  }
  
  ::class Derived extend Base \
  method do_it
  
  Derived::do_it() {
    $self.super do_it
    echo -n "Derived;"
  }
  
  ::class Derived2 extend Derived \
  method do_it
  
  Derived2::do_it() {
    $self.super do_it
    echo -n "Derived2;"
  }
  
  local obj
  ::new obj Derived2
  assert_equals "Base;Derived;Derived2;" "$($obj.do_it)"
}

test_dispatch() {
  ::class Banana \
  method Eat \
  var weight
  
  Banana::Eat() {
    echo "Yum"
  }
  
  local banana
  ::new banana Banana
  
  assert_equals "Yum" "$($banana.Eat)"
  
  $banana.weight=100
  
  assert_equals 100 $($banana.weight)
}

test_sanity_scenario() {
  # Declare some classes
  ::class Car \
  method Drive \
  method Honk \
  var name
  assert_equals $? 0
  Car::init() {
    $self.name=$1
  }
  Car::Drive() {
    echo "Driving car named $($self.name)"
  }
  Car::Honk() {
    echo "Hooonk"
  }
  
  assert_equals $? 0
  
  ::class Truck extend Car \
  method Honk \
  method Load \
  method FreeSpaceLeft \
  var max_load \
  var load
  assert_equals $? 0
  Truck::init() {
    $self.super init $1
    $self.max_load=$2
    $self.load=0
  }
  Truck::Honk() {
    echo "Boooooooop"
  }
  Truck::Load() {
    $self.load=$(($($self.load) + $1))
  }
  Truck::FreeSpaceLeft() {
    echo "$(($($self.max_load) - $($self.load)))"
  }
  assert_equals $? 0
  
  # Create some instances
  local car
  ::new car Car Bumblebee
  assert_equals $? 0
  local truck
  ::new truck Truck Optimus 10
  assert_equals $? 0
  
  assert_equals "Driving car named Bumblebee" "$($car.Drive)"
  assert_equals "Hooonk" "$($car.Honk)"
  
  assert_equals "Driving car named Optimus" "$($truck.Drive)"
  assert_equals "Boooooooop" "$($truck.Honk)"
  $truck.Load 3
  assert_equals 7 "$($truck.FreeSpaceLeft)"
  
  assert "$car.is_a Car"
  assert_fail "$car.is_a Truck"
  assert "$truck.is_a Car"
  assert "$truck.is_a Truck"
  
  assert "$car.typeof Car"
  assert "$truck.typeof Truck"
  
  declare -n name_ref=$($truck.ref name)
  assert_equals "Optimus" "$name_ref"
  $truck.del
  assert_equals $? 0
  assert_equals "" "$name_ref"
  
  $car.del
  assert_equals $? 0
  
}
