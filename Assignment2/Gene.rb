require 'rest-client'
require 'json'  # to handle JSON format

# == Gene
#
# This is a representation of a Gene
# that can interact with other genes.
#
# == Summary (what to use the object for)
# 
# It has a unique ID identifier, represented by Arabidopsis AGI code,
# and also functional annotation from KEGG and GO databases about it.
# All the data was extracted Using TOGO and the IntAct databases.

class Gene

	# Get/Set the Gene ID
	# @!attribute [rw] (read/write)
	# @return [String] The Gene ID
	attr_accessor :id # Unique locus tag ID

	# Get/Set the GO ID
	# @!attribute [rw] (read/write)
	# @return [String] The GO ID
	attr_accessor :go # Hash

	# Get/Set the KEGG ID
	# @!attribute [rw] (read/write)
	# @return [String] The KEGG ID
	attr_accessor :kegg # Array
	# attr_accessor :alt_id # Array
	# attr_accessor :alias # Array
	# attr_accessor :taxonomy_id # Array
	@@all_genes = Hash.new

	# Create a new instance of Gene

	# @param name [String] the name of the patient as a String
	# @param age [Integer] the age of the patient as a Integer
	# @return [Patient] an instance of Patient
	def initialize(params = {})
		@id = params.fetch(:id, 'nil')
		@id = @id.upcase
		# @alt_id = Array.new
		# @alias = Array.new
		# @taxonomy_id = 	Array.new
		@go = Hash.new
		@kegg = Hash.new
		@@all_genes[@id] = self
	end

	def self.all_genes
		return @@all_genes
	end

	# Compare genes by locus tag ID
	def ==(other)
		self.id == other.id
	end

	# Represent gene in string
	def to_s
		return @id
	end

	# Retrieve the GO of that gene
	def find_GO
		go_hash = Hash.new
		go_address = "http://togows.dbcls.jp/entry/uniprot/#{@id}/dr.json" # dr: cross-references section

		if response = fetch(go_address)
			go_data = JSON.parse(response.body)# It turns it into a Ruby DS. A list of lists.

			go_data = go_data[0]

			if go_data.has_key?("GO")
				go_data["GO"].each do |annotation|

					# Filter by experimental evidence. IDA(Direct Assay), IMP (Mutual phenotype)
					next unless (annotation[2].match(/IDA\:/) or annotation[2].match(/^IMP\:/) or annotation[2].match(/^IPI\:/)) and annotation[1].match(/^P\:(.*)/)
					go_hash[annotation[0]] = $1.to_s
					# next unless annotation[2].match(/IDA\:(.*)/) or annotation[2].match(/IMP\:(.*)/)
					# puts annotation[0] + "      " + $1
					#puts annotation
				end
			end
			@go = go_hash
		end
		# return nil
	end

	# Retrieve KEGG pathway
	def find_KEGG
		address = "http://togows.org/entry/kegg-genes/ath:#{@id}/pathways.json" # kegg-genes

		if response = fetch(address)
			data = JSON.parse(response.body)# It turns it into a Ruby DS. A list of lists.

			data = data[0]
			@kegg = data
		end
		# return  nil
	end

	# def all_names
	# 	return id + " " + @alt_id.join(" ") + @alias.join(" ")
	# end

	# def alt_id
	# 	return @alt_id
	# end

	# def alt_id=(new_alt_id)
	# 	@alt_id |= new_alt_id
	# end

	# def alias
	# 	return @alias
	# end

	# def alias=(new_alias)
	# 	@alias |= new_alias
	# end

	# def taxonomy_id
	# 	return @taxonomy_id
	# end

	# def taxonomy_id=(new_taxonomy_id)
	# 	@taxonomy_id |= new_taxonomy_id
	# end

end


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