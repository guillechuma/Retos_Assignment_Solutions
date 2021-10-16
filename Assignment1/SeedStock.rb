require './Gene.rb'

class SeedStock
	##
	# This class represents a seed stock record.
	# Each record has the following information as instance variables.
	##
	attr_accessor :seed_stock_id
	attr_accessor :mutant_gene_id
	attr_accessor :last_planted
	attr_accessor :storage
	attr_accessor :grams_remaining

	# Initialize all instance variables
	def initialize(params = {})
		@seed_stock_id = params.fetch(:seed_stock_id, "None")
		@mutant_gene_id = params.fetch(:mutant_gene_id, "None")
		@last_planted = params.fetch(:last_planted, "None")
		@storage = params.fetch(:storage, "None")
		@grams_remaining = params.fetch(:grams_remaining, 0)
	end

	# The instance variable @gene represents a Gene Object
	def gene
		return @gene
	end

	# The @gene is validated to make sure its value is a Gene object
	def gene=(newvalue)
		if newvalue.is_a?(Gene) then
			@gene = newvalue
		else
			puts "#{newvalue} is not a gene"
		end
	end
end