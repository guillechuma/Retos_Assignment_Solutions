class GraphNode

	attr_accessor :value # Must be a Gene object!
	attr_accessor :neighbors

	def initialize(params = {})
		@value = params.fetch(:value, "")
		@neighbors = Array.new
	end

	def add_edge(neighbor)
		@neighbors << neighbor
	end
end