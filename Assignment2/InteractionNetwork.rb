require './InteractionParser'
require './Gene.rb'
require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/connected_components'

# == InteractionNetwork
#
# This represents all the Networks that are formed by all the interactions between a list of Genes.
#
# == Summary
# 
# The network is formed using the information of interactions in the PSIQUIC IntAct REST API.
# It searches the interactions of all genes until a depth level and makes the corresponding networks.
# The Network representation is an undirected graph modeled with the gem library RGL.
# Using graphs we have information of every pair of interactions in the network and also of all the networks that are formed.
class InteractionNetwork

	# Get/Set the list of all networks 
	# @!attribute [rw] network_list
	# @return [Array<RGL::AdjacencyGraph>] A list of an undirected Graph that represents each network of Genes.
	attr_accessor :network_list

	# Create a new instance of InteractionNetwork object
	# 
	# @param gene_file [String] a text file that has the Gene's AGI locus codes (1 per line).
	# @param all_genes [Hash<String, Gene>] A hash of all the genes of gene_file. The key is the AGI locus code and the value is the Gene object.
	# @param id_list [Array<String>] An array of all the AGI locus codes in the gene_file.
	# @param all_networks [RGL::AdjacencyGraph] An undirected graph object that represents the networks. The vertices are Gene Objects.
	# @param network_list [Array<RGL::AdjacencyGraph>] A list of an undirected Graph that represents each network of Genes.
	# @return [InteractionNetwork] an instance of InteractionNetwork
	def initialize(params={})
		@gene_file = params.fetch(:gene_file, nil) # File name
		@all_genes = Hash.new 
		@id_list = Array.new
		create_genes # Fill the @all_genes and @id_list attributes with the genes in gene_file
		@all_networks = RGL::AdjacencyGraph.new # Graph of the network
		# Create all networks
		@all_genes.each_key do |locus_tag|
			create_all_networks_recursive(locus_tag, locus_tag) # Create network for each AGI locus ID with a depth of 3
		end
		annotate_networks # Annotate all genes in the networks with KEGG and GO terms
		# Separate individal networks to a list
		@network_list = Array.new
		separate_networks
	end

	# Read the gene_file to get all the genes and create instances of Gene objects for each Gene.
	# It fills the all_genes hash and the id_list array.
	def create_genes
		genes = File.open(@gene_file,'r')

		genes.readlines.each do |locus_tag|
			locus_tag.strip!
			locus_tag = locus_tag.upcase
			@all_genes[locus_tag] = Gene.new(id: locus_tag)
			@id_list << locus_tag
		end
	end

	# Get method for the all_networks RGL graph.
	#
	# @return [RGL::AdjacencyGraph] An undirected graph object that represents the networks. The vertices are Gene Objects.
	def all_networks
		return @all_networks
	end

	# Get method for the all_genes hash.
	#
	# @return [Hash<String, Gene>] A hash of all the genes of gene_file. The key is the AGI locus code and the value is the Gene object.
	def get_all_genes
		return @all_genes
	end
	
	# Retrieve a Gene object from the all_genes using the AGI Locus ID
	#
	# @param locus_tag [String] the AGI Locus ID.
	# @returns [Gene] The Gene with AGI Locus ID.
	def get_gene(locus_tag)
		return @all_genes[locus_tag]
	end

	# Auxiliary method to print the network in a DOT format, which can be used to visualize the graph in other software, like GraphViz.
	#
	# @see https://dreampuf.github.io/GraphvizOnline/
	# @returns [String] DOT file format of the graph.
	def save_network
		return @all_networks.print_dotted_on
	end

	# Find the GO and KEGG annotations for all the genes in the network. The information is stored in each Gene object.
	#
	def annotate_networks
		@all_networks.vertices.each do |gene|
			gene.find_GO
			gene.find_KEGG
		end
	end

	# Separate each individual network from all the networks as an RGL undirected graph.
	#
	# @returns [Array<RGL::AdjacencyGraph>] A list of an undirected Graph that represents each network of Genes.
	def separate_networks
		# Find the connected components from the whole network. Each connected component is an individual network
		@all_networks.each_connected_component { |network|
			net_graph = RGL::AdjacencyGraph.new # Create an instance of a graph to represent an individual network
			# Each Gene of the network
			network.each { |gene|
				# Search for all adjacent genes (interactions) of the gene in all_networks
				@all_networks.adjacent_vertices(gene).each { |adjacent| 
					# Add each interaction edge to the graph
					net_graph.add_edge(gene, adjacent)
				}
			}
			# A list of networks
			@network_list << net_graph
		}
	end

	# Create a Report that is a summary of the networks. The report has information of all the genes that form the network, 
	# all the KEGG pathway annotation of the network, and all the GO biological process of the network. Also in is specified in each
	# network the binary interactions between genes with their individual KEGG and GO ID. Also indicating if the genes are from the gene_list
	# Or they are intermediary genes that are not on the list, but interacts with them. Finally the report tells if the genes in the list are indeed 
	# binding to each other (the hypothesis).
	#
	# @param filename [String] The name of the report file. Eg: "NetworksReport.txt"
	# @returns [String] A filename with the report of the networks.
	def create_report(filename)
		File.open(filename, 'w') { |file|
			net_count = 1 # Keep track of the number of networks
			## Header block with information about the report.
			file.write("Network Report\n")
			file.write("By Guillermo Chumaceiro\n\n")
			file.write("The networks are formed by the arabidopsis genes defined in #{@gene_file},")
			file.write("I used the IntAct database to search meaningful interactions between this genes.\n")
			file.write("The depth of the search is of 3 genes, taking into acount the possibility of intermediary genes not in the list that interact with two genes on the list.\n")
			file.write("The interactions where filtered by the taxonomy ID of arabidopsis and the quality value of the interaction.\n")
			file.write("I decided to consider interactions with quality values >= 0.4.\n")
			file.write("Each network is annotated by the  KEGG pathways and GO terms associated with biological process of the genes of each network.\n")
			file.write("The following report is a summary of each network and the annotation of the genes in that network.\n")
			file.write("Keywords:\n")
			file.write("\tI: Indirect gene that interacts (not found on the gene list).\n")
			file.write("\tD: Direct gene that interacts (it is on the gene list).\n")
			total_direct_genes = Array.new # Keep track of all genes that interact that are on the gene_list
			# Go through each network
			@network_list.each do |network|
				# Start body of the report
				file.write("-"*50)
				file.write("\n")
				file.write("Network #{net_count}\n")
				file.write("The network has #{network.vertices.length} genes:\n")
				# Write all the genes in the network with their individual annotations
				# GO ANNOTATIONS
				network.vertices.each do |gene|
					file.write("#{gene}\n")
					# Find the GO ID and terms
					if gene.go.empty?
						go_string = "\tNo GO terms\n"
					else # Case where there is a GO ID
						go_string = "\tGO terms\n"
						# Annotate all GO TERMS
						gene.go.each {|id, go_term| go_string += "\t\tGO ID: #{id}\tGO biological process: #{go_term}\n"}
					end
					file.write(go_string) # Write to report

					# KEGG ANNOTATIONS
					if gene.kegg.empty?
						kegg_string = "\tNo KEGG pathways\n"
					else # Case where there is a GO ID
						kegg_string = "\tKEGG pathways\n"
						# Annotate all KEGG PATHWAYS
						gene.kegg.each {|id, kegg_term| kegg_string += "\t\tKEGG ID: #{id}\tKEGG Pathway: #{kegg_term}\n"}
					end
					file.write(kegg_string) # Write to report
					file.write("\n")
				end
				file.write("\n")
				file.write("\n")
				# KEGG info of all the network (without duplicates)
				kegg_hash = network_kegg(network) 
				file.write("The global KEGG pathways the genes in this network are involved in are:\n")
				kegg_hash.each do |kegg_id, pathway|
					file.write("KEGG ID: #{kegg_id} with the pathway: #{pathway}\n")
				end
				# GO info of all the network (without duplicates)
				go_hash = network_go(network)
				file.write("\n")
				file.write("The Biological processes the genes in this network participate in are:\n")
				go_hash.each do |go_id, go_term|
					file.write("GO ID: #{go_id} with the biological process: #{go_term}\n")
				end
				
				file.write("\n")
				# Interaction info 
				file.write("The interaction of genes in the network is:\n")

				indirect_genes = Array.new # Keep track of genes that interact but are NOT on list
				direct_genes = Array.new # Keep track of genes that interact that are on list
				# Iterate over the edges (interactions)
				network.edges.each do |interaction| 
					# For the source (1st interactor)
					# If the ID is in the id_list, then it is a direct gene
					if @id_list.include? interaction.source.id
						source_text = "Gene ID (D): #{interaction.source.id}"
						direct_genes |= [interaction.source.id]
						total_direct_genes |= [interaction.source.id]
					else  # Case where the ID is not on the list (Indirect Gene)
						source_text = "Gene ID (I): #{interaction.source.id}"
						indirect_genes |= [interaction.source.id]
					end

					# For the target (2nd interactor)
					# If the ID is in the id_list, then it is a direct gene
					if @id_list.include? interaction.target.id 
						target_text = "Gene ID (D): #{interaction.target.id}" 
						direct_genes |= [interaction.target.id]
						total_direct_genes |= [interaction.target.id]
					else # Case where the ID is not on the list (Indirect Gene)
						target_text = "Gene ID (I): #{interaction.target.id}"
						indirect_genes |= [interaction.target.id]
					end
					# The interaction line
					file.write("#{source_text} interacts with #{target_text}\n")
				end
				# write a summary of the number of direct and indirect genes.
				file.write("There are #{direct_genes.length} Genes that are on the gene list: #{direct_genes.join(" ")}\n")
				file.write("There are #{indirect_genes.length} Genes that are NOT on the gene list: #{indirect_genes.join(" ")}\n")
				net_count += 1
				file.write("\n")
			end
			file.write("-"*50)
			file.write("\n")
			interaction_ratio = total_direct_genes.length.to_f/@id_list.length.to_f # Ratio between interacting direct genes and all the gens¡es in the list
			# Final part of the report: If the interaction is significant or not.
			# Threshold for significance is that the ratio should be 50% or higher (If 50% of the genes interact with each other)
			file.write("#{total_direct_genes.length} Genes interact with each other out of a total of #{@id_list.length} Genes. #{(interaction_ratio*100.0).round(2)}% of the genes in the list interact with each other.\n")
			if interaction_ratio >= 0.5
				file.write("In conclusion, the number of co-expressed genes that interacts with each other is high (more than 50%).\n")
			else
				file.write("In conclusion, the number of co-expressed genes that interacts with each other is low (less than 50%).\n")
			end
			file.write("\n")
			file.write("End of report")
		}
	end

	# Retrieve all the GO ID and terms of the members of a network
	#
	# @param network [RGL::AdjacencyGraph] The network of Genes.
	# @returns [Hash<String, String>] A hash with GO ID as key and GO biological process term as value
	def network_go(network)
		go_terms = Hash.new 
		# Go through each gene object of the network
		network.vertices.each do |gene|
			# Update the go_terms hash to incude the GO hash of the gene, if it has one.
			go_terms = go_terms.merge(gene.go) unless gene.go.empty?
		end
		return go_terms
	end

	# Retrieve all the KEGG ID and terms of the members of a network
	#
	# @param network [RGL::AdjacencyGraph] The network of Genes.
	# @returns [Hash<String, String>] A hash with KEGG ID as key and KEGG pathway term as value
	def network_kegg(network)
		kegg_terms = Hash.new
		# Go through each gene object of the network
		network.vertices.each do |gene|
			# Update the kegg_terms hash to incude the KEGG hash of the gene, if it has one.
			kegg_terms = kegg_terms.merge(gene.kegg) unless gene.kegg.empty?
		end
		return kegg_terms
	end

	# Recursive method to seach for the interactions of a AGI locus ID and find connections with a certain depth. 
	# The depth level means how far in the interaction chain do you want to go for each AGI locus ID.
	# Found interactions are added to the @all_networks attribute.
	# IMPORTANT: Each vertex of the Graph is a Gene object with all its attributes. Each edge represents an interaction between two genes.
	#
	# @param prev_locus_tag [String] The AGI locus ID query of the previous depth level, it is needed to stablish complete interactions.
	# @param locus_tag [String] The AGI locus ID query that will be used to search for interactions.
	# @param depth [Integer] The depth level of the recursive function. CAUTION: Change to higher depth at your own risk.
	# @returns [RGL::AdjacencyGraph] An undirected graph object that represents the networks. The vertices are Gene Objects.
	def create_all_networks_recursive(prev_locus_tag,locus_tag, depth = 3)

		# Base case
		if depth == 1
			return
		end

		# Find all interactions of locus_tag
		interaction = InteractionParser.new(locus_id: locus_tag)
		# If there are interactions
		if interaction.interactions
			# Go through each interaction (line)
			interaction.interactions.each do |new_int|
				# Determine which is the query (locus_tag) and the interactor (other)
				new_int[0] == locus_tag ? other = new_int[1] : other = new_int[0]

				# If the other Gene (interactor) is in the gene_list, that means there is a direct connection and the edge is added to the graph.
				# We chech that the other and the locus_tag are not the previous locus tag to avoid infinte loops.
				if @id_list.include? other and (other != prev_locus_tag) and (prev_locus_tag != locus_tag)
					Gene.new(id: locus_tag) unless Gene.all_genes.has_key?(locus_tag) # Create a gene object if the Gene does not exist (For intermediaries)
					# Add the interaction (edge) between previous locus tag and the locus tag, unless it already exists
					@all_networks.add_edge(Gene.all_genes[prev_locus_tag], Gene.all_genes[locus_tag]) unless @all_networks.has_edge?(Gene.all_genes[prev_locus_tag], Gene.all_genes[locus_tag])
					# Add the interaction (edge) between locus tag and the other Gene, unless it already exists
					@all_networks.add_edge(Gene.all_genes[locus_tag], Gene.all_genes[other]) unless @all_networks.has_edge?(Gene.all_genes[locus_tag], Gene.all_genes[other])
					next # Go to next interaction (No need to go further)
				else # If other is not on the gene_list, seach of the interactions of other
					create_all_networks_recursive(locus_tag, other, depth-1) # Locus_tag becomes the prev_locus_tag and other becomes the query, we have reached another depth level.
				end
			end
		end
	end
end