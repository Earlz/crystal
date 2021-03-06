require 'spec_helper'

describe 'Code gen: block' do
  it "generate inline" do
    run(%q(
      def foo
        yield
      end

      foo do
        1
      end
    )).to_i.should eq(1)
  end

  it "pass yield arguments" do
    run(%q(
      def foo
        yield 1
      end

      foo do |x|
        x + 1
      end
    )).to_i.should eq(2)
  end

  it "pass arguments to yielder function" do
    run(%q(
      def foo(a)
        yield a
      end

      foo(3) do |x|
        x + 1
      end
    )).to_i.should eq(4)
  end

  it "pass self to yielder function" do
    run(%q(
      class Int
        def foo
          yield self
        end
      end

      3.foo do |x|
        x + 1
      end
    )).to_i.should eq(4)
  end

  it "pass self and arguments to yielder function" do
    run(%q(
      class Int
        def foo(i)
          yield self, i
        end
      end

      3.foo(2) do |x, i|
        x + i
      end
    )).to_i.should eq(5)
  end

  it "allows access to local variables" do
    run(%q(
      def foo
        yield
      end

      x = 1
      foo do
        x + 1
      end
    )).to_i.should eq(2)
  end

  it "can access instance vars from yielder function" do
    run(%q(
      class Foo
        def initialize
          @x = 1
        end
        def foo
          yield @x
        end
      end

      Foo.new.foo do |x|
        x + 1
      end
    )).to_i.should eq(2)
  end

  it "can set instance vars from yielder function" do
    run(%q(
      class Foo
        def initialize
          @x = 1
        end

        def foo
          @x = yield
        end
        def value
          @x
        end
      end

      a = Foo.new
      a.foo { 2 }
      a.value
    )).to_i.should eq(2)
  end

  it "can use instance methods from yielder function" do
    run(%q(
      class Foo
        def foo
          yield value
        end
        def value
          1
        end
      end

      Foo.new.foo { |x| x + 1 }
    )).to_i.should eq(2)
  end

  it "can call methods from block when yielder is an instance method" do
    run(%q(
      class Foo
        def foo
          yield
        end
      end

      def bar
        1
      end

      Foo.new.foo { bar }
    )).to_i.should eq(1)
  end

  it "nested yields" do
    run(%q(
      def bar
        yield
      end

      def foo
        bar { yield }
      end

      a = foo { 1 }
    )).to_i.should eq(1)
  end

  it "assigns yield to argument" do
    run(%q(
      def foo(x)
        yield
        x = 1
      end

      foo(1) { 1 }
      )).to_i.should eq(1)
  end

  it "can use global constant" do
    run(%q(
      FOO = 1
      def foo
        yield
        FOO
      end
      foo { }
    )).to_i.should eq(1)
  end

  it "return from yielder function" do
    run(%q(
      def foo
        yield
        return 1
      end

      foo { }
      2
    )).to_i.should eq(2)
  end

  it "return from block" do
    run(%q(
      def foo
        yield
      end

      def bar
        foo { return 1 }
        2
      end

      bar
    )).to_i.should eq(1)
  end

  it "return from yielder function (2)" do
    run(%q(
      def foo
        yield
        return 1 if true
        return 2
      end

      def bar
        foo {}
      end

      bar
    )).to_i.should eq(1)
  end

  it "union value of yielder function" do
    run(%q(
      def foo
        yield
        a = 1.1
        a = 1
        a
      end

      foo {}.to_i
    )).to_i.should eq(1)
  end

  it "allow return from function called from yielder function" do
    run(%q(
      def foo
        return 2
      end

      def bar
        yield
        foo
        1
      end

      bar {}
    )).to_i.should eq(1)
  end

  it "" do
    run(%q(
      def foo
        yield
        true ? return 1 : return 1.1
      end

      foo {}.to_i
    )).to_i.should eq(1)
  end

  it "return from block that always returns from function that always yields inside if block" do
    run(%q(
      def bar
        yield
        2
      end

      def foo
        if true
          bar { return 1 }
        else
          0
        end
      end

      foo
    )).to_i.should eq(1)
  end

  it "return from block that always returns from function that conditionally yields" do
    run(%q(
      def bar
        if true
          yield
        end
      end

      def foo
        bar { return 1 }
        2
      end

      foo
    )).to_i.should eq(1)
  end

  it "call block from dispatch" do
    run(%q(
      def bar(y)
        yield y
      end

      def foo
        x = 1.1
        x = 1
        bar(x) { |z| z }
      end

      foo.to_i
    )).to_i.should eq(1)
  end

  it "call block from dispatch and use local vars" do
    run(%q(
      def bar(y)
        yield y
      end

      def foo
        total = 0
        x = 1.5
        bar(x) { |z| total += z }
        x = 1
        bar(x) { |z| total += z }
        x = 1.5
        bar(x) { |z| total += z }
        total
      end

      foo.to_i
    )).to_i.should eq(4)
  end

  it "break without value returns nil" do
    run(%q(
      require "nil"

      def foo
        yield
        1
      end

      x = foo do
        break if true
      end

      x.nil?
    )).to_b.should be_true
  end

  it "break block with yielder inside while" do
    run(%q(
      require "int"
      a = 0
      10.times do
        a += 1
        break if a > 5
      end
      a
    )).to_i.should eq(6)
  end

  it "break from block returns from yielder" do
    run(%q(
      def foo
        yield
        yield
      end

      a = 0
      foo { a += 1; break }
      a
    )).to_i.should eq(1)
  end

  it "break from block with value" do
    run(%q(
      def foo
        while true
          yield
          a = 3
        end
      end

      foo do
        break 1
      end
    )).to_i.should eq(1)
  end

  it "break from block with value" do
    run(%q(
      require "nil"

      def foo
        while true
          yield
          a = 3
        end
      end

      def bar
        foo do
          return 1
        end
      end

      bar.to_i
    )).to_i.should eq(1)
  end

  it "doesn't codegen after while that always yields and breaks" do
    run(%q(
      def foo
        while true
          yield
        end
        1
      end

      foo do
        break 2
      end
    )).to_i.should eq(2)
  end

  pending "break from block with value" do
    run(%q(
      require "int"
      10.times { break 20 }
    )).to_i.should eq(20)
  end

  it "doesn't codegen call if arg yields and always breaks" do
    run(%q(
      require "nil"

      def foo
        1 + yield
      end

      foo { break 2 }.to_i
    )).to_i.should eq(2)
  end

  it "codegens nested return" do
    run(%q(
      def bar
        yield
        a = 1
      end

      def foo
        bar { yield }
      end

      def z
        foo { return 2 }
      end

      z
    )).to_i.should eq(2)
  end

  it "codegens nested break" do
    run(%q(
      def bar
        yield
        a = 1
      end

      def foo
        bar { yield }
      end

      foo { break 2 }
    )).to_i.should eq(2)
  end

  it "codegens call with block with call with arg that yields" do
    run(%q(
      def bar
        yield
        a = 2
      end

      def foo
        bar { 1 + yield }
      end

      foo { break 3 }
    )).to_i.should eq(3)
  end

  it "can break without value from yielder that returns nilable" do
    run(%q(
      require "nil"
      require "reference"

      def foo
        yield
        ""
      end

      a = foo do
        break
      end

      a.nil?
    )).to_b.should be_true
  end

  it "break with value from yielder that returns a nilable" do
    run(%q(
      require "nil"
      require "reference"

      def foo
        yield
        ""
      end

      a = foo do
        break if false
        break ""
      end

      a.nil?
    )).to_b.should be_false
  end

  it "can use self inside a block called from dispatch" do
    run(%q(
      require "nil"

      class Foo
        def do; yield; end
      end
      class Bar < Foo
      end


      class Int
        def foo
          x = Foo.new
          x = Bar.new
          x.do { $x = self }
        end
      end

      123.foo
      $x.to_i
    )).to_i.should eq(123)
  end

  it "return from block called from dispatch" do
    run(%q(
      class Foo
        def do; yield; end
      end
      class Bar < Foo
      end

      def foo
        x = Foo.new
        x = Bar.new
        x.do { return 1 }
        0
      end

      foo
    )).to_i.should eq(1)
  end

  it "breaks from while in function called from block" do
    run(%q(
      def foo
        yield
      end

      def bar
        while true
          break 1
        end
        2
      end

      foo do
        bar
      end
    )).to_i.should eq(2)
  end

  it "allows modifying yielded value (with literal)" do
    run(%q(
      def foo
        yield 1
      end

      foo { |x| x = 2; x }
    )).to_i.should eq(2)
  end

  it "allows modifying yielded value (with variable)" do
    run(%q(
      def foo
        a = 1
        yield a
        a
      end

      foo { |x| x = 2; x }
    )).to_i.should eq(1)
  end

  it "it yields nil from another call" do
    run(%q(
      def foo(key, default)
        foo(key) { default }
      end

      def foo(key)
        if !(true)
          return yield key
        end
        yield key
      end

      foo(1, nil)
    ))
  end

  it "allows yield from dispatch call" do
    run(%q(
      def foo(x : Value)
        yield 1
      end

      def foo(x : Int)
        yield 2
      end

      def bar
        a = 1; a = 1.1
        foo(a) do |i|
          yield i
        end
      end

      x = 0
      bar { |i| x = i }
      x
    )).to_i.should eq(1)
  end

  it "block with nilable type" do
    run(%q(
      class Foo
        def foo
          yield 1
        end
      end

      class Bar
        def foo
          yield 2
          Reference.new
        end
      end

      a = Foo.new || Bar.new
      a.foo {}
    ))
  end

  it "block with nilable type 2" do
    run(%q(
      class Foo
        def foo
          yield 1
          nil
        end
      end

      class Bar
        def foo
          yield 2
          Reference.new
        end
      end

      a = Foo.new || Bar.new
      a.foo {}
    ))
  end

  it "allows yields with less arguments than in block" do
    run(%(
      require "nil"

      def foo
        yield 1
      end

      a = 0
      foo do |x, y|
        a += x + y.to_i
      end
      a
      )).to_i.should eq(1)
  end

  it "codegens block with nilable type with return" do
    run(%q(
      def foo
        if yield
          return Reference.new
        end
        nil
      end

      foo { false }
      ))
  end

  it "codegens block with union with return" do
    run(%q(
      def foo
        yield

        return 1 if 1 == 2

        nil
      end

      foo { }
      ))
  end

  it "codegens if with call with block (ssa issue)" do
    run(%q(
      def bar
        yield
      end

      def foo
        if 1 == 2
          bar do
            x = 1
          end
        else
          3
        end
      end

      foo
      )).to_i.should eq(3)
  end

  it "codegens block with return and yield and no return" do
    run(%q(
      lib C
        fun exit : NoReturn
      end

      def foo(key)
        foo(key) { C.exit }
      end

      def foo(key)
        if 1 == 1
          return 2
        end
        yield
      end

      foo 1
      )).to_i.should eq(2)
  end

  it "codegens while/break inside block" do
    run(%q(
      def foo
        yield
      end

      foo do
        while true
          break
        end
        1
      end
    )).to_i.should eq(1)
  end

  it "codegens block with union arg" do
    run(%q(
      class Number
        def abs
          self
        end
      end

      class Foo(T)
        def initialize(x : T)
          @x = x
        end

        def each
          yield @x
        end
      end

      a = Foo.new(1) || Foo.new(1.5)
      a.each do |x|
        x.abs
      end.to_i
      )).to_i.should eq(1)
  end

  it "codegens block with hierarchy type arg" do
    run(%q(
      class Var(T)
        def initialize(x : T)
          @x = x
        end

        def each
          yield @x
        end
      end

      class Foo
        def bar
          1
        end
      end

      class Bar < Foo
        def bar
          2
        end
      end

      a = Var.new(Foo.new) || Var.new(Bar.new)
      a.each do |x|
        x.bar
      end
      )).to_i.should eq(1)
  end

  it "codegens call with blocks of different type without args" do
    run(%q(
      def foo
        yield
      end

      foo { 1.1 }
      foo { 1 }
    )).to_i.should eq(1)
  end

 end
