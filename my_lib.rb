require 'values'

# Orderable
# an object is orderable if it has a function compare(other)
# that returns 0 for equality, -1 or 1 for < or >

module Orderable
    # can be included on orderable objects

    def <(other)
        self.compare(other) < 0
    end

    def >(other)
        self.compare(other) > 0
    end

    def ==(other)
        self.compare(other) == 0
    end

    def >=(other)
        self > other || self == other
    end

    def <=(other)
        self < other || self == other
    end
end

module Monoid
    # can be included on monoid objects

    def self.fold(monoids)
        monoids.inject(monoids.first.mempty) { |result, item| result.mappend(item) }
    end
end

class Integer
    # Policy: Integer implements monoid
    def mempty
        0
    end

    def mappend(m)
        self + m
    end
end

IntM = Value.new(:val)
class IntM
    # Policy: IntM implements monoid
    def mempty
        IntM.new(1)
    end

    def mappend(m)
        IntM.new(val * m.val)
    end
end

class String
    # Policy: String implements monoid

    def mempty
        ""
    end

    def mappend(m)
        self + m
    end
end

class Array
    # Policy: Array implements monoid
    def mempty
        []
    end

    def mappend(m)
        self + m
    end
end

module Enumerable
    def minject
        Monoid.fold(self)
    end
end

Maybe = Value.new(:value)
class Maybe
    # implements the Functor, Applicative and Monad policies

    def nothing?
        @value == nil
    end

    def fmap
        return Nothing.new if nothing?
        Maybe.new(yield @value)
    end

    def self.pure(value)
        Maybe.new(value)
    end

    def apply(m)
        return Nothing.new if nothing?
        return Nothing.new if m.nothing?

        m.fmap {|v| @value.curry.(v)}
    end

    def pass(&fn)
        return Nothing.new if nothing?
        fn.(@value)
    end
end

class Nothing < Maybe
    def initialize
        super(nil)
    end
end