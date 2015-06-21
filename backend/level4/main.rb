require "json"
require "date"
require "sinatra"

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
	def initialize(id, car_id, start_date, end_date, distance, deductible_reduction)
		start_date = Date.parse(start_date, "%Y-%m-%d")
		end_date = Date.parse(end_date, "%Y-%m-%d")
		raise ArgumentError, 'id is not Integer' unless id.is_a? Integer
		raise ArgumentError, 'car_id is not Integer' unless car_id.is_a? Integer	
		raise ArgumentError, 'distance is not Integer' unless distance.is_a? Integer		
		raise ArgumentError, 'start_date is not Date' unless start_date.is_a? Date
		raise ArgumentError, 'end_date is not Date' unless end_date.is_a? Date
		raise ArgumentError, 'distance is not >= 0' unless distance >= 0
		raise ArgumentError, 'end_date prior to start_date' unless (end_date - start_date) >= 0
		raise ArgumentError, 'deductible_reduction is not boolean' unless !!deductible_reduction == deductible_reduction		
		@id = id
		@car_id = car_id
		@start_date = start_date
		@end_date = end_date
		@distance = distance
		@days = end_date - start_date + 1
		@deductible_reduction = deductible_reduction
		if @deductible_reduction == true then
			@deductible_total_price = (400 * @days).to_i
		else 
			@deductible_total_price = 0
		end
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
				ten_percent_rate = (car.get_per_day() - (car.get_per_day() * 0.1)).to_i
				thirty_percent_rate = (car.get_per_day() - (car.get_per_day() * 0.3)).to_i
				fifty_percent_rate = (car.get_per_day() - (car.get_per_day() * 0.5)).to_i
				remaining_days = @days
				fifty_days = 0
				thirty_days = 0
				ten_days = 0
				if remaining_days > 10 then
					fifty_days = remaining_days - 10
					remaining_days = 10
				end
				if remaining_days > 4 then
					thirty_days = remaining_days - 4
					remaining_days = 4
				end
				if remaining_days > 1 then
					ten_days = remaining_days - 1
					remaining_days = 1
				end
				@total_price = (@distance * car.get_per_km()).to_i + (fifty_days * fifty_percent_rate).to_i + (thirty_days * thirty_percent_rate).to_i + (ten_days * ten_percent_rate).to_i + (remaining_days * car.get_per_day()).to_i
			end
		end
		return @total_price
	end

	def calculate_commission()
		if not defined? @total_price
			return Nil
		else
			working_amount = (@total_price * 0.3).to_i
			@insurance_fee = (working_amount * 0.5).to_i
			@assistance_fee  = (@days * 100).to_i
			@drivy_fee = working_amount - @insurance_fee - @assistance_fee
		end
	end

	def return_commission()
		calculate_commission()
		if not defined? @drivy_fee
			return Nil
		else
			json_packet = { :insurance_fee => @insurance_fee, :assistance_fee => @assistance_fee, :drivy_fee => @drivy_fee }
			return json_packet
		end
	end

	def return_options()
		json_packet = { :deductible_reduction => @deductible_total_price }
		return json_packet
	end
end

post '/:file_name' do
	cars = []
	rentals = []
	request.body.rewind
	input_hash = JSON.parse(request.body.read)

	input_hash['cars'].each do |car|
		   cars << Car.new(car['id'], car['price_per_day'], car['price_per_km'])
	end

	input_hash['rentals'].each do |rental|
		rentals << Rental.new(rental['id'], rental['car_id'], rental['start_date'], rental['end_date'], rental['distance'], rental['deductible_reduction'])
	end

	output = { 'rentals' => [] }
	rentals.each do |rental|
		output['rentals'] <<  { :id => rental.get_id(), :price => rental.find_car_price(cars), :options => rental.return_options(), :commission => rental.return_commission() }
	end

	output_file = File.open(params['file_name'], 'w')
	output_file.write(JSON.pretty_generate(output))
	output_file.close
end
