require 'bio'

# Command line arguments
input_array = ARGV

# Check if CL arguments are two 
if input_array.empty? or (input_array.length != 3) then 
	$ARA_FILE = "./data/athaliana.fa"
  $SPOMBE_FILE = "./data/spombe.fa"
  $REPORT_FILE = "RBH_ara_spombe.txt"
else
	# Case where there are command line arguments
	$ARA_FILE = input_array[0]
  $SPOMBE_FILE = input_array[1]
  $REPORT_FILE = input_array[2]
end

# Convert A. Thaliana nucleotide sequences to protein fasta. It is more accurate to do blast between proteins.
# Also, blastp is more efficient than tblastx in comparing sequences.

faaoutput = File.open('./data/athaliana.faa', 'w') # Name of the output file
fasta_file = Bio::FlatFile.auto($ARA_FILE)
fasta_file.each_entry do |x| # Go though each fasta record
  # If translation includes codon stop as *, do not include it.
  if x.naseq.translate[-1] == "*" 
    # Translate without *
    protein = x.naseq.translate[1..-2] 
  else
    # Translate
    protein = x.naseq.translate #
  end
  # Convert to string
  seq_str = protein.to_s
  seq = Bio::Sequence.new(seq_str) # Create new biosequence
  faaoutput.puts seq.output_fasta(definition = x.definition) # Put the original header of each record
end

# Create a blast database for both A.thaliana and S.pombe
puts "Database for A.thaliana created" if system("makeblastdb -in ./data/athaliana.faa -dbtype 'prot' -out ./databases/athaliana_prot")
puts "Database for S.pombe created" if system("makeblastdb -in ./data/spombe.fa -dbtype 'prot' -out ./databases/spombe")


# Auxiliary method to index the fasta files
# This method creates a dictionary of the fasta file with the header of each record as key and the complete fasta as value.
# This mantains the sequences in memory and it is easier to seach than loading the file (It will be done many times).

# @return [Hash<String, String>]. The dictionary with the indexed fasta files.
def fasta2dict(fasta_file)
  fasta_dict = Hash.new
  fasta_data = Bio::FlatFile.auto(fasta_file) # Read file as Fasta Format
  fasta_data.each_entry do |fasta| # Iterate all records
    fasta_dict[fasta.definition] = fasta.to_s # Populate hash
  end
  return fasta_dict
end

# ---------------------------------------------
# Perform Reciprocal Blast Hit
# ---------------------------------------------

# blast and blast-legacy must be installed globally

# Perform a Reciprocal best hit between the proteome of two species using blastp to query their databases.
# The result is a report of the putative orthologues between the two species.
# 
# @param proteome_1 [String] The file to the proteome of the first species.
# @param proteome_2 [String] The file to the proteome of the second species.
# @param database_1 [String] The blast database of the first species.
# @param database_2 [String] The blast database of the second species.
# @param report_name [String] The name of the final report.
def RBH(proteome_1, proteome_2, database_1, database_2, report_name)

  # Create a blastp factory to search the athaliana protein database with an E-value threshold o 1E-6
  # Matches using proteins are more biologically meaningfull!!
  factory = Bio::Blast.local('blastp', database_1, '-e 0.000001')

  # Use the genome of S. Pombe as query
  query_file = proteome_2
  query_data = Bio::FlatFile.auto(query_file) # Fetch fasta as bioruby fasta:Format

  # Dictionaries for A. thaliana
  athaliana_fasta = fasta2dict(proteome_1)

  # Create a blastp factory to search the S.pombe protein database with an E-value threshold o 1E-6 
  # This is the reciprocal database
  reciprocal_factory = Bio::Blast.local('blastp', database_2, '-e 0.000001')

  # REGEX to extract only the ID from the header of each fasta record. This is used to compare matches.
  id_regex = Regexp.new(/^(\w+\.\w+)/i)

  # Keep track of the number of putative orthologues
  ort_count = 0

  puts "Searching for Reciprocal Best Hits"

  # Open the report file
  File.open(report_name,'w') do |file|

    # Header of the report
    file.write("Orthologues between A.thaliana and S.pombe\n")
    file.write("S.pombe gene\tA.thaliana gene\n")

    # Iterate though all the query fasta files
    query_data.each_entry do |query_fasta|

      query = query_fasta.to_s # Convert to string (Input to factory)
      report = factory.query(query) # Bio::Blast::Report
      # The BRH is the BEST hit, get only the first one.
      hit = report.hits[0] # hit: Bio::Blast::Report::Hit
      next if hit.nil? # Filter when there are no hits
      # From the best hit, get the best HSP
      hsp = hit.hsps[0] # Bio::Blast::Report::Hsp
      next if hsp.nil? # filter when there are no HSP

      # Calculate the coverage as alignment length/Query length
      cov = (hit.query_end.to_f - hit.query_start.to_f + 1) / query_fasta.length.to_f

      # Find the query ID using regex expression
      if query_fasta.definition.match(id_regex)
        query_id = $1
      end

      # Sensitivity filter. Coverage must be higher or equal to 50%
      if cov >= 0.5
        # Make blast with other seq
        # Get the sequence from the BEST HIT, it will be the reciprocal query
        reciprocal_query = Bio::FastaFormat.new(athaliana_fasta[hit.target_def])

        # Retrieve it's ID
        reciprocal_query_id = reciprocal_query.entry_id

        # Search the reciprocal query in the  S. pombe database
        reciprocal_report = reciprocal_factory.query(reciprocal_query.to_s) # Bio::Blast::Report

        # The BRH is the BEST hit, get only the first one.
        reciprocal_hit = reciprocal_report.hits[0] # hit: Bio::Blast::Report::Hit
        next if reciprocal_hit.nil? # Filter no hits
        # From the best hit, get the best HSP
        reciprocal_hsp = reciprocal_hit.hsps[0] # Bio::Blast::Report::Hsp
        next if reciprocal_hsp.nil? # filter when there are no HSP

        # Get the reciprocal target ID with the regex expression
        if reciprocal_hit.target_def.match(id_regex)
          reciprocal_target_id = $1
        end

        # Calculate reciprocal coverage
        reciprocal_cov = (reciprocal_hit.query_end.to_f - reciprocal_hit.query_start.to_f + 1) / reciprocal_query.length.to_f
        
        # Filter by coverage higher or equal to 50%
        if reciprocal_cov >= 0.5
          # Check if the target hit is the query hit of the first blast
          if reciprocal_target_id == query_id
            # That means that the query and the reciprocal are putative ORTHOLOGUES.
            file.write("#{query_id}\t#{reciprocal_query_id}\n") # Write line to report
            ort_count += 1 # Keep track of the number of orthologues
          end
        end
      end
    end
  end
  file.write("\n")
  file.write("Found #{ort_count} orthologues between S. pombe and A. thaliana")
  puts "Found #{ort_count} orthologues between S. pombe and A. thaliana"
end

# Run Reciprocal Best Hit program with both proteomes
RBH("./data/athaliana.faa", "./data/spombe.fa", './databases/athaliana_prot', './databases/spombe', $REPORT_FILE)

puts "Program ended"