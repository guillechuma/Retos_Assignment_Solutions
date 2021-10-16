class Gene
	##
	# This class represents a Gene Objects
	##

	# Instance variables
	attr_accessor :gene_id
	attr_accessor :gene_name
	attr_accessor :mutant_phenotype

	def initialize(params = {})
		@gene_name = params.fetch(:gene_name, "None")
		@mutant_phenotype = params.fetch(:mutant_phenotype, "None")
		@linked_to = Array.new 	# This instance variable is another Gene Object, when the Genes are genetically linked
								# It is an array because a Gene can be linked to many genes (one to many relation)

		#Validate geneID
		gene_id_code = params.fetch(:gene_id, "None")
		# Regex expression of the Gene ID
		gene_id_regex = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
		# Only match codes that follow the regex and have the same lenth as a Gene ID
		unless gene_id_regex.match(gene_id_code) and (gene_id_code.length == 9)
			puts "The Gene ID #{gene_id_code} is not valid"
			@gene_id = "None"
		else
			@gene_id = gene_id_code
		end

	end

	# Method to retrieve the Genes that are linked with self
	def linked_to
		return @linked_to
	end

	# Append the Genes that are linked to self to a list
	def linked_to=(newvalue)
		# Validate that linked to value is a Gene object
		if newvalue.is_a?(Gene) then
			@linked_to << newvalue
		else
			puts "#{newvalue} is not a gene"
		end
	end
end
