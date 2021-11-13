require 'bio'
require 'rest-client'   # this is how you access the Web
# == Gene
#
# This is a representation of a Gene
# that can interact with other genes.
#
# == Summary
# 
# It has a unique ID identifier, represented by Arabidopsis AGI code,
# and also functional annotation from KEGG and GO databases about it.
# All the data was extracted Using TOGO and the IntAct databases.
class Gene

	# Get/Set the Gene ID AGI Locus Codes
	# @!attribute [rw] id
	# @return [String] The Gene ID AGI Locus Codes
	attr_accessor :id # Unique locus tag ID

	# Get/Set the EMBL record of the Gene ID
	# @!attribute [rw] embl
	# @return [Bio::EMBL] the EMBL record of the Gene ID
	attr_accessor :embl

	# Get/Set the Sequence of the Gene ID
	# @!attribute [rw] sequence
	# @return [Bio::Sequence] the Sequence of the Gene ID
	attr_accessor :sequence

	# Get/Set the Features of the Gene ID
	# @!attribute [rw] features
	# @return [Hash<String, Hash<String, Bio::Feature>>] the features of the Gene ID
	attr_accessor :features

	# Hash that contains all the genes that are created (Class variable)
	# @!attribute [r] all_genes
	# @return [Hash<String, Gene>] A Hash of all the genes created. The key is the Gene ID (AGI Locus Codes) and the value is the Gene Object.
	@@all_genes = Hash.new

	# Create a new instance of Gene object
	# 
	# @param id [String] The ID: AGI Locus Codes, normalized to upcase
	# @param go [Hash<String, String>] The GO annotations. The key is the ID and the value is the description of the term.
	# @param kegg [Hash<String, String>] The KEGG annotations. The key is the ID and the value is the pathway.
	# @return [Gene] an instance of Gene
	def initialize(params = {})

		#Validate ID
		gene_id_code = params.fetch(:id, nil)
		# Regex expression of the Gene ID
		gene_id_regex = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
		# Only match codes that follow the regex and have the same lenth as a Gene ID
		unless gene_id_regex.match(gene_id_code) and (gene_id_code.length == 9)
			puts "The Gene ID #{gene_id_code} is not valid"
			@id = nil
		else
			@id = gene_id_code
			@id = @id.upcase
		end

		# Create an EMBL file if it does not exists
		filename = "./embl_records/#{@id}.embl"
		fetch_embl(@id) unless File.file?(filename)

		# Read embl file (Be carefull with next_entry)
		# TODO: Check assumption that each file has only one record
		@embl = read_embl(@id).next_entry

		# Create a sequence object to annotate it!
		@sequence = @embl.to_biosequence

		# @TODO: General feature HASH
		@features = Hash.new

		# Annotate exon features
		@features["exons"] = get_exons_features

		# Annotate sequence
		search_annotate_sequence

		@@all_genes[@id] = self
	end

	#
    #
    # @return [Bio::FlatFile] flat embl record located in ./embl_records
	def fetch_embl(id)
		address = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{id}"
		response = fetch(address)
		record = response.body
		# create a local file with this data
		File.open("./embl_records/#{id}.embl", "w") do |file|  # w makes it writable
			file.puts record
		end
	end

	#
    #
    # @return [Bio::FlatFile] emlb record of ID
	def read_embl(id)
		filename = "./embl_records/#{id}.embl"
		return Bio::FlatFile.auto(filename)
	end

	def get_exons_features

		# entry =  @embl.next_entry; # OJO: Assume each file has one entry
		# iterates over each element in 'features' # features method finds all features
		exon_hash = Hash.new

		@embl.features.each do |feature|
			# FILTER EXONS
			next unless feature.feature == "exon"
			# position = feature.position # Look at Bio::Feature object
			
			qual = feature.assoc 

			exon_id_regex = Regexp.new(/exon_id=(#{@id}.*)/i)

			if exon_id_regex.match(qual["note"])
				exon_hash[$1] = feature
			end
		end
		return exon_hash
	end

	# Find sequence pattern (CTTCTT)
	def search_annotate_sequence(feature_name = 'repeat', sequence = 'cttctt')
		sequence = Bio::Sequence::NA.new(sequence)
		sequence_regex = Regexp.new(/(?=#{sequence})/i)
		reverse_sequence_regex = Regexp.new(/(?=#{sequence.complement})/i)
		@features['exons'].each do |exon_id, exon|
			sequence = @sequence.splicing(exon.position)
			matches = sequence.to_enum(:scan, sequence_regex).map {Regexp.last_match}
			# TO adjust positions relative to sequence!!
			from, to = exon.locations.span
			if matches
				matches.each do |match|
					position = "#{match.offset(0)[0] + 1 + from - 1}..#{match.offset(0)[0] + from - 1 + 6}"
					repeat_ft = Bio::Feature::new(feature_name , position)
            		repeat_ft.append(Bio::Feature::Qualifier.new('note', exon_id))
					@sequence.features << repeat_ft
				end
			end

			rev_matches = sequence.to_enum(:scan, reverse_sequence_regex).map {Regexp.last_match}
			if rev_matches
				rev_matches.each do |match|
					position = "complement(#{match.offset(0)[0] + 1 + from - 1}..#{match.offset(0)[0] + from - 1 + 6})"
					rev_repeat_ft = Bio::Feature::new(feature_name , position)
					rev_repeat_ft.append(Bio::Feature::Qualifier.new('note', exon_id))
					@sequence.features << rev_repeat_ft
			   end
			end
		end
	end

	def write_gff3
		File.open('test_repeats.gff3','w') do |file|
			file.write("##gff-version 3\n")
			@sequence.features.each do |feature|
				next unless feature.feature == 'repeat'
				Regexp.new(/complement/i).match(feature.position) ? strand = "-" : strand = "+"
				from, to = feature.locations.span
				exon_id = feature.assoc['note']
				file.write("#{@id}\tGene.rb\trepeat_unit\t#{from}\t#{to}\t.\t#{strand}\t.\texon_id=#{exon_id}\n")
			end
			# Write FASTA
			file.write("##FASTA\n")
		end
	end

	def write_report
		repeats_array = Array.new
		@sequence.features.each do |feature|
			next unless feature.feature == 'repeat'
			repeats_array << feature.assoc['note']
			# next if gene.features['exons'].key?(idx)
			# puts gene.features['exons'][idx]
		end
		repeats_array = repeats_array.uniq

		report_string = String.new
		exons_not_repeat = @features["exons"].keys - repeats_array.uniq
		unless exons_not_repeat.empty?
			report_string += "Gene ID: #{@id}\n"
			report_string += exons_not_repeat.join("\n")
			report_string += "\n\n"
		end
		# exons_not_repeat.each do |not_exon|
		# 	puts not_exon
		# end
		return report_string
	end

	# Class Method to get all the created Gene objects.
	#
	# @return [Hash<String, Gene>] the class variable all_genes.
	def Gene.all_genes
		return @@all_genes
	end

	# Overwrite the == method to compare genes by AGI Locus Codes (ID)
	#
	# @param other [Gene] A Gene object to compare.
	# @return [Boolean]. True if Genes are the same, false if not.
	def ==(other)
		self.id == other.id
	end

	# Overwrite the to_s method to print genes by AGI Locus Codes (ID)
	#
	# @return [String]. The Gene ID.
	def to_s
		return @id
	end

    #
    #
    # @return [Bio::FlatFile] 
    def read_file(filename)
        return Bio::FlatFile.auto(filename)
    end

    def get_features(feature)

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
