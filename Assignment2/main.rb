require './InteractionNetwork.rb'

input_array = ARGV

if input_array.empty? or (input_array.length != 2) then 
	$GENE_FILE = 'ArabidopsisSubNetwork_GeneList.txt'
	$NET_REPORT = 'NetworksReport.txt'
else
	# Case where there are command line arguments
	$GENE_FILE = input_array[0]
	$NET_REPORT = input_array[1]
end

puts 'Creating networks'

network = InteractionNetwork.new(gene_file: $GENE_FILE)

puts 'Created networks'

puts "Creating Network Report"

network.create_report($NET_REPORT)

puts "Created Network Report"
puts "End of program"