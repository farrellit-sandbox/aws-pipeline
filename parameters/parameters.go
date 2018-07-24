package main

import (
  "gopkg.in/yaml.v2"
  "regexp"
)

// Values
/*
  Values have a name and a value
  They can be specified in 2 ways:
  - as the section of a `values` k/v pair
  - as one of the values of an iterator
  They can be referred to in later DeploySpecs, 
  - within the matches
  - within the values as a string or value
  They are always strings ?
*/

type Value struct {
  key string
  value string
}

// to resolve a value, we'd need the currently scoped values
// so we could replace any placeholders.  We can use a regex for that.
func (v *Value) ResolveValue (vs *Values) {
}

// I guess this is something we'd build over time when
// actually iterating.  I suppose we'd resolve the values at 
// the last possible moment, so their inline parameters 
// could be resolved from all prior steps.  
type ValueSet struct {
  interpolation_regex *Regexp
  kvpairs map[string]*Value
}

func NewValueSet() {
  vs = new(ValueSet)
  vs.interpolation_regex = regexp.Compile(`\$\{([^}]+)\}`)
  vs.kvpairs = make(map[string]*Value)
}

func (vs *ValueSet) GetValue(key string) (value string, ok bool ){
  value, ok := vs.kvpairs[key]
  return value, ok
}

// Matches
/* by default these would be simple strings,
    but they might be regular expressions also ...
    they could even be something else
    - { re: expression }
    - string 
  we'll need to make a custom parser for this; it could try to 
  get a string and if that failed try to get a map and match one 
  of the types we support ( just re ? )
*/
type MatchValue interface {
  isMatch(value string) bool
}

// basic string values
type MatchValueString struct {
  value String
}

func (*mv MatchValueString) isMatch (value string) {
  return mv.value == value
}

// regex values

type MatchValueRegex struct {
  value *Regexp
}

func (*mv MatchValueRegex) isMatch(value string) {
  return mv.value.Match([]byte(value))
}


// this structure brings all the MatchValues under one struct

type Match struct {
  Key string
  Value *MatchValue
}

type DeploySpec struct {
  Priority int
  Matches []*Match
  Values *ValueSet
  Iterators *IteratorSet
  Stacks []string
  StackParameters map[string]map[string]string
}

// I suppose this would be responsible for reading a file
func (dspec *DeploySpec)Parse() {

}
