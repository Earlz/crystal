#!/usr/bin/env bin/crystal -run
require "spec"
require "set"

describe "Set" do
  describe "set" do
    it "is empty" do
      Set(Nil).new.empty?.should be_true
    end

    it "has length 0" do
      Set(Nil).new.length.should eq(0)
    end
  end

  describe "add" do
    it "adds and includes" do
      set = Set(Int).new
      set.add 1
      set.includes?(1).should be_true
      set.length.should eq(1)
    end
  end

  describe "delete" do
    it "deletes an object" do
      set = Set.new [1, 2, 3]
      set.delete 2
      set.length.should eq(2)
      set.includes?(1).should be_true
      set.includes?(3).should be_true
    end
  end

  describe "==" do
    it "compares two sets" do
      set1 = Set.new([1, 2, 3])
      set2 = Set.new([1, 2, 3])
      set3 = Set.new([1, 2, 3, 4])

      set1.should eq(set1)
      set1.should eq(set2)
      set1.should_not eq(set3)
    end
  end
end
