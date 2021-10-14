class HybridCross

	attr_accessor :parent1
	attr_accessor :parent2
	attr_accessor :f2_wild
	attr_accessor :f2_p1
	attr_accessor :f2_p2
	attr_accessor :f2_p1p2

	def initialize(params = {})
		@parent1 = params.fetch(:parent1, 'None')
		@parent2 = params.fetch(:parent2, 'None')
		@f2_wild = params.fetch(:f2_wild, 'None')
		@f2_p1 = params.fetch(:f2_p1, 'None')
		@f2_p2 = params.fetch(:f2_p2, 'None')
		@f2_p1p2 = params.fetch(:f2_p1p2, 'None')

	end

end
