# == Gene
#
# This is a representation of a Gene
# that can interact with other genes.
#
# == Summary (what to use the object for)
# 
# It has a unique ID identifier, and also functional annotation 
# about it.
#
class Gene
	##
	# This class represents a Gene Objects that
	# has a protein that can interact with other proteins
	##

	# Get/Set the Gene ID
	# @!attribute [rw] (read/write)
	# @return [String] The Gene ID
	attr_accessor :id # Unique locus tag ID


	attr_accessor :go # Hash
	attr_accessor :kegg # Array
	# attr_accessor :alt_id # Array
	# attr_accessor :alias # Array
	# attr_accessor :taxonomy_id # Array
	@@all_genes = Hash.new

	def initialize(params = {})
		@id = params.fetch(:id, 'nil')
		@id = @id.upcase
		@alt_id = Array.new
		@alias = Array.new
		@taxonomy_id = 	Array.new
		#@go = find_GO
		#@kegg = find_KEGG
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

			go_data["GO"].each do |annotation|

				# Filter by experimental evidence. IDA(Direct Assay), IMP (Mutual phenotype)
				next unless (annotation[2].match(/IDA\:/) or annotation[2].match(/^IMP\:/) or annotation[2].match(/^IPI\:/)) and annotation[1].match(/^P\:(.*)/)
				go_hash[annotation[0]] = $1.to_s
				# next unless annotation[2].match(/IDA\:(.*)/) or annotation[2].match(/IMP\:(.*)/)
				# puts annotation[0] + "      " + $1
				#puts annotation
			end
		end
		return go_hash
	end

	# Retrieve KEGG pathway
	def find_KEGG

	end

	def all_names
		return id + " " + @alt_id.join(" ") + @alias.join(" ")
	end

	def alt_id
		return @alt_id
	end

	def alt_id=(new_alt_id)
		@alt_id |= new_alt_id
	end

	def alias
		return @alias
	end

	def alias=(new_alias)
		@alias |= new_alias
	end

	def taxonomy_id
		return @taxonomy_id
	end

	def taxonomy_id=(new_taxonomy_id)
		@taxonomy_id |= new_taxonomy_id
	end

end
