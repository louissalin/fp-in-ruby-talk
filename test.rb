require './my_lib'
# value objects

User = Value.new(:name)

u1 = User.new("Louis")
u2 = User.new("Bob")
u3 = User.new("Louis")

# u1 == u2  # false
# u1 == u3  # true

## quicksort

def func_quick_sort(list)
	return list if list.length <= 1
	h, *t = list
	func_quick_sort(t.select { |i| i < h }) + [h] + func_quick_sort(t.select { |i| i >= h })
end

# Policy: Weird implements the orderable policy
Weird = Value.new(:a, :b)
class Weird
	include Orderable
	def compare(other)
		if a < other.a 
			-1
		elsif a > other.a
			1
		else
			0
		end
	end
end

func_quick_sort [Weird.new(1,1), Weird.new(2,2), Weird.new(3,1), Weird.new(4,2)].shuffle

# Monoids!

# I want to
# fold([1,2,3,4,5])
# fold([IntM.new(1), IntM.new(2), IntM.new(3)])
# fold(["hello", " ", "world"])
# fold([[1,2,3], [4,5,6]])

Monoid.fold([1,2,3,4,5])
Monoid.fold([IntM.new(1), IntM.new(2), IntM.new(3)])
Monoid.fold(["hello", " ", "world"])
Monoid.fold([[1,2,3], [4,5,6]])


[1,2,3,4,5].minject
(1..5).minject


class CalcWorkingDays
	def initialize
		@weekdays = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
	end

	def day_range(start_day, span_in_days)
		start_range = @weekdays
		start_range = start_range.rotate until start_range.first == start_day

		Monoid.fold(Array.new(span_in_days / 7 + 1, start_range))[0..span_in_days - 1]
	end

	def day_to_int(day)
		case day
		when :saturday, :sunday
			0
		else
			1
		end
	end

	def working_days(start_day, span_in_days)
		range = day_range(start_day, span_in_days)
		Monoid.fold(range.map {|x| day_to_int(x)})
	end
end

# a = CalcWorkingDays.new
# a.day_range(:tuesday, 356)


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


Order = Value.new(:total)
Customer = Value.new(:order, :address)
class Customer
	def order
		Maybe.new(@order)
	end

	def address
		Maybe.new(@address)
	end
end

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
		Maybe.new(Customer.new(Order.new(100), "some address"))
	end

	def self.fetch_bad_customer
		Nothing.new
	end
end

Maybe.new(1).fmap {|i| i + 1}
Nothing.new.fmap {|i| i + 1}
Repo.fetch_existing_customer().fmap {|c| c.order.value.total}

# fmap means Maybe is a functor

# now what if to ship an order we need both a customer's address AND an order? fmap can't help us.

# Maybe.pure(->(addr, order) {Shipper.ship(address, order)}).
#       apply(customer.address).
#       apply(customer.order)

class Shipper
	def self.ship(address, order)
		puts "shipped order to #{address}"
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

# here maybe_customer is the result of something returning a Maybe, like the repo
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

# as a program

charge_customer = ->(maybe_customer) {
	maybe_customer.pass { |cust|
	cust.address.pass { |addr|
	cust.order.pass { |order|
		puts "ready to charge..."
		discount = order.total > 100 ? 0 : 10
		Maybe.pure Account.charge(order.total - discount)
}}}}

charge_customer.(maybe_customer)