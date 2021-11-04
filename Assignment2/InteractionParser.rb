require './Interaction.rb'

class InteractionParser
	##
	# This class represents a Parser for a set of Interactions of a Gene object
	# It creates all Interaction Objects for every pair of interaction with
	# all its properties.
	##

	attr_accessor :locus_id
	def initialize(params={})
		@locus_id = params.fetch(:locus_id, '')
		#url = 'http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/At4g18960?format=tab25'

		@interactions = create_interactions # Array of all the interaction objects
	end

	def create_interactions
		# Array of all interactions in file
		interactions = Array.new
		url = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{@locus_id}?format=tab25"
		# url = "http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{@locus_id}/?format=tab25"
		if res = fetch(url)
			raw_data = res.body
			# If the result is empty, that gene does not interact? ASK
			return nil if raw_data.length == 0
			data = raw_data.split("\n")
			data.each do |line|
				interaction = create_interaction(line)
				# Check if nil or not
				if interaction
					interactions << interaction
				end
			end
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
		locus_tag_regex =/A[Tt]\d[Gg]\d\d\d\d\d/i
		#tair_regex = /tair:(.*?)(?:\t|\(.*?\)|\||$)/
		id_a = id_a.scan(line_regex).flatten[0]
		id_b = id_b.scan(line_regex).flatten[0]
		alt_id_a = alt_id_a.scan(line_regex).flatten
		alt_id_b = alt_id_b.scan(line_regex).flatten
		# locus_tag_a = alt_id_a.scan(tair_regex).flatten[0]
		# locus_tag_b = alt_id_b.scan(tair_regex).flatten[0]
		al_a = al_a.scan(line_regex).flatten
		al_b = al_b.scan(line_regex).flatten
		int_met = int_met.scan(line_regex).flatten
		tax_a = tax_a.scan(line_regex).flatten
		tax_b = tax_b.scan(line_regex).flatten
		int_type = int_type.scan(line_regex).flatten
		source_db = source_db.scan(line_regex).flatten
		int_id = int_id.scan(line_regex).flatten
		int_score = int_score.scan(line_regex).flatten

		# FILTERS

		# Taxonomy filter. Ara TaxID: 3702
		ara_tax = "3702"
		return nil unless (tax_a.include? ara_tax) and (tax_b.include? ara_tax)

		# Quality filter
		return nil unless int_score[0].to_f >= 0.4
		# Filter by interaction detection method
		not_valid_int = [0364, 0362, 0363, 0063, 0046]
		# return nil if not_valid_int.include? int_met


		## FIND LOCUS TAG IN ALL ID's (IT WILL BE UNIQUE ID FOR EACH GENE)
		# For protein A
		if id_a and alt_id_a and al_a
			all_ids_a = id_a + " " + alt_id_a.join(" ")  + " " + al_a.join(" ")
			# puts 'ID a: ' + all_ids_a
			locus_tag_a = all_ids_a.match(locus_tag_regex)

			# If there is no locus tag, look for it in TOGO
			# locus_tag_a = find_locus_tag(all_ids_a) unless locus_tag_a
		end

		# For protein B
		if id_b and alt_id_b and al_b
			all_ids_b = id_b + " " + alt_id_b.join(" ") + " " +  al_b.join(" ")
			# puts 'ID b: ' + all_ids_b
			locus_tag_b = all_ids_b.match(locus_tag_regex)

			# If there is no locus tag, look for it in TOGO
			# locus_tag_b = find_locus_tag(all_ids_b) unless locus_tag_b
		end

		# CHECK
		unless locus_tag_a
			#puts "not found locus a #{locus_tag_a}"
			return nil
		end

		unless locus_tag_b
			#puts "not found locus b #{locus_tag_b}"
			return nil
		end

		# Check if protein A and protein B are the same
		return nil if locus_tag_a[0] == locus_tag_b[0]

		return locus_tag_a[0].upcase, locus_tag_b[0].upcase

		# return nil if locus_tag_a == locus_tag_b
		
		# return locus_tag_a, locus_tag_b
		# TODO: Check if it is necesary to create genes
		# Create Proteins
		protein_a = Gene.new(id: locus_tag_a[0])
		protein_b = Gene.new(id: locus_tag_b[0])

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

	def find_locus_tag(alt_ids)
		#puts "alternative id #{alt_ids}"
		locus_tag_regex =/A[Tt]\d[Gg]\d\d\d\d\d/i
		alt_id_list = alt_ids.split(" ")
		alt_id_list.each do |alt_id|
			if url = fetch("http://togows.dbcls.jp/entry/uniprot/#{alt_id}/dr.json")
				text = url.body
				locus_tag = text.match(locus_tag_regex)

				# if locus_tag
				# 	#puts "found locus tag #{locus_tag}"
				# 	return locus_tag
				# else
				# 	if url = fetch("https://www.uniprot.org/uniprot/#{alt_id}.txt")
				# 		text = url.body
				# 		locus_tag = text.match(locus_tag_regex)
				# 	end
				# end

				if locus_tag
					#puts "found locus tag #{locus_tag}"
					return locus_tag
				else
					return nil
				end
			end
		end

		return nil
	end
end

def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
	response = RestClient::Request.execute({
	  method: :get,
	  url: url.to_s,
	  user: user,
	  password: pass,
	  headers: headers})
	return response
	
	rescue RestClient::ExceptionWithResponse => e
	  $stderr.puts e.inspect
	  response = false
	  return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
	rescue RestClient::Exception => e
	  $stderr.puts e.inspect
	  response = false
	  return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
	rescue Exception => e
	  $stderr.puts e.inspect
	  response = false
	  return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  end