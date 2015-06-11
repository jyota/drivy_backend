require "json"
require "date"

class Car
	def initialize(id, price_per_day, price_per_km)
		raise ArgumentError, 'id is not Integer' unless id.is_a? Integer
		raise ArgumentError, 'price_per_day is not Integer' unless price_per_day.is_a? Integer
		raise ArgumentError, 'price_per_km is not Integer' unless price_per_km.is_a? Integer
		raise ArgumentError, 'price_per_day is not >= 0' unless price_per_day >= 0 
		raise ArgumentError, 'price_per_km is not >= 0' unless price_per_day >= 0
		@car_id = id
		@price_per_day = price_per_day
		@price_per_km = price_per_km
	end

	def get_id()
		return @car_id
	end

	def get_per_day()
		return @price_per_day
	end

	def get_per_km()
		return @price_per_km
	end
end

class Rental
	def initialize(id, car_id, start_date, end_date, distance)
		start_date = Date.parse(start_date, "%Y-%m-%d")
		end_date = Date.parse(end_date, "%Y-%m-%d")
		raise ArgumentError, 'id is not Integer' unless id.is_a? Integer
		raise ArgumentError, 'car_id is not Integer' unless car_id.is_a? Integer	
		raise ArgumentError, 'distance is not Integer' unless distance.is_a? Integer		
		raise ArgumentError, 'start_date is not Date' unless start_date.is_a? Date
		raise ArgumentError, 'end_date is not Date' unless end_date.is_a? Date
		raise ArgumentError, 'distance is not >= 0' unless distance >= 0
		raise ArgumentError, 'end_date prior to start_date' unless (end_date - start_date) >= 0		
		@id = id
		@car_id = car_id
		@start_date = start_date
		@end_date = end_date
		@distance = distance
		@days = end_date - start_date + 1
	end

	def get_id()
		return @id
	end

	def get_days()
		return @days
	end

	def get_distance()
		return @distance
	end

	def find_car_price(car_array)
		raise ArgumentError, 'car_array is not Array' unless car_array.is_a? Array
		car_array.each do |car|
			if car.get_id() == @car_id then
				@total_price = (@days * car.get_per_day()) + (@distance * car.get_per_km())
			end
		end
		return @total_price
	end
end

cars = []
rentals = []
input = File.read("data.json")
input_hash = JSON.parse(input)

input_hash['cars'].each do |car|
	   cars << Car.new(car['id'], car['price_per_day'], car['price_per_km'])
end

input_hash['rentals'].each do |rental|
	rentals << Rental.new(rental['id'], rental['car_id'], rental['start_date'], rental['end_date'], rental['distance'])
end

output = { 'rentals' => [] }
rentals.each do |rental|
	output['rentals'] <<  { :id => rental.get_id(), :price => rental.find_car_price(cars).to_i }
end

output_file = File.open("my_output.json", 'w')
output_file.write(JSON.pretty_generate(output))
output_file.close

