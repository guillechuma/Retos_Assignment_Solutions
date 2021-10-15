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
	        stock_data[seed_stock_id] = SeedStock.new(
	        	seed_stock_id: seed_stock_id,
	        	mutant_gene_id: gene_id,
	        	last_planted: last_planted,
	        	storage: storage,
	        	grams_remaining: grams_remaining
	        	)
	    end
	}
	end

	def get_seed_stock(seed_stock_id)
		return @stock_data[seed_stock_id]
	end


end
 