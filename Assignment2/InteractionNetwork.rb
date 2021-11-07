require './InteractionParser'
require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/connected_components'

class InteractionNetwork

	attr_accessor :network_list

	def initialize(params={})
		@gene_file = params.fetch(:gene_file, nil)
		@all_genes = Hash.new
		@id_list = Array.new
		create_genes
		@all_networks = RGL::AdjacencyGraph.new
		#@all_networks.add_edge(@all_genes["AT4g27030"], @all_genes["AT5g54270"])
		# Create all networks
		@all_genes.each_key do |locus_tag|
			create_all_networks_recursive(locus_tag, locus_tag, 3)
		end

		annotate_networks # Annotate all genes in the networks with KEGG and GO terms
		# Separate individal networks to a list
		@network_list = Array.new
		separate_networks
		

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

	def all_networks
		return @all_networks
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
		return @all_networks.print_dotted_on
	end

	def annotate_networks
		@all_networks.vertices.each do |gene|
			gene.find_GO
			gene.find_KEGG
		end
	end

	def separate_networks
		@all_networks.each_connected_component { |network|
			net_graph = RGL::AdjacencyGraph.new
			network.each { |gene| 
				@all_networks.adjacent_vertices(gene).each { |adjacent| 
					net_graph.add_edge(gene, adjacent)
				}
			}
			@network_list << net_graph
		}
	end

	def create_report(filename)
		File.open(filename, 'w') { |file|
			net_count = 1
			file.write("Network Report\n")
			file.write("By Guillermo Chumaceiro\n\n")
			file.write("The networks are formed by the arabidopsis genes defined in #{@gene_file},")
			file.write("I used the IntAct database to search meaningful interactions between this genes. The depth of the search is")
			file.write("of 3 genes, taking into acount the possibility of intermediary genes not in the list that interact with two genes on the")
			file.write("list. The interactions where filtered by the taxonomy ID of arabidopsis and the quality value of the interaction. I decided ")
			file.write("to consider interactions with quality values >= 0.4.\n")
			file.write("Each network is annotated by the KEGG pathways and GO terms associated with biological process of the genes of each network.")
			file.write("The GO terms are filtered by evidence: IDA(Inferred from Direct Assay), IMP(Inferred from Mutant Phenotype) and IPI(Inferred from Physical Interaction).\n")
			file.write("The following report is a summary of each network and the annotation of the genes in that network.\n")
			@network_list.each do |network|
				file.write("-"*50)
				file.write("\n")
				file.write("Network #{net_count}\n")
				file.write("The network has #{network.vertices.length} genes:\n")
				file.write(network.vertices.join(" "))
				file.write("\n")
				file.write("\n")
				file.write("The global KEGG pathways the genes in this network are involved in are:\n")
				kegg_hash = network_kegg(network)
				kegg_hash.each do |kegg_id, pathway|
					file.write("KEGG ID: #{kegg_id} with the pathway: #{pathway}\n")
				end

				file.write("\n")
				file.write("The Biological processes the genes in this network participate in are:\n")
				go_hash = network_go(network)
				go_hash.each do |go_id, go_term|
					file.write("GO ID: #{go_id} with the biological process: #{go_term}\n")
				end
				
				file.write("\n")
				file.write("The interaction of genes in the network is:\n")
				network.edges.each do |interaction| 
					if @id_list.include? interaction.source.id
						source_text = "Gene ID: #{interaction.source.id}"
					else 
						source_text = "Intermediary Gene ID: #{interaction.source.id}"
					end

					if @id_list.include? interaction.target.id 
						target_text = "Gene ID: #{interaction.target.id}"
					else 
						target_text = "Intermediary Gene ID: #{interaction.target.id}"
					end

					file.write("#{source_text} interacts with #{target_text}\n")
				end
				net_count += 1
				file.write("\n")
			end
			file.write("-"*50)
			file.write("\n")
			file.write("End of report")
		}
	end

	def network_go(network)
		go_terms = Hash.new
		network.vertices.each do |gene|
			go_terms = go_terms.merge(gene.go) unless gene.go.empty?
		end
		return go_terms
	end

	def network_kegg(network)
		kegg_terms = Hash.new
		network.vertices.each do |gene|
			kegg_terms = kegg_terms.merge(gene.kegg) unless gene.kegg.empty?
		end
		return kegg_terms
	end


	def create_all_networks
		@all_genes.each do |locus_tag, gene_lvl1|
			inter_lvl1 = InteractionParser.new(locus_id: locus_tag)
			if inter_lvl1.interactions # Check if there is indeed an interaction
				inter_lvl1.interactions.each do |genes_1|
					genes_1[0] == locus_tag ? other_1 = genes_1[1] : other_1 = genes_1[0]

					# See if the network has made the reverse connection
					#next if @all_networks.has_edge?(Gene.all_genes[other_1], Gene.all_genes[locus_tag])

					# Of the other gene is already on the list, no need to look further
					if @id_list.include? other_1
						# puts 'lvl1'
						# puts locus_tag + "\t" + other_1
						# puts
						@all_networks.add_edge(Gene.all_genes[locus_tag], Gene.all_genes[other_1]) unless @all_networks.has_edge?(Gene.all_genes[locus_tag], Gene.all_genes[other_1])
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
								@all_networks.add_edge(Gene.all_genes[locus_tag], Gene.all_genes[other_1]) unless @all_networks.has_edge?(Gene.all_genes[locus_tag], Gene.all_genes[other_1])
								@all_networks.add_edge(Gene.all_genes[other_1], Gene.all_genes[other_2]) unless @all_networks.has_edge?(Gene.all_genes[other_1], Gene.all_genes[other_2])
							end
						end
					end
				end
			end
		end
	end

	def create_all_networks_recursive(prev_locus_tag,locus_tag, depth)

		# Base case
		if depth == 1
			return
		end

		interaction = InteractionParser.new(locus_id: locus_tag)
		if interaction.interactions
			interaction.interactions.each do |new_int|
				new_int[0] == locus_tag ? other = new_int[1] : other = new_int[0]

				if @id_list.include? other and (other != prev_locus_tag) and (prev_locus_tag != locus_tag)
					Gene.new(id: locus_tag) unless Gene.all_genes.has_key?(locus_tag)
					@all_networks.add_edge(Gene.all_genes[prev_locus_tag], Gene.all_genes[locus_tag]) unless @all_networks.has_edge?(Gene.all_genes[prev_locus_tag], Gene.all_genes[locus_tag])
					@all_networks.add_edge(Gene.all_genes[locus_tag], Gene.all_genes[other]) unless @all_networks.has_edge?(Gene.all_genes[locus_tag], Gene.all_genes[other])
					next
				else
					create_all_networks_recursive(locus_tag, other, depth-1)
				end
			end
		end
	end
end