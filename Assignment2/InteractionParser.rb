require 'rest-client'

# == InteractionParser
#
# This is a Parser for a set of Interactions between proteins information gathered in the IntAct Database.
#
# == Summary
# 
# This object access the data Using the PSIQUIC IntAct REST API.
# It reads all the interactions of a query gene using the AGI Locus ID
# and it filters the interaction by taxonomy of Arabidopsis thaliana
# and by the quality of the interaction with a threshold of 0.4.
class InteractionParser

	# Get/Set the Gene ID AGI Locus Code used as query
	# @!attribute [rw] locus_id
	# @return [String] The Gene ID AGI Locus Code used as query
	attr_accessor :locus_id

	# Create a new instance of InteractionParser object
	# 
	# @param locus_id [String] The ID: AGI Locus Codes, normalized to upcase
	# @param interactions [Array<String>] An array of all the pair of interactions of the query Gene.
	# @return [InteractionParser] an instance of InteractionParser
	def initialize(params={})
		@locus_id = params.fetch(:locus_id, '')
		@interactions = create_interactions # Array of all the interaction objects
	end

	# Read the information of the PSIQUIC IntAct REST API with the Locus ID as query in tab25 format and create the list of interactions.
	#
	# @see https://psicquic.github.io/MITAB25Format.html
	# @return [Array<String>] An array of all the pair of interactions of the query Gene.
	def create_interactions
		# Array of all interactions in file
		interactions = Array.new
		# The PSIQUIC IntAct URL of the query gene in tab25 format.
		url = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{@locus_id}?format=tab25"
		# Check if there is a response
		if res = fetch(url)
			raw_data = res.body # Get the body of the response
			# ASSUMPTION: If the result is empty, that gene does not interact with anything
			return nil if raw_data.length == 0
			# Split the data by line
			data = raw_data.split("\n")
			# Each line is an interaction
			data.each do |line|
				interaction = create_interaction(line) # Parse the interaction
				# Check if nil or not. It may be the case that all interactions does not pass the filters.
				# In that case, it is discarded.
				if interaction
					interactions << interaction # Assign the interaction (GeneID_A, GeneID_B) to the array of interactions
				end
			end
		end
		return interactions
	end

	# Get method for the interactions array
	#
	# @return [Array<String>]. The binary interactions.
	def interactions
		return @interactions
	end

	# Parse and filter an interaction (a line) defined by the tab25 format of the PSIQUIC IntAct REST API database.
	#
	# @see https://psicquic.github.io/MITAB25Format.html
	# @return [Array<String>] An array of all the pair of interactions of the query Gene.
	def create_interaction(line)
		# Assign a variable to each feature of the Tab25 format (separated by \t)
		id_a, id_b, alt_id_a, alt_id_b, al_a, al_b, int_met, fist_a, id_pub, tax_a, tax_b, int_type, source_db, int_id, int_score = line.split("\t")
		# The regex expression to extract the value of each feature, case insensitive
		line_regex = /\S*?:(.*?)(?:\(.*?\)|\||$)/i 
		# The regex expression to extract the AGI Locus Code, case insensitive
		locus_tag_regex =/A[Tt]\d[Gg]\d\d\d\d\d/i
		id_a = id_a.scan(line_regex).flatten[0] # Search for ID of interactor A (IMPORTANT)
		id_b = id_b.scan(line_regex).flatten[0] # Search for ID of interactor B (IMPORTANT)
		alt_id_a = alt_id_a.scan(line_regex).flatten # Search for alternative ID of interactor A (IMPORTANT)
		alt_id_b = alt_id_b.scan(line_regex).flatten # Search for alternative ID of interactor B (IMPORTANT)
		al_a = al_a.scan(line_regex).flatten # Search for alias of interactor A (IMPORTANT)
		al_b = al_b.scan(line_regex).flatten # Search for alias of interactor B (IMPORTANT)
		int_met = int_met.scan(line_regex).flatten # Search for interaction detection method, Could be used as filtered by PI request. In this case we do not filter
		tax_a = tax_a.scan(line_regex).flatten # Search for the Taxonomy ID of interactor A (FILTER)
		tax_b = tax_b.scan(line_regex).flatten # Search for the Taxonomy ID of interactor B (FILTER)
		int_type = int_type.scan(line_regex).flatten # Search for interactor type
		source_db = source_db.scan(line_regex).flatten # Search for source Database
		int_id = int_id.scan(line_regex).flatten # Search for interaction ID
		int_score = int_score.scan(line_regex).flatten # Search for interaction score (FILTER)

		# FILTERS

		# Taxonomy filter. Ara TaxID: 3702
		ara_tax = "3702"
		return nil unless (tax_a.include? ara_tax) and (tax_b.include? ara_tax) # Both interactors must be of Arabidopsis.

		# Quality filter: Threshold of 0.4
		return nil unless int_score[0].to_f >= 0.4

		## FIND LOCUS TAG IN ALL ID's (IT WILL BE UNIQUE ID FOR EACH GENE)
		# Since I don't know a priori where is the AGI Locus Code, I search for all possible ID's
		# That includes the ID, the alternative ID's and the alias.

		# For protein A
		if id_a and alt_id_a and al_a
			# Join all possible ID's
			all_ids_a = id_a + " " + alt_id_a.join(" ")  + " " + al_a.join(" ") 
			# Search for AGI Locus ID
			locus_tag_a = all_ids_a.match(locus_tag_regex)
		end

		# For protein B
		if id_b and alt_id_b and al_b
			# Join all possible ID's
			all_ids_b = id_b + " " + alt_id_b.join(" ") + " " +  al_b.join(" ")
			# Search for AGI Locus ID
			locus_tag_b = all_ids_b.match(locus_tag_regex)
		end

		# IMPORTANT STEP
		# The interaction is only valid if there is an AGI Locus ID defined for both interactors!!!

		unless locus_tag_a 
			return nil # Return nil if no AGI Locus ID for interactor A
		end

		unless locus_tag_b
			return nil # Return nil if no AGI Locus ID for interactor B
		end

		# Check if protein A and protein B are the same
		return nil if locus_tag_a[0].upcase == locus_tag_b[0].upcase

		# Return both AGI Locus ID of interactor A and B
		return locus_tag_a[0].upcase, locus_tag_b[0].upcase
	end
end

# Auxiliary function to fetch a URL correctly.
# 
# @param url [String] The URL to search.
# @return [String] The response for the URL.
def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
	response = RestClient::Request.execute({
	  method: :get,
	  url: url.to_s,
	  user: user,
	  password: pass,
	  headers: headers})
	return response
	
	rescue RestClient::ExceptionWithResponse => e
	  $stderr.puts e.inspect
	  response = false
	  return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
	rescue RestClient::Exception => e
	  $stderr.puts e.inspect
	  response = false
	  return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
	rescue Exception => e
	  $stderr.puts e.inspect
	  response = false
	  return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  end