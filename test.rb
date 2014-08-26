
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

# define the policy in your tests:
# describe "Integer" do
#   it "should be a monoid" do
#     1.mempty.should == 0
#     1.mappend(2).should == 3
#   end
# end

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

Publication = Value.new(:date_subs)
class Publication
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

## Maybe

# ex without Maybe
# c = Customer.find(id)
# if c && c.order
# 	# do something
# end

# but what if instead we could:
# fetch_customer(123).fmap {|c| c.order}.fmap do |o|
#   # do something with o
#


Customer = Value.new(:order)
Order = Value.new(:total)

Maybe = Value.new(:value)
module Repo
	def self.fetch_customer(id)
		# fetch the customer
		if record.present?
			Maybe.new(record)
		else
			Nothing.new
		end
	end

	def self.fetch_existing_customer
		Maybe.new(Customer.new(Order.new(100)))
	end

	def self.fetch_bad_customer
		Nothing.new
	end
end

class Maybe
	def nothing?
		@value == nil
	end

	def fmap
		return Nothing.new if nothing?
		Maybe.new(yield @value)
	end
end

class Nothing < Maybe
	def initialize
		super(nil)
	end
end

Maybe.new(1).fmap {|i| i + 1}
Nothing.new.fmap {|i| i + 1}
Repo.fetch_existing_customer().fmap {|c| c.order.total}

# fmap means Maybe is a functor

# now what if to ship an order we need both a customer's address AND an order? fmap can't help us.

# Maybe.pure(->(addr, order) {Shipper.ship(address, order)}).
#       apply(customer.address).
#       apply(customer.order)

Customer = Value.new(:order, :address)
class Customer
	def order
		Maybe.new(@order)
	end

	def address
		Maybe.new(@address)
	end
end

class Shipper
	def self.ship(address, order)
		puts "shipped order to #{address}"
	end
end

class Maybe
	# policy
	# self.pure: takes a value and wraps it into a Maybe
	# fmap: takes a function that requires at least one parameters and applies the value inside
	#       the current Maybe to it. It returns a Maybe with the new value inside.
	# apply: The current Maybe on which apply is called must wrap a function. The parameter must
	#        be another Maybe value. The function wrapped in the current maybe is applied to the
	# 	     value of the passed in Maybe value. The whole thing returns a new Maybe with the new
	#        value.
	def self.pure(value)
		Maybe.new(value)
	end

	# add currying
	def fmap(&fn)
		return Nothing.new if nothing?
		Maybe.new(fn.curry.(@value))
	end

	def apply(m)
		return Nothing.new if nothing?
		return Nothing.new if m.nothing?

		m.fmap {|v| @value.curry.(v)}
	end
end

t = Maybe.pure ->(x){x+1}
t.apply(Maybe.new(1))

cust = Customer.new(nil, nil)
Maybe.pure(->(address, order) {Shipper.ship(address, order)}).apply(cust.address).apply(cust.order)

cust = Customer.new(Order.new(123), nil)
Maybe.pure(->(address, order) {Shipper.ship(address, order)}).apply(cust.address).apply(cust.order)

cust = Customer.new(Order.new(123), "home")
Maybe.pure(->(address, order) {Shipper.ship(address, order)}).apply(cust.address).apply(cust.order)

maybe_customer = Maybe.new(Customer.new(Order.new(123), "home"))
maybe_customer.fmap do |cust| 
	Maybe.pure(->(address, order) {Shipper.ship(address, order)}).apply(cust.address).apply(cust.order)
end

# monads
class Account
	def self.charge(amount)
		puts "charged customer $#{amount}"
		true
	end
end

class Maybe
	# input: function must take a value and return a monadic value, or computation, in this case just a Maybe
	def pass(&fn)
		return Nothing.new if nothing?
		fn.(@value)
	end
end

maybe_customer.pass do |cust|
	cust.address.pass do |addr|
		cust.order.pass do |order|
			puts "ready to charge..."
			discount = order.total > 100 ? 0 : 10
			Maybe.pure Account.charge(order.total - discount)
		end
	end
end

maybe_customer.pass { |cust|
cust.address.pass { |addr|
cust.order.pass { |order|
	puts "ready to charge..."
	discount = order.total > 100 ? 0 : 10
	Maybe.pure Account.charge(order.total - discount)
}}}
