require './Gene.rb'
class Interaction
	## 
	# This class represents an interaction between two
	# proteins, abstracted in the Gene class. 
	# This class has all information in the Tab25 file 
	# It represents a binary interaction between two gene objects.
	##
	attr_accessor :interactorA # Gene object
	attr_accessor :interactorB # Gene object

	def initialize(params={})
		@interactorA = params.fetch(:interactorA, Gene.new())
		@interactorB = params.fetch(:interactorB, Gene.new())
		@int_detection_method = Array.new # Interaction detection method
		@int_type = Array.new # Interaction type
		@source_db = Array.new # source databases
		@interaction_id = Array.new
		@confidence = Array.new # Confidence score
	end

	def int_detection_method
		return @int_detection_method
	end

	def int_detection_method=(new_int_detection_method)
		@int_detection_method |= new_int_detection_method
	end

	def int_type
		return @int_type
	end

	def int_type=(new_int_type)
		@int_type |= new_int_type
	end

	def source_db
		return @source_db
	end

	def source_db=(new_source_db)
		@source_db |= new_source_db
	end

	def interaction_id
		return @interaction_id
	end

	def interaction_id=(new_interaction_id)
		@interaction_id |= new_interaction_id
	end

	def confidence
		return @confidence
	end

	def confidence=(new_confidence)
		@confidence |= new_confidence
	end

end