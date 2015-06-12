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

	attr_reader :car_id
	attr_reader :price_per_day
	attr_reader :price_per_km

end

class RentalModification
	def initialize(id, rental_id, start_date, end_date, distance, deductible_reduction)
		@id = id
		@rental_id = rental_id
		@car_id = car_id
		@start_date = start_date
		@end_date = end_date
		@distance = distance
		@deductible_reduction = deductible_reduction
	end

	attr_reader :id
	attr_reader :rental_id
	attr_reader :car_id
	attr_reader :start_date
	attr_reader :end_date
	attr_reader :distance
	attr_reader :deductible_reduction
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
		@adjustments = []
		@adjustment_id = nil
		@adjustment_length = 0
	end

	attr_reader :id
	attr_reader :days
	attr_reader :distance
	attr_reader :adjustment_id
	attr_reader :adjustment_length

	def add_rental_adjustments(adjustment_array)
		raise ArgumentError, 'adjustment_array is not Array' unless adjustment_array.is_a? Array
		adjustment_array.each do |adj|
			if adj.rental_id == @id then
				@adjustments << adj
				@adjustment_id = adj.id
				@adjustment_length = @adjustment_length + 1
			end
		end
	end

	def find_car_price(car_array)
		raise ArgumentError, 'car_array is not Array' unless car_array.is_a? Array
		car_array.each do |car|
			if car.car_id == @car_id then
				ten_percent_rate = (car.price_per_day - (car.price_per_day * 0.1)).to_i
				thirty_percent_rate = (car.price_per_day - (car.price_per_day * 0.3)).to_i
				fifty_percent_rate = (car.price_per_day - (car.price_per_day * 0.5)).to_i
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
				@total_price = (@distance * car.price_per_km).to_i + (fifty_days * fifty_percent_rate).to_i + (thirty_days * thirty_percent_rate).to_i + (ten_days * ten_percent_rate).to_i + (remaining_days * car.price_per_day).to_i
			end
		end
		return @total_price
	end

	def calculate_commission()
		if not defined? @total_price
			return nil
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
			return nil
		else
			json_packet = { :insurance_fee => @insurance_fee, :assistance_fee => @assistance_fee, :drivy_fee => @drivy_fee }
			return json_packet
		end
	end

	def return_options()
		json_packet = { :deductible_reduction => @deductible_total_price }
		return json_packet
	end

	def generate_transaction_message(who, type, amount)
		json_packet = { :who => who, :type => type, :amount => amount }
	end

	def generate_transactions()
		if not defined? @drivy_fee
			return nil
		else
			json_packet = [ generate_transaction_message("driver", "debit", (@total_price + @deductible_total_price).to_i),
		   			generate_transaction_message("owner", "credit", (@total_price - @insurance_fee - @assistance_fee - @drivy_fee).to_i),
					generate_transaction_message("insurance", "credit", @insurance_fee),
					generate_transaction_message("assistance", "credit", @assistance_fee),
					generate_transaction_message("drivy", "credit", (@drivy_fee + @deductible_total_price).to_i) ]
			return json_packet
		end
	end

	def calculate_rental_modifications(car_array)
		raise ArgumentError, 'car_array is not Array' unless car_array.is_a? Array
		if (@adjustments.length > 0) and (defined? @drivy_fee) then
			old_driver_debit = (@total_price + @deductible_total_price).to_i
			old_owner_credit = (@total_price - @insurance_fee - @assistance_fee - @drivy_fee).to_i
			old_insurance_credit = @insurance_fee
			old_assistance_credit = @assistance_fee
			old_drivy_credit = (@drivy_fee + @deductible_total_price).to_i
			@adjustments.each do |adj|
				if not adj.start_date.nil? then
					@start_date = Date.parse(adj.start_date, "%Y-%m-%d")
				end
				if not adj.end_date.nil? then
					@end_date = Date.parse(adj.end_date, "%Y-%m-%d")
				end
				if not adj.distance.nil? then
					@distance = adj.distance
				end
				@days = @end_date - @start_date + 1				
				if not adj.deductible_reduction.nil? then
					@deductible_reduction = adj.deductible_reduction
				end
				if @deductible_reduction == true then
					@deductible_total_price = (400 * @days).to_i
				else 
					@deductible_total_price = 0
				end
			end
			find_car_price(car_array)
			calculate_commission()
			driver_adj = old_driver_debit - (@total_price + @deductible_total_price).to_i
			owner_adj  = old_owner_credit - (@total_price - @insurance_fee - @assistance_fee - @drivy_fee).to_i
			insurance_adj = old_insurance_credit - @insurance_fee
			assistance_adj = old_assistance_credit - @assistance_fee
			drivy_adj = old_drivy_credit - (@drivy_fee + @deductible_total_price).to_i
			json_packet = [] 
			if driver_adj > 0 then
				json_packet << generate_transaction_message("driver", "credit", driver_adj.abs)
			else
				json_packet << generate_transaction_message("driver", "debit", driver_adj.abs)
			end
			if owner_adj > 0 then
				json_packet << generate_transaction_message("owner", "debit", owner_adj.abs)
			else
				json_packet << generate_transaction_message("owner", "credit", owner_adj.abs)
			end
			if insurance_adj > 0 then
				json_packet << generate_transaction_message("insurance", "debit", insurance_adj.abs)
			else
				json_packet << generate_transaction_message("insurance", "credit", insurance_adj.abs)
			end
			if assistance_adj > 0 then
				json_packet << generate_transaction_message("assistance", "debit", assistance_adj.abs)
			else
				json_packet << generate_transaction_message("assistance", "credit", assistance_adj.abs)
			end
			if drivy_adj > 0 then
				json_packet << generate_transaction_message("drivy", "debit", drivy_adj.abs)
			else
				json_packet << generate_transaction_message("drivy", "credit", drivy_adj.abs)
			end
		
			return json_packet

		else
			return nil
		end
	end
end

cars = []
rentals = []
modifications = []
input = File.read("data.json")
input_hash = JSON.parse(input)

input_hash['cars'].each do |car|
	   cars << Car.new(car['id'], car['price_per_day'], car['price_per_km'])
end

input_hash['rentals'].each do |rental|
	rentals << Rental.new(rental['id'], rental['car_id'], rental['start_date'], rental['end_date'], rental['distance'], rental['deductible_reduction'])
end

input_hash['rental_modifications'].each do |rental_mod|
	modifications << RentalModification.new(rental_mod['id'], rental_mod['rental_id'],  
						rental_mod['start_date'], rental_mod['end_date'], rental_mod['distance'], rental_mod['deductible_reduction'])
end

output = { 'rental_modifications' => [] }
rentals.each do |rental|
	rental.find_car_price(cars)
	rental.calculate_commission()
	rental.add_rental_adjustments(modifications)
	if rental.adjustment_length > 0 then	
		output['rental_modifications'] <<  { :id => rental.adjustment_id, :rental_id => rental.id, :actions => rental.calculate_rental_modifications(cars) }
	end
end

output_file = File.open("my_output.json", 'w')
output_file.write(JSON.pretty_generate(output))
output_file.close

