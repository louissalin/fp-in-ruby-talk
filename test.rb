
require 'values'

# value objects

User = Value.new(:name)

u1 = User.new("Louis")
u2 = User.new("Bob")
u3 = User.new("Louis")

# u1 == u2  # false
# u1 == u3  # true

# quicksort part 1

def quick_sort(list)
	# class exercise
end


# Monoids!

module Monoid
	# Policy:
	# fold: input is an enumerable of objects that must respond to mappend and mempty. 
	#       the result of mappend or mempty must be an instance of the same class
	#       usage of mappend and mempty must follow monoid laws

	def self.fold(monoids)
		monoids.inject(monoids.first.mempty) { |result, item| result.mappend(item) }
	end
end

class Integer
	def mempty
		0
	end

	def mappend(m)
		self + m
	end
end

class IntM
	attr_reader :val

	def initialize(val)
		@val = val
	end

	def mempty
		IntM.new(1)
	end

	def mappend(m)
		IntM.new(@val * m.val)
	end
end

class String
	def mempty
		""
	end

	def mappend(m)
		self + m
	end
end

class Array
	def mempty
		[]
	end

	def mappend(m)
		self + m
	end
end


Monoid.fold([1,2,3,4,5])
Monoid.fold([IntM.new(1), IntM.new(2), IntM.new(3)])
Monoid.fold(["hello", " ", "world"])
Monoid.fold([[1,2,3], [4,5,6]])


## more complex
Subscription = Value.new(:user, :magazines)

class Subscription
	def mempty
		Subscription.new(nil, [])
	end

	def mappend(m)
		if @user.nil?
			Subscription.new(m.user, @magazines.mappend(m.magazines))
		else
			raise "users must be equal" unless @user == m.user
			Subscription.new(@user, @magazines.mappend(m.magazines))
		end
	end
end

s1 = Subscription.new(u1, ["m1"])
s2 = Subscription.new(u1, ["m2"])
s3 = Subscription.new(u2, ["m1"])

# Monoid.fold([s1, s2])
# Monoid.fold([s1, s3]) # fail!

class Publication
	attr_reader :date_subs

	def initialize(date_subs)
		@date_subs = date_subs
	end

	def mempty
		Publication.new({})
	end

	def mappend(m)
		new_dates = self.date_subs.merge(m.date_subs.reject {|k, v| self.date_subs.keys.include?(k)})
		m.date_subs.select {|k, v| self.date_subs.keys.include?(k)}.each do |date, subs|
			new_dates[date] = new_dates[date].mappend(subs)
		end

		Publication.new(new_dates)
	end
end


p1 = Publication.new({'d1' => [s1]})
p2 = Publication.new({'d2' => [s2]})
p3 = Publication.new({'d2' => [s1]})
p4 = Publication.new({'d3' => [s3]})
p5 = Publication.new({'d2' => [s3]})

# all = Monoid.fold([p1,p2,p3,p4,p5])

module Enumerable
	def minject
		Monoid.fold(self)
	end
end

[1,2,3,4,5].minject
(1..5).minject
[p1, p2, p3, p4, p5].minject

## quicksort



def func_quick_sort(list)
	return list if list.length <= 1
	h, *t = list
	quick_sort(t.select { |i| i < h }) + [h] + quick_sort(t.select { |i| i >= h })
end

