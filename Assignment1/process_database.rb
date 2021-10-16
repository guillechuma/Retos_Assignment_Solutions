# Import the other Classes used in the main script
require './Gene.rb'
require './HybridCross.rb'
require './SeedStock.rb'
require './StockDatabase.rb'

# Global variables
# Get the command line arguments
input_array = ARGV
# Case where there are no command line arguments or not enough
if input_array.empty? or (input_array.length != 4) then 
	$STOCK_FILE = './seed_stock_data.tsv'
	$CROSS_FILE = './cross_data.tsv'
	$GENE_FILE = './gene_information.tsv'
	$OUTPUT_FILE = 'new_stock_file.tsv'
else
	# Case where there are command line arguments
	$GENE_FILE = input_array[0]
	$STOCK_FILE = input_array[1]
	$CROSS_FILE = input_array[2]
	$OUTPUT_FILE = input_array[3]
end

### TASK 1
# Create a new seed stock database
database = StockDatabase.new

# Fill database with tsv file stock data
database.load_from_file($STOCK_FILE) # BONUS

# Simulate planting 7 grams of seed from the stock database
database.plant_seed(7) # BONUS

# Write the updated database to a new tsv file
database.write_database($OUTPUT_FILE) # BONUS

## Prepare database for TASK 2
# Add Gene data information to the stock database
# Read the gene file line by line
IO.foreach($GENE_FILE, $/).with_index { |record,line_number| 
	# Skip header line
	if line_number > 0 then

	    # Split line values by the tab
	    line = record.split("\t") 

	    # Go though each field of the line
	    gene_id = line[0] # First field is gene ID
	    gene_name = line[1] # Second field is the gene name
	    mutant_phenotype = line[2] # Third field is the description of the mutant phenotype
	    
	    # Create a Gene class for every record 
	    new_gene = Gene.new(gene_id: gene_id,
					    	gene_name: gene_name,
					    	mutant_phenotype: mutant_phenotype)

	    # Assign the Gene Object to the corresponding stock record (Where Gene ID is the same)
	    database.get_seed_stock_by_gene_id(gene_id).gene = new_gene
	end
}

### TASK 2

# Create a Data Structure that has the seed cross data
cross_data = Array.new

#Read cross data and iterate every line
IO.foreach($CROSS_FILE, $/).with_index { |record, line_number|
	# Skip header line
	if line_number > 0 then
		# Split line values by the tab
        line = record.split("\t") 

        # Go though each field of the line
        parent1_id = line[0]
        parent2_id = line[1]
        f2_wild = line[2]
        f2_p1 = line[3]
        f2_p2 = line[4]
        f2_p1p2 = line[5]
        
        # Create a HybridCross class for every record 
        # and store it in cross_data array
        cross_data << HybridCross.new(
        	parent1_id: parent1_id,
        	parent2_id: parent2_id,
        	parent1: database.get_seed_stock(parent1_id).gene,
        	parent2: database.get_seed_stock(parent2_id).gene,
        	f2_wild: f2_wild.to_i,
        	f2_p1: f2_p1.to_i,
        	f2_p2: f2_p2.to_i,
        	f2_p1p2: f2_p1p2.to_i
        	)
	end
}

# Test chi_square on hybrid cross data

# Go through each HybridCross to perform a Chi Square test
cross_data.each {|h_cross|

	# Make the chi Square test on each cross
	x_2 = h_cross.chi_square

	# Degrees of freedom is 3
	# For p value = 0.05, the Chi-square dist is 7.815
	if x_2 > 7.815 then
		# Case where p value < 0.05, there is statistical significance
		# meaning the genes are linked

		# Access the gene data structure with each key
		# And assign the other gene to the linked_to property
		h_cross.parent1.linked_to = h_cross.parent2
		h_cross.parent2.linked_to = h_cross.parent1
		puts "Recording: #{h_cross.parent1.gene_name} is genetically linked to #{h_cross.parent2.gene_name} with chisquare score #{h_cross.chi_square.to_s}"
	end

}

# Print a final report with the linked genes
puts "Final Report:"

database.stock_data.each_value { |stock|

	# Retrieve the gene of each stock
	gene = stock.gene

	# The property linked_to is empty if genes are not linked,
	# Skip empty linked_to
	unless gene.linked_to.empty?
		# Print statement of linked genes
		puts "#{gene.gene_name} is linked to #{gene.linked_to[0].gene_name}"
	end
}
puts

# Bonus code
puts '-'*20
puts
puts 'BONUS'
puts 'Testing that the Gene class accepts correct Gene ID'

Gene.new(
	gene_id: 'AT1G69120A', # Wrong gene ID
    gene_name: 'ap1',
    mutant_phenotype: "meristems replace first and second whorl")

puts
#method to get a seed stock record by ID
puts 'Retrieve seed stock by its ID in database'
puts database.get_seed_stock('A348').seed_stock_id
