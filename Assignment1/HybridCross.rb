require './Gene.rb'

class HybridCross
	##
	# This class represents a Hybrid Cross between two parents.
	# It contains information about the F2 offspring and the amount of seeds 
	# With phenotypes equal to the wild tipe, the parent1 mutation, the parent2 mutation
	# or both parents mutations.
	##

	attr_accessor :parent1_id
	attr_accessor :parent2_id
	attr_accessor :parent1 # This instance variable is a Gene Object of the parent1 
	attr_accessor :parent2 # This instance variable is a Gene Object of the parent2
	attr_accessor :f2_wild
	attr_accessor :f2_p1
	attr_accessor :f2_p2
	attr_accessor :f2_p1p2
	attr_accessor :total_f2

	# Initialize all instance variables
	def initialize(params = {})
		@parent1_id = params.fetch(:parent1_id, 'None')
		@parent2_id = params.fetch(:parent2_id, 'None')
		@f2_wild = params.fetch(:f2_wild, 0)
		@f2_p1 = params.fetch(:f2_p1, 0)
		@f2_p2 = params.fetch(:f2_p2, 0)
		@f2_p1p2 = params.fetch(:f2_p1p2, 0)

		# Validate that parent1 and parent2 are Gene objects
		gene1 = params.fetch(:parent1, "None")
		if gene1.is_a?(Gene) then
			@parent1 = gene1
		else
			@parent1 = "None"
		end

		gene2 = params.fetch(:parent2, "None")
		if gene2.is_a?(Gene) then
			@parent2 = gene2
		else
			@parent1 = "None"
		end

		# Create an instance variable that represents the total amount of offspring of the F2
		@total_f2 = f2_wild + f2_p1 + f2_p2 + f2_p1p2
	end


	# Auxiliary method: Make the Chi Square test for the F2 of the parent seeds
	def chi_square
		# Expected values of F2 with the ratio 9:3:3:1
		expected_wild = @total_f2 * (9.0 / 16)
		expected_p1 = @total_f2 * (3.0 / 16)
		expected_p2 = @total_f2 * (3.0 / 16)
		expected_p1p2 = @total_f2 * (1.0 / 16)
		
		# The chi square of each variable
		chi_wt = ((@f2_wild - expected_wild)**2) / expected_wild
		chi_p1 = ((@f2_p1 - expected_p1)**2) / expected_p1
		chi_p2 = ((@f2_p2 - expected_p2)**2) / expected_p2
		chi_p1p2 = ((@f2_p1p2 - expected_p1p2)**2) / expected_p1p2

		# The final chi_square value of the F2
		x_2 = chi_wt + chi_p1 + chi_p2 + chi_p1p2

		return x_2
	end


end
