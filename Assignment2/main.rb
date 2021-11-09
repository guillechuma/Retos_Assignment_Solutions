require './InteractionNetwork.rb'

###
# Main program of the Interaction Network solution
###

# Command line arguments (should be two)
input_array = ARGV

# Check if CL arguments are two
if input_array.empty? or (input_array.length != 2) then 
	$GENE_FILE = 'ArabidopsisSubNetwork_GeneList.txt'
	$NET_REPORT = 'NetworksReport.txt'
else
	# Case where there are command line arguments
	$GENE_FILE = input_array[0]
	$NET_REPORT = input_array[1]
end

# Put on stdout the progress of program
puts 'Creating networks'

# Create an interaction network
network = InteractionNetwork.new(gene_file: $GENE_FILE)

puts 'Created networks'

puts "Creating Network Report"

# Create a report 
network.create_report($NET_REPORT)

puts "Created Network Report"
puts "End of program"