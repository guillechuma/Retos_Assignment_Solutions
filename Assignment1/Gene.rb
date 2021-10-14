class Gene

	attr_accessor :gene_id
	attr_accessor :gene_name
	attr_accessor :mutant_phenotype

	def initialize(params = {})
		@gene_name = params.fetch(:gene_name, "None")
		@mutant_phenotype = params.fetch(:mutant_phenotype, "None")

		gene_id_code = params.fetch(:gene_id, "None")

		#Validate geneID
		gene_id_regex = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
		unless gene_id_regex.match(gene_id_code) and (gene_id_code.length == 9)
			puts "The Gene ID is not valid"
			@gene_id = "None"
		else
			@gene_id = gene_id_code
		end

	end


end
