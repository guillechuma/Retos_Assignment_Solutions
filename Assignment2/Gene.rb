require 'rest-client'
require 'json'  # to handle JSON format

# == Gene
#
# This is a representation of a Gene
# that can interact with other genes.
#
# == Summary
# 
# It has a unique ID identifier, represented by Arabidopsis AGI code,
# and also functional annotation from KEGG and GO databases about it.
# All the data was extracted Using TOGO and the IntAct databases.
class Gene

	# Get/Set the Gene ID AGI Locus Codes
	# @!attribute [rw] id
	# @return [String] The Gene ID AGI Locus Codes
	attr_accessor :id # Unique locus tag ID

	# Get/Set the GO ID
	# @!attribute [rw] go
	# @return [Hash<String, String>] The GO annotations. The key is the ID and the value is the description of the term.
	attr_accessor :go # Hash

	# Get/Set the KEGG ID
	# @!attribute [rw] kegg
	# @return [Hash<String, String>] The KEGG annotations. The key is the ID and the value is the pathway.
	attr_accessor :kegg # Hash

	# Hash that contains all the genes that are created (Class variable)
	# @!attribute [r] all_genes
	# @return [Hash<String, Gene>] A Hash of all the genes created. The key is the Gene ID (AGI Locus Codes) and the value is the Gene Object.
	@@all_genes = Hash.new

	# Create a new instance of Gene object
	# 
	# @param id [String] The ID: AGI Locus Codes, normalized to upcase
	# @param go [Hash<String, String>] The GO annotations. The key is the ID and the value is the description of the term.
	# @param kegg [Hash<String, String>] The KEGG annotations. The key is the ID and the value is the pathway.
	# @return [Gene] an instance of Gene
	def initialize(params = {})

		#Validate ID
		gene_id_code = params.fetch(:id, nil)
		# Regex expression of the Gene ID
		gene_id_regex = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
		# Only match codes that follow the regex and have the same lenth as a Gene ID
		unless gene_id_regex.match(gene_id_code) and (gene_id_code.length == 9)
			puts "The Gene ID #{gene_id_code} is not valid"
			@id = nil
		else
			@id = gene_id_code
			@id = @id.upcase
		end

		@go = Hash.new
		@kegg = Hash.new
		@@all_genes[@id] = self
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

	# Retrieve the GO Biological Process annotation of the Gene using the TOGO REST API
	#	
	# @see http://togows.dbcls.jp
	# @return [Hash<String, String>] The GO Biological Process annotations. The key is the ID and the value is the description of the term.
	def find_GO
		go_hash = Hash.new # Create the hash to store the annotations
		# Use TOGO API to access the uniprot database, search for the Gene(ID), and access the cross-references section in JSON format
		go_address = "http://togows.dbcls.jp/entry/uniprot/#{@id}/dr.json" # dr: cross-references section

		# Check if we can fetch the URL
		if response = fetch(go_address)
			# Parse the response as a JSON object
			go_data = JSON.parse(response.body) # It turns it into a Ruby DS. A list of lists.

			# Access the JSON data, the result is a Hash
			go_data = go_data[0]

			# Check if there is a GO Key in the JSON data
			if go_data.has_key?("GO")
				# Search the GO terms in the reference data of the Gene
				go_data["GO"].each do |annotation|

					# Filter GO terms by Biological Process.
					# next unless (annotation[2].match(/^IDA\:/) or annotation[2].match(/^IMP\:/) or annotation[2].match(/^IPI\:/)) and annotation[1].match(/^P\:(.*)/)
					next unless annotation[1].match(/^P\:(.*)/)
					# Assign the biological proccess (value) to the GO ID (key)
					go_hash[annotation[0]] = $1.to_s
				end
			end
			@go = go_hash # Update the instance variable @go with the annotations
		end
	end

	# Retrieve the KEGG pathway annotation of the Gene using the TOGO REST API.
	#
	# @see http://togows.dbcls.jp
	# @return [Hash<String, String>] The KEGG annotations. The key is the ID and the value is the pathway.
	def find_KEGG
		# Use TOGO API to access the kegg-genes database, search for the Gene(ID), and access the pathways field in JSON format
		address = "http://togows.org/entry/kegg-genes/ath:#{@id}/pathways.json" # kegg-genes
		
		# Check if we can fetch the URL
		if response = fetch(address)
			# Parse the response as a JSON object
			data = JSON.parse(response.body)# It turns it into a Ruby DS. A list of lists.
			
			# Access the JSON data, the result is a Hash
			data = data[0]
			@kegg = data # Update the instance variable @kegg with the annotations
		end
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
    
      # IF there is a problem, you pass the error condition
    rescue RestClient::ExceptionWithResponse => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue RestClient::Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    
      # This is everything
    rescue Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  end 