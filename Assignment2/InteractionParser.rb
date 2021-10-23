require './Interaction.rb'

class InteractionParser
	##
	# This class represents a Parser for a set of Interactions of a Gene object
	# It creates all Interaction Objects for every pair of interaction with
	# all its properties.
	##

	attr_accessor :tab25_data
	def initialize(params={})
		@tab25_data = params.fetch(:tab25_data, '')

		@interactions = create_interactions() # Array of all the interaction objects
	end

	def create_interactions()
		interactions = Array.new
		data = @tab25_data.split("\n")
		data.each do |line|
			interaction = create_interaction(line)
			interactions << interaction
		end

		return interactions
	end

	def interactions
		return @interactions
	end

	def create_interaction(line)
		# Create an array of all the columns
		# TODO: verify that line is not null and len is ok	
		id_a, id_b, alt_id_a, alt_id_b, al_a, al_b, int_met, fist_a, id_pub, tax_a, tax_b, int_type, source_db, int_id, int_score = line.split("\t")
		# LAbel regex:([^\|]\S*?):(.*?)(?:\(.*?\)|\||$)
		line_regex = /\S*?:(.*?)(?:\(.*?\)|\||$)/i
		id_a = id_a.scan(line_regex).flatten[0]
		id_b = id_b.scan(line_regex).flatten[0]
		alt_id_a = alt_id_a.scan(line_regex).flatten
		alt_id_b = alt_id_b.scan(line_regex).flatten
		al_a = al_a.scan(line_regex).flatten
		al_b = al_b.scan(line_regex).flatten
		int_met = int_met.scan(line_regex).flatten
		tax_a = tax_a.scan(line_regex).flatten
		tax_b = tax_b.scan(line_regex).flatten
		int_type = int_type.scan(line_regex).flatten
		source_db = source_db.scan(line_regex).flatten
		int_id = int_id.scan(line_regex).flatten
		int_score = int_score.scan(line_regex).flatten

		# Create Proteins
		protein_a = Gene.new(id: id_a)
		protein_b = Gene.new(id: id_b)

		# Set attributes of Proteins
		protein_a.alt_id = alt_id_a
		protein_a.alias = al_a
		protein_a.taxonomy_id = tax_a

		protein_b.alt_id = alt_id_b
		protein_b.alias = al_b
		protein_b.taxonomy_id = tax_b

		# Create interactor object
		interactor = Interaction.new(interactorA: protein_a, interactorB: protein_b)

		# Set attribures of Interactor
		interactor.int_detection_method = int_met
		interactor.int_type = int_type
		interactor.source_db = source_db
		interactor.interaction_id = int_id
		interactor.confidence = int_score

		return interactor
	end
end