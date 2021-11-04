require './InteractionParser'
require 'rgl/adjacency'
require 'rgl/dot'

class InteractionNetwork

	def initialize(params={})
		@gene_file = params.fetch(:gene_file, nil)
		@all_genes = Hash.new
		@id_list = Array.new
		create_genes
		@network = RGL::AdjacencyGraph.new
		#@network.add_edge(@all_genes["AT4g27030"], @all_genes["AT5g54270"])
		create_network
	end

	def create_genes
		genes = File.open(@gene_file,'r')

		genes.readlines.each do |locus_tag|
			locus_tag.strip!
			locus_tag = locus_tag.upcase
			@all_genes[locus_tag] = Gene.new(id: locus_tag)
			@id_list << locus_tag
		end
	end

	def network
		return @network.to_s
	end

	def get_all_genes
		return @all_genes
	end

	def get_gene(locus_tag)
		return @all_genes[locus_tag]
	end

	def interact(geneA, geneB)
		# inter_geneA = InteractionParser.new(locus_id: geneA.id)
		# if inter_geneA.interactions
		# 	inter_geneA.interactions.each do |genes_1|
		# 		genes_1[0] == geneA.id ? other_1 = genes_1[1] : other_1 = genes_1[0]

		# 		if @id_list.include? other_1
	end

	def save_network
		return @network.print_dotted_on
	end

	def create_network
		@all_genes.each do |locus_tag, gene_lvl1|
			inter_lvl1 = InteractionParser.new(locus_id: locus_tag)
			if inter_lvl1.interactions # Check if there is indeed an interaction
				inter_lvl1.interactions.each do |genes_1|
					genes_1[0] == locus_tag ? other_1 = genes_1[1] : other_1 = genes_1[0]

					# See if the network has made the reverse connection
					#next if @network.has_edge?(Gene.all_genes[other_1], Gene.all_genes[locus_tag])

					# Of the other gene is already on the list, no need to look further
					if @id_list.include? other_1
						# puts 'lvl1'
						# puts locus_tag + "\t" + other_1
						# puts
						@network.add_edge(Gene.all_genes[locus_tag], Gene.all_genes[other_1]) unless @network.has_edge?(Gene.all_genes[locus_tag], Gene.all_genes[other_1])
						next
					end
					inter_lvl2 = InteractionParser.new(locus_id: other_1)
					if inter_lvl2.interactions # Check if there is indeed an interaction
						inter_lvl2.interactions.each do |genes_2|
							genes_2[0] == other_1 ? other_2 = genes_2[1] : other_2 = genes_2[0]

							if @id_list.include? other_2 and (other_2 != locus_tag)
								# Create gene for other 1 if it does not exist
								unless Gene.all_genes.has_key?(other_1)
									#puts "creating new gene #{other_1}"
									Gene.new(id: other_1)
								end
								# puts 'lvl2'
								# puts locus_tag + "\t" + other_1 + "\t" + other_2
								# puts
								@network.add_edge(Gene.all_genes[locus_tag], Gene.all_genes[other_1]) unless @network.has_edge?(Gene.all_genes[locus_tag], Gene.all_genes[other_1])
								@network.add_edge(Gene.all_genes[other_1], Gene.all_genes[other_2]) unless @network.has_edge?(Gene.all_genes[other_1], Gene.all_genes[other_2])
							end
						end
					end
				end
			end
		end
	end
end