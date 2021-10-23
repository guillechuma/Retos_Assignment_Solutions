class Gene
	##
	# This class represents a Gene Objects that
	# has a protein that can interact with other proteins
	##

	# Instance variables
	attr_accessor :id
	# attr_accessor :alt_id # Array
	# attr_accessor :alias # Array
	# attr_accessor :taxonomy_id # Array

	def initialize(params = {})
		@id = params.fetch(:id, nil)
		@alt_id = Array.new
		@alias = Array.new
		@taxonomy_id = 	Array.new
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
