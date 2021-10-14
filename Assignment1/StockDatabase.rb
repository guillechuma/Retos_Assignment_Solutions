require './SeedStock.rb'

class StockDatabase

	def initialize
		@stock_data = Hash.new

	end

	def load_from_file(stock_file)

		# Read the stock file line by line
		IO.foreach(stock_file, $/).with_index { |record,rec_num| 
	    # Skip header line
	    if rec_num > 0 then

	        # Split line values by the tab
	        line = record.split("\t") 

	        # Go though each field of the line
	        seed_stock_id = line[0]
	        gene_id = line[1]
	        last_planted = line[2]
	        storage = line[3]
	        grams_remaining = line[4]
	        
	        # Create a SeedStock class for every record 
	        # and store it in stock_data hash
	        @stock_data[seed_stock_id] = SeedStock.new(
	        	seed_stock_id: seed_stock_id,
	        	mutant_gene_id: gene_id,
	        	last_planted: last_planted,
	        	storage: storage,
	        	grams_remaining: grams_remaining.to_i
	        	)
	    end
	}
	end

	def get_seed_stock(seed_stock_id)
		# This method returns the SeedStock object with 
		# the corresponding seed_stock_id
		return @stock_data[seed_stock_id]
	end

	def write_database(filename)
		# Create a new file with filename
		File.open(filename, 'w') { |file|
			# Write the header file
			file.write("Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining\n")

			# Iterate over the stock_data to write each entry into file
			@stock_data.each_value { |seed_stock|
				# The value var contains a seedStock object
				file.write("#{seed_stock.seed_stock_id}\t#{seed_stock.mutant_gene_id}\t#{seed_stock.last_planted}\t#{seed_stock.storage}\t#{seed_stock.grams_remaining.to_s}\n")

			}

		}
		
	end

	def plant_seed(amount)
		# This method simulates the planting of the amount of seed
		# on all records and updates the database
		@stock_data.each { |seed_id, seed_stock|
			
			# Check if the amount of seed is zero or less than zero
			if seed_stock.grams_remaining - amount <= 0 then
				puts "WARNING: we have run out of Seed Stock #{seed_id}"
				seed_stock.grams_remaining = 0
			else
				# Substract the amount to the grams remaining
				seed_stock.grams_remaining -= amount
			end
		}
	end


end
 