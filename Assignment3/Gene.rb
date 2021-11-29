require 'bio'
require 'rest-client'
# == Gene
#
# This is a representation of a Gene 
# that has features and annotations.
#
# == Summary
# 
# It has a unique ID identifier, represented by Arabidopsis AGI code,
# and also functional annotation from EMBL records.
# All the data was extracted Using EMBL-EBI dbfetch REST API
class Gene

	# Get/Set the Gene ID AGI Code
	# @!attribute [rw] id
	# @return [String] The Gene ID AGI Locus Code
	attr_accessor :id # Unique locus tag ID

	# Get/Set the EMBL record of the Gene ID
	# @!attribute [rw] embl
	# @return [Bio::EMBL] the EMBL record of the Gene ID
	attr_accessor :embl

	# Get/Set the Sequence of the Gene ID
	# @!attribute [rw] sequence
	# @return [Bio::Sequence] the Sequence of the Gene ID
	attr_accessor :sequence

	# Get/Set the Features of the Gene ID
	# @!attribute [rw] features
	# @return [Hash<String, Hash<String, Bio::Feature>>] the features of the Gene ID
	attr_accessor :features

	# Hash that contains all the genes that are created (Class variable)
	# @!attribute [r] all_genes
	# @return [Hash<String, Gene>] A Hash of all the genes created. The key is the Gene ID (AGI Locus Codes) and the value is the Gene Object.
	@@all_genes = Hash.new

	# Create a new instance of Gene object
	# 
	# @param :id [String] The ID: AGI Locus Codes, normalized to upcase letters. IT checks if code is correctly formated.
	# @return [Gene] an instance of Gene.
	def initialize(params = {})

		# Fetch the :id from parameters
		gene_id_code = params.fetch(:id, nil)
		#Validate ID
		# Regex expression of the Gene ID
		gene_id_regex = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
		# Only match codes that follow the regex and have the same lenth as a Gene ID
		unless gene_id_regex.match(gene_id_code) and (gene_id_code.length == 9)
			puts "The Gene ID #{gene_id_code} is not valid" # Print error message
			@id = nil
		else
			@id = gene_id_code # Assign code to instance variable id
			@id = @id.upcase # Normalize to uppercase letters
		end

		# Create an EMBL file of the gene if it does not exists.
		# It is stored in the folder ./embl_records/
		filename = "./embl_records/#{@id}.embl"
		fetch_embl(@id) unless File.file?(filename) # Auxiliary method to fetch the EMBL file

		# Read EMBL file
		# IMPORTANT 
		# I Make the assumption that each file has only one record, since each AGI locus code represents one gene only.
		@embl = read_embl(@id).next_entry # class BIO::EMBL

		# Convert the BIO::EMBL object to Bio::Sequence to include annotations
		# Create a sequence object to annotate it!
		@sequence = @embl.to_biosequence 

		# Hash that has for keys the feature type (in this case the only key is "exon")
		# The values are a hash of features.
		@features = Hash.new

		# Annotate exon features 
		# get_exons_features is an auxiliary method to extract exon features (see method)
		@features["exons"] = get_exons_features

		# Search for CTTCTT repeats and annotate the sequence
		search_annotate_sequence

		# Add the Gene created to the list of Genes
		@@all_genes[@id] = self
	end

	# Auxiliary method to use the EMBL-EBI dbfetch API to retrieve EMBL record of Gene
	#
	# @param id [String] The AGI locus code to search the API 
	# @return [Bio::FlatFile] flat embl record located in ./embl_records
	def fetch_embl(id)
		address = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{id}"
		response = fetch(address)
		record = response.body
		# create a local file with this data
		File.open("./embl_records/#{id}.embl", "w") do |file|  # w makes it writable
			file.puts record
		end
	end
	
	# Auxiliary method to read the EMBL file located in ./embl_records and load it as a Bio::FlatFile object
	#
	# @return [Bio::FlatFile] EMBL record of ID
	def read_embl(id)
		filename = "./embl_records/#{id}.embl"
		return Bio::FlatFile.auto(filename)
	end

	# Extract the exon features from the EMBL record and record them into the @features instance variable.
	# The associated value with key "Note" contains the exon number. That information is used as the key to the 
	# exon Hash.
	#
	# @return [Hash<String, Bio::Feature] a hash of exons as features.
	def get_exons_features

		exon_hash = Hash.new

		# iterates over each element in 'features' # features method finds all features
		@embl.features.each do |feature|
			# FILTER EXON FEATURES
			next unless feature.feature == "exon"

			qual = feature.assoc # Extract associated values of feature

			exon_id_regex = Regexp.new(/exon_id=(#{@id}.*)/i) # The regex to find the exon_id in notes

			# Search for exon number and ID
			if exon_id_regex.match(qual["note"])
				exon_hash[$1] = feature # Use the exon number as key and the exon feature as value
			end
		end
		return exon_hash
	end

	# Search for specific sequences inside the exons of the Gene and annotate them as Bio::Features. 
	# This annotation is strand-aware (It annotates sequence in forward and reverse strand).
	# Also, the method is aware of the possibility of overlapping of sequences and detects them correctly.
	# This method has been abstracted so that you can search and annotate any feature
	# and give it your name. By default it searches for the repeat cttctt and names it repeat,
	# but it works for any valid sequence of interest.
	#
	# @param feature_name [String] The name of the feature that represents the sequence to search for
	# @param sequence [String] The sequence you want to search inside the exons and annotate.
	# @return [Array<Bio::Feature>] append found features to the Bio::Sequence object of the Gene.
	def search_annotate_sequence(feature_name = 'repeat', sequence = 'cttctt')
		# Convert the sequence query String to a Bio::Sequence::NA object
		sequence = Bio::Sequence::NA.new(sequence)
		# Create a regex for the sequence.
		# IMPORTANT: the term (?=) means positive lookahead. It searches for the sequence
		# before it reaches the string. This way it is aware of overlapping sequences.
		# eg. CTTCTTCTT In this case there are two instances of CTTCTT.
		sequence_regex = Regexp.new(/(?=#{sequence})/i)
		# Create the same regex for the reverse complement of the sequence
		# This searches for the pattern in the reverse strand
		reverse_sequence_regex = Regexp.new(/(?=#{sequence.complement})/i)

		# Position array to avoid repetition of transcripts
		position_array = Array.new
		# Iterate over each exon of the Gene
		@features['exons'].each do |exon_id, exon|
			# Retrieve the sequence of the exon
			seq = @sequence.splicing(exon.position)
			# Get all matches of sequence in the string.
			# This line of code was adapted from StackOverflow.
			# URL: https://stackoverflow.com/questions/80357/how-to-match-all-occurrences-of-a-regex
			matches = seq.to_enum(:scan, sequence_regex).map {Regexp.last_match}
			# TO adjust positions relative to sequence!!
			# Get starting and ending positions of the exon.
			# Put coordinates relative to the Gene sequence, not the exon.	
			from, to = exon.locations.span
			if matches # If there is a match
				matches.each do |match| # Go trough each match
					# Set the forward position relative to the gene
					position = "#{match.offset(0)[0] + 1 + from - 1}..#{match.offset(0)[0] + from - 1 + 6}"
					next if position_array.include? position # Next if the position has been found by another transcript
					position_array << position # Append from position to array
					repeat_ft = Bio::Feature::new(feature_name, position) # Create new feature object
            		repeat_ft.append(Bio::Feature::Qualifier.new('note', exon_id)) #Append the exon id as a Qualifier of the feature
					@sequence.features << repeat_ft # Append the new feature to the features of the sequence of the Gene.
				end
			end
			# Same procedure as before but with the reverse complement as regex.
			# This line of code was adapted from StackOverflow.
			# URL: https://stackoverflow.com/questions/80357/how-to-match-all-occurrences-of-a-regex
			rev_matches = seq.to_enum(:scan, reverse_sequence_regex).map {Regexp.last_match}
			if rev_matches
				rev_matches.each do |match|
					# Note that the position is specified that it is on the reverse strand.
					position = "complement(#{match.offset(0)[0] + 1 + from - 1}..#{match.offset(0)[0] + from - 1 + 6})"
					next if position_array.include? position # Next if the position has been found by another transcript
					position_array << position # Append from position to array
					rev_repeat_ft = Bio::Feature::new(feature_name , position)
					rev_repeat_ft.append(Bio::Feature::Qualifier.new('note', exon_id))
					@sequence.features << rev_repeat_ft
			   end
			end
		end
	end

	# Report showing which Genes do not have the CTTCTT repeat.
	#
	# @return [String] a report of the exons without the CTTCTT repeat.
	def write_report
		# repeats_array = Array.new # Create an array of repeat features
		# Go through all the features of the sequence gene
		@sequence.features.each do |feature|
			# Only use repeat features
			next unless feature.feature == 'repeat'
			# repeats_array << feature.assoc['note'] # Append that repeat to the array
			return '' # case if there is a repeat
		end
		# Remove duplicates (an exon can have many repeats)	
		# repeats_array = repeats_array.uniq

		# report_string = String.new # This will be the return value
		# # Find those exons that do not have repeats  
		# exons_not_repeat = @features["exons"].keys - repeats_array.uniq
		# # If exons_not_repeat empty, all exons have repeat
		# unless exons_not_repeat.empty?
		# 	# Gene ID as header	
		# 	report_string += "Gene ID: #{@id}\n"
		# 	report_string += exons_not_repeat.join("\n")
		# 	report_string += "\n\n"
		# end
		return "#{@id}\n"
	end

	# Class Method to get all the created Gene objects.
	#
	# @return [Hash<String, Gene>] the class variable all_genes.
	def Gene.all_genes
		return @@all_genes
	end

	# Overwrite the == method to compare genes by AGI Locus Codes (ID)
	#
	# @param other [Gene] A Gene object to compare.
	# @return [Boolean]. True if Genes are the same, false if not.
	def ==(other)
		self.id == other.id
	end

	# Overwrite the to_s method to print genes by AGI Locus Codes (ID)
	#
	# @return [String]. The Gene ID.
	def to_s
		return @id
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
