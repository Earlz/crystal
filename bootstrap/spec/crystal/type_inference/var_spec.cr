#!/usr/bin/env bin/crystal -run
require "../../spec_helper"

include Crystal

describe "Type inference: var" do
  it "types an assign" do
    input = parse "a = 1"
    result = infer_type input
    mod = result.program
    input = result.node
    if input.is_a?(Assign)
      input.target.type.should eq(mod.int32)
      input.value.type.should eq(mod.int32)
      input.type.should eq(mod.int32)
    else
      fail "expected input to be an Assign"
    end
  end

  it "types a variable" do
    input = parse "a = 1; a"
    result = infer_type input
    mod = result.program
    input = result.node

    if input.is_a?(Expressions)
      input.last.type.should eq(mod.int32)
      input.type.should eq(mod.int32)
    else
      fail "expected input to be an Expressions"
    end
  end
end
