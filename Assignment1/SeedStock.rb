class SeedStock

	attr_accessor :seed_stock_id
	attr_accessor :mutant_gene_id
	attr_accessor :last_planted
	attr_accessor :storage
	attr_accessor :grams_remaining

	def initialize(params = {})
		@seed_stock_id = params.fetch(:seed_stock_id, "None")
		@mutant_gene_id = params.fetch(:mutant_gene_id, "None")
		@last_planted = params.fetch(:last_planted, "None")
		@storage = params.fetch(:storage, "None")
		@grams_remaining = params.fetch(:grams_remaining, 0)

	end
end