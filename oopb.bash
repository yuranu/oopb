# Source this file to enable OOPB

[ -n "$oopb_util__DEBUG_LEVEL" ] || oopb_util__DEBUG_LEVEL=30
[ -n "$oopb__util__DEBUG" ] || oopb__util__DEBUG=true

# Log levels constants
readonly oopb__util__CRITICAL=0
readonly oopb__util__ERROR=10
readonly oopb__util__WARNING=20
readonly oopb__util__INFO=30
readonly oopb__util__DEBUG=40
readonly oopb__util__TRACE=50

# Terminal color codes
readonly oopb__util__RED='\033[0;31m'
readonly oopb__util__GREEN='\033[0;32m'
readonly oopb__util__YELLOW='\033[0;33m'
readonly oopb__util__BLUE='\033[0;34m'
readonly oopb__util__MAGENTA='\033[0;35m'
readonly oopb__util__CYAN='\033[0;36m'
readonly oopb__util__WHITE='\033[0;37m'
readonly oopb__util__NC='\033[0m'

# Reserved keywords
readonly oopb__util__RESERVED_KEYWORDS=(
  extend
  method
  var
  init
  fini
  super
  ref
  is_a
  typeof
)

# Calls a function if in debug mode
oopb::util::debug_call() {
  $oopb__util__DEBUG && "$@"
}

# Check if a command is defined
oopb::util::is_cmd_defined() {
  command -v "$1" >/dev/null 2>&1
}

# Check if a variable is defined
oopb::util::is_var_defined() {
  [[ -n "${!1}" ]]
}

# Check if class is defined. Can be identified by the presence of the
# is_defined variable.
oopb::util::is_class_defined() {
  oopb::util::valid_string "$1" || return 1
  oopb::util::is_var_defined "${1}__is_defined"
}

# Gemerate a unique object_id
oopb::util::alloc_object_id() {
  # Just generate a random UUID, assume it is unique. Also make sure it is in
  # a valid variable name format.
  local -r uuid=$(cat /proc/sys/kernel/random/uuid)
  echo "_${uuid//-/_}"
}

# Returns true is alphanumeric and starts with a letter or underscore and is not
# a reserved keyword
oopb::util::valid_string() {
  [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && {
    for keyword in "${oopb__util__RESERVED_KEYWORDS[@]}"; do
      [[ "$1" == "$keyword" ]] && return 1
    done
    return 0
  }
}

oopb::util::perror() {
  echo >&2 "$@"
}

# Log functions
oopb::util::log() {
  local -r level="$1"
  shift
  if [[ $level -gt "$oopb_util__DEBUG_LEVEL" ]]; then
    return
  fi
  local -r message="$@"
  echo >&2 -n "[$(date '+%Y-%m-%d %H:%M:%S')]: "
  if [[ $level -le "$oopb__util__CRITICAL" ]]; then
    echo >&2 -e "${oopb__util__RED}CRITICAL: $message${oopb__util__NC}"
    elif [[ $level -le "${oopb__util__ERROR}" ]]; then
    echo >&2 -e "${oopb__util__RED}ERROR: $message${oopb__util__NC}"
    elif [[ $level -le "${oopb__util__WARNING}" ]]; then
    echo >&2 -e "${oopb__util__YELLOW}WARNING: $message${oopb__util__NC}"
    elif [[ $level -le "${oopb__util__INFO}" ]]; then
    echo >&2 -e "INFO: $message"
    elif [[ $level -le "${oopb__util__DEBUG}" ]]; then
    echo >&2 -e "${oopb__util__BLUE}DEBUG: $message${oopb__util__NC}"
  else
    echo >&2 -e "${oopb__util__CYAN}TRACE: $message${oopb__util__NC}"
  fi
}
oopb::util::CRITICAL() {
  oopb::util::log "$oopb__util__CRITICAL" "$@"
}
oopb::util::ERROR() {
  oopb::util::log "$oopb__util__ERROR" "$@"
}
oopb::util::WARNING() {
  oopb::util::log "$oopb__util__WARNING" "$@"
}
oopb::util::INFO() {
  oopb::util::log "$oopb__util__INFO" "$@"
}
oopb::util::DEBUG() {
  oopb::util::log "$oopb__util__DEBUG" "$@"
}
oopb::util::TRACE() {
  oopb::util::log "$oopb__util__TRACE" "$@"
}

# Outputs the name of a variable containing a list of methods for a class
oopb::util::prototype_methods() {
  local -r class_name="$1"
  echo "${class_name}__prototype__methods"
}

# Outputs the name of a variable containing a list of vars for a class
oopb::util::prototype_vars() {
  local -r class_name="$1"
  echo "${class_name}__prototype__vars"
}

# Outputs the name of a variable containing a list of base classes for a class
oopb::util::prototype_bases() {
  local -r class_name="$1"
  echo "${class_name}__prototype__bases"
}

# Outputs the name of a variable containing the object class
oopb::util::object_class() {
  local -r object_id="$1"
  echo "${object_id}__class_name"
}

# Outputs the name of a variable containing the object vars array
oopb::util::object_vars() {
  local -r object_id="$1"
  echo "${object_id}__vars"
}

# Validate the class, or print an error and fail
oopb::util::validate_class() {
  local -r class_name="$1"
  oopb::util::is_class_defined "$class_name" ||
  {
    oopb::util::perror "Undefined class name '$class_name'"
    return 1
  }
}

# Validate the object_id is a valid object of a valid class, or print an error
# and fail
oopb::util::validate_object() {
  local -r object_id="$1"
  # Validate object id format
  [[ "$object_id" =~ ^_[a-f0-9]{8}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{12}$ ]] ||
  {
    oopb::util::perror "Invalid object id '$object_id'"
    return 1
  }
  # Validate object class
  declare -n class_name="$(oopb::util::object_class $object_id)"
  oopb::util::validate_class "$class_name" ||
  {
    oopb::util::perror "Invalid object class '$class_name'"
    return 1
  }
}

# Returns success iff the object or one of its bases has a variable with the
# given name
oopb::util::is_var() {
  local -r object_id="$1"
  local -r var_name="$2"
  declare -n class_name="$(oopb::util::object_class $object_id)"
  oopb::util::TRACE "Checking object $object_id $class_name for var $var_name"
  # Iterate over the class and its bases. Remember that our clss is always the
  # first in the list of bases.
  declare -n bases_array="$(oopb::util::prototype_bases $class_name)"
  for base in "${bases_array[@]}"; do
    declare -n vars_array="$(oopb::util::prototype_vars $base)"
    for var in "${vars_array[@]}"; do
      if [[ "$var" == "$var_name" ]]; then
        return 0
      fi
    done
  done
  return 1
}

# Declare a class
# Input format:
# oopb::class <class_name> [extend <base_name> ...]
#             [method <method_name> ...] [var <var_name> ...]
oopb::class() {
  # First - read the declaration, and validate it is correct. The output of
  # this stage are three arrays: methods, vars and bases.
  # TODO: consider making these associative arrays to support traits such as
  # public/private/protected and possibly const.
  local -r class_name=$1
  shift
  oopb::util::valid_string "$class_name" ||
  {
    oopb::util::perror "Invalid class name '$class_name'"
    return 1
  }
  oopb::util::TRACE "Declaring class $class_name"
  
  local -a methods=()
  local -a vars=()
  local -a bases=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      extend)
        shift
        base_name="$1"
        shift
        oopb::util::valid_string "$base_name" ||
        {
          oopb::util::perror "Invalid base class name '$base_name'"
          return 1
        }
        bases+=("$base_name")
        oopb::util::TRACE "Extending class $base_name"
      ;;
      method)
        shift
        method_name="$1"
        shift
        oopb::util::valid_string "$method_name" ||
        {
          oopb::util::perror "Invalid method name '$method_name'"
          return 1
        }
        methods+=("$method_name")
        oopb::util::TRACE "Declaring method $method_name"
      ;;
      var)
        shift
        var_name="$1"
        shift
        oopb::util::valid_string "$var_name" ||
        {
          oopb::util::perror "Invalid var name '$var_name'"
          return 1
        }
        vars+=("$var_name")
        oopb::util::TRACE "Declaring var $var_name"
      ;;
      *)
        oopb::util::perror "Unexpected keyword '$1' in class declaration"
        return 1
      ;;
    esac
  done
  # Now expand the bases.
  local -a bases_expanded=()
  # Iterate the bases in reverse order
  for base_index in $(seq $((${#bases[@]} - 1)) -1 0); do
    local base_name="${bases[$base_index]}"
    oopb::util::TRACE "Expanding base class $base_name"
    # Get the base class bases
    declare -n base_bases="$(oopb::util::prototype_bases $base_name)"
    # Iterate over the base class bases in reverse order
    for base_base_index in $(seq $((${#base_bases[@]} - 1)) -1 0); do
      local base_base_name="${base_bases[$base_base_index]}"
      oopb::util::TRACE "Expanding base base class $base_base_name"
      # If the base class base is not already in the expanded bases, add it
      local found=false
      for expanded_base in "${bases_expanded[@]}"; do
        if [[ "$expanded_base" == "$base_base_name" ]]; then
          found=true
          break
        fi
      done
      $found || bases_expanded=("$base_base_name" "${bases_expanded[@]}")
    done
  done
  # For simplicity, we also prepend the class itself to its bases
  bases_expanded=("$class_name" "${bases_expanded[@]}")
  
  # Now register the class prototype.
  eval "declare -ga $(oopb::util::prototype_methods $class_name)=(${methods[@]})"
  eval "declare -ga $(oopb::util::prototype_vars $class_name)=(${vars[@]})"
  eval "declare -ga $(oopb::util::prototype_bases $class_name)=(${bases_expanded[@]})"
  eval "declare -g ${class_name}__is_defined=true"
}

# Initialize a new object and assign it to a variable
# Input format:
# oopb::new <var_name> <class_name> [arg ...]
oopb::new() {
  local -r var_name="$1"
  shift
  local -r class_name="$1"
  shift
  
  oopb::util::valid_string "$var_name" ||
  {
    oopb::util::perror "Invalid variable name '$var_name'"
    return 1
  }
  oopb::util::validate_class "$class_name" || return 1
  oopb::util::TRACE "Creating new object of class $class_name"
  local -r object_id=$(oopb::util::alloc_object_id)
  # Assign the object class to the object
  eval "declare -g $(oopb::util::object_class $object_id)=$class_name"
  # Initialize object vars
  local vars_base=$(oopb::util::object_vars $object_id)
  declare -n vars_array=$(oopb::util::prototype_vars $class_name)
  # All instance variables are stored as separate variables.
  # This allows us to:
  # 1. Easily take a reference to an instance variable for get/set operations.
  # 2. Store complex data types like arrays and associative arrays.
  for var in "${vars_array[@]}"; do
    eval "declare -g ${vars_base}__${var}"
  done
  
  # Call the init method. If it is not defined, it is OK.
  oopb::call "$object_id" init "$@"
  # Finaly assign the object to the variable
  eval "$var_name=\"oopb::util::dispatch $object_id \""
}

# Delete an object
# Input format:
# oopb::del <object_id>
oopb::del() {
  local -r object_id="$1"
  oopb::util::validate_object "$object_id" || return 1
  oopb::util::TRACE "Deleting object $object_id"
  # Call the fini method. If it is not defined, it is OK.
  oopb::call "$object_id" fini
  # Get the base classes
  declare -n class_name="$(oopb::util::object_class $object_id)"
  declare -n bases_array="$(oopb::util::prototype_bases $class_name)"
  # Iterate over all base classes
  for base_name in "${bases_array[@]}"; do
    # Iterate over all variables in the base class, and unset them
    declare -n vars_array="$(oopb::util::prototype_vars $base_name)"
    local vars_base=$(oopb::util::object_vars $object_id)
    for var in "${vars_array[@]}"; do
      unset "${vars_base}__${var}"
    done
  done
  
  # Last, unset the object class
  unset "$(oopb::util::object_class $object_id)"
}

# Internal function to call a method on an object, with known starting class and
# virtual table depth
oopb::util::call() {
  local -r object_id="$1"
  shift
  local -r class_name="$1"
  shift
  local -r virtual_table_depth="$1"
  shift
  local -r method_name="$1"
  shift
  
  # We shifted all metadata arguments. The rest are the method arguments.
  
  # Important trick: self, class_name and virtual_table_depth are local to this
  # function, so they are also visible from inside the called method. If,
  # however, the method calls another method, they will change to a different
  # value.
  local oopb__virtual_table_depth=$virtual_table_depth
  local -r self="oopb::util::dispatch $object_id "
  
  oopb::util::TRACE "Requested to call method $method_name on object" \
  "$object_id of type $class_name with depth $oopb__virtual_table_depth"
  
  declare -n bases_array="$(oopb::util::prototype_bases $class_name)"
  local base_name="${bases_array[$oopb__virtual_table_depth]}"
  
  # Iterate until we either find the method or reach the end of the base classes
  # array
  while [[ $oopb__virtual_table_depth -lt ${#bases_array[@]} ]]; do
    oopb::util::TRACE "Trying depth $oopb__virtual_table_depth, owner class" \
    "$base_name"
    declare -n vt="$(oopb::util::prototype_methods $base_name)"
    # Check if the method is defined in the virtual table.
    local method_impl_name=""
    # Special case: init or fini methods are not in the virtual table
    # In a special case of init or fini methods, it is OK to not have them
    if [[ "$method_name" == "init" ]] || [[ "$method_name" == "fini" ]]; then
      if oopb::util::is_cmd_defined "${base_name}::$method_name"; then
        oopb::util::TRACE "Found method $method_name in class $base_name"
        method_impl_name="${base_name}::$method_name"
      fi
    fi
    # Check if the method is defined in the virtual table
    if [[ -z "$method_impl_name" ]]; then
      for method in "${vt[@]}"; do
        if [[ "$method" == "$method_name" ]]; then
          oopb::util::TRACE "Found method $method_name in class $base_name"
          method_impl_name="$base_name::$method_name"
          break
        fi
      done
    fi
    # If the method is found in the virtual table, invoke it.
    if [[ -n "$method_impl_name" ]] &&
    oopb::util::is_var_defined "method_impl_name"; then
      oopb::util::TRACE "Calling method $method_name of owner class" \
      "$base_name on object $object_id"
      $method_impl_name "$@"
      return
    fi
    # If the method is not found in the virtual table, try the next base class
    oopb__virtual_table_depth=$(($oopb__virtual_table_depth + 1))
    base_name="${bases_array[$oopb__virtual_table_depth]}"
  done
  
  # In a special case of init or fini methods, it is OK to not have them
  if [[ "$method_name" == "init" ]] || [[ "$method_name" == "fini" ]]; then
    oopb::util::TRACE "Method $method_name not found in object $object_id"
    return
  fi
  oopb::util::ERROR "Method $method_name not found in object $object_id"
  false
}

# Call a method on an object
# Input format:
# oopb::call <object_id> <method_name> [arg ...]
oopb::call() {
  local -r object_id="$1"
  shift
  oopb::util::validate_object "$object_id" || return 1
  local -r method_name="$1"
  shift
  
  declare -n class_name="$(oopb::util::object_class $object_id)"
  oopb::util::call "$object_id" "$class_name" 0 "$method_name" "$@"
}

# Call a method on an object's base class
# Input format:
# oopb::super <object_id> <method_name> [arg ...]
oopb::super() {
  local -r object_id="$1"
  shift
  oopb::util::validate_object "$object_id" || return 1
  local -r method_name="$1"
  shift
  
  declare -n class_name="$(oopb::util::object_class $object_id)"
  oopb::util::call "$object_id" "$class_name" \
  $(($oopb__virtual_table_depth + 1)) "$method_name" "$@"
}

# Get a variable from an object
# Input format:
# oopb::get <object_id> <variable_name>
# Output format:
oopb::get() {
  local -r object_id="$1"
  shift
  oopb::util::validate_object "$object_id" || return 1
  local -r var_name="$1"
  oopb::util::TRACE "Getting variable $var_name from object $object_id"
  declare -n variable="$(oopb::ref "$object_id" "$var_name")" || return 1
  echo "$variable"
}

# Set a variable on an object
# Input format:
# oopb::set <object_id> <variable_name> <value>
oopb::set() {
  local -r object_id="$1"
  shift
  oopb::util::validate_object "$object_id" || return 1
  local -r var_name="$1"
  shift
  local -r value="$1"
  oopb::util::TRACE "Setting variable $var_name on object $object_id to $value"
  declare -n variable="$(oopb::ref "$object_id" "$var_name")" || return 1
  variable="$value"
}

# Return a reference to an object variable
# Input format:
# oopb::ref <object_id> <variable_name>
oopb::ref() {
  local -r object_id="$1"
  shift
  oopb::util::validate_object "$object_id" || return 1
  local -r var_name="$1"
  local vars_array="$(oopb::util::object_vars $object_id)"
  echo "${vars_array}__${var_name}"
}

# Check if an object is an instance of a class or its subclass
# Input format:
# oopb::is_a <object_id> <class_name>
oopb::is_a() {
  local -r object_id="$1"
  shift
  oopb::util::validate_object "$object_id" || return 1
  local -r class_name="$1"
  oopb::util::validate_class "$class_name" || return 1
  declare -n object_class="$(oopb::util::object_class $object_id)"
  if [[ "$object_class" == "$class_name" ]]; then
    echo "$object_class"
    return 0
  fi
  declare -n bases_array="$(oopb::util::prototype_bases $object_class)"
  for base in "${bases_array[@]}"; do
    if [[ "$base" == "$class_name" ]]; then
      return 0
    fi
  done
  return 1
}

# Get the class of an object
# Input format:
# oopb::typeof <object_id>
oopb::typeof() {
  local -r object_id="$1"
  oopb::util::validate_object "$object_id" || return 1
  declare -n object_class="$(oopb::util::object_class $object_id)"
  echo "$object_class"
}

# Invoke a requested operation on an object
# Input format:
# oopb::util::dispatch <object_id> .\s*operation
oopb::util::dispatch() {
  local -r object_id="$1"
  shift
  # Supported format is . either followed by a whitespace or not, and tehn an
  # operation
  local operation="$1"
  if [[ "$operation" == '.' ]]; then
    shift
    operation="$1"
  else
    # Remove operation first character
    operation="${operation:1}"
  fi
  case "$operation" in
    super)
      shift
      oopb::util::TRACE "Super operation $operation"
      oopb::super "$object_id" "$@"
    ;;
    ref)
      shift
      oopb::util::TRACE "Ref operation $operation"
      oopb::ref "$object_id" "$@"
    ;;
    del)
      shift
      oopb::util::TRACE "Del operation $operation"
      oopb::del "$object_id" "$@"
    ;;
    is_a)
      shift
      oopb::util::TRACE "Is_a operation $operation"
      oopb::is_a "$object_id" "$@"
    ;;
    typeof)
      shift
      oopb::util::TRACE "Typeof operation $operation"
      oopb::typeof "$object_id" "$@"
    ;;
    *)
      # Is it an assignment?
      if [[ "$operation" == *'='* ]]; then
        oopb::util::TRACE "Assignment operation $operation"
        local -r var_name="${operation%%=*}"
        local -r value="${operation#*=}"
        oopb::set "$object_id" "$var_name" "$value"
      else
        # Is it a variable?
        if oopb::util::is_var "$object_id" "$operation"; then
          oopb::util::TRACE "Get operation $operation"
          oopb::get "$object_id" "$operation"
        else
          # Is it a method?
          shift
          oopb::util::TRACE "Call operation $operation"
          oopb::call "$object_id" "$operation" "$@"
        fi
      fi
  esac
}

::call() { oopb::call "$@"; }
::super() { oopb::super "$@"; }
::get() { oopb::get "$@"; }
::set() { oopb::set "$@"; }
::ref() { oopb::ref "$@"; }
::new() { oopb::new "$@"; }
::del() { oopb::del "$@"; }
::is_a() { oopb::is_a "$@"; }
::typeof() { oopb::typeof "$@"; }
::class() { oopb::class "$@"; }
::bless() { oopb::bless "$@"; }
