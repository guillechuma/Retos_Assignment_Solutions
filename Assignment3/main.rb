require './Gene'

# == main
#
# This is the main program to find CTTCTT repeats in the exons of a list of genes.
#
# == Summary
# 
# The program creates an EMBL file of all the genes,
# it then creates an annotated Gene object. It writes a report of the genes that to not 
# have exons with the CTTCTT repeat.
# It then generates two GFF3 files. The first one is of all the repeat features in the 
# Gene coordinates.
# The second is a GFF3 file with the chromosome coordinates.
# It can be loaded to ENSEMBL to view the CTTCTT repeats in the cromosome.

# Command line arguments (should be one)
input_array = ARGV

# Check if CL arguments are one
if input_array.empty? or (input_array.length != 4) then 
	$GENE_FILE = 'ArabidopsisSubNetwork_GeneList.txt'
    $REPORT_FILE = 'genes_not_repeats.txt'
    $GFF3_FILE = 'repeats.gff3'
    $CHR_GFF3_FILE = 'chr_repeats.gff3'
else
	# Case where there are command line arguments
	$GENE_FILE = input_array[0]
    $REPORT_FILE = input_array[1]
    $GFF3_FILE = input_array[2]
    $CHR_GFF3_FILE = input_array[3]
end

genes = File.open($GENE_FILE ,'r')
# Create gene annotated objects 
genes.readlines.each do |gene_id|
    gene_id.strip! # Remove \n
    gene_id.upcase! # Normalize id
    Gene.new(id: gene_id) # Create annotated gene object
end

# Write report of genes on the list that do no have exons with CTTCTT repeat
File.open($REPORT_FILE,'w') do |file|
    file.write("This report contains the genes on the list that do no have exons with CTTCTT repeat\n\n")
    Gene.all_genes.each_value do |gene|
        file.write(gene.write_report)
    end
    file.write("\nEnd of Report")
end

# Write a GFF3 file with the CTTCTT repeats in the exons of all the genes in the list.
# Using the coordinates of each Gene.
# 
# @return [String] The gff3 file.
def write_gff3
    File.open($GFF3_FILE,'w') do |file|
        file.write("##gff-version 3\n")
        Gene.all_genes.each do |gene_id, gene|
            gene.sequence.features.each do |feature|
                next unless feature.feature == "repeat"
                # Determine the orientation of the strand
                Regexp.new(/complement/i).match(feature.position) ? strand = "-" : strand = "+"
                from, to = feature.locations.span
				exon_id = feature.assoc['note']
                file.write("#{gene_id}\tGene.rb\trepeat_unit\t#{from}\t#{to}\t.\t#{strand}\t.\texon_id=#{exon_id}\n")
            end
        end
        # Write FASTA
        file.write("##FASTA\n")
        Gene.all_genes.each do |gene_id, gene|
            file.write("#{gene.sequence.output_fasta(definition=gene_id)}")
        end
    end
end

# Write gff3
write_gff3

# Write a GFF3 file with the CTTCTT repeats in the exons of all the genes in the list.
# Using the coordinates of the chromosome. It can be added to an ENSEMBL track.
# @return [String] The gff3 file with chromosome coordinates.
def write_chr_gff3
    File.open($CHR_GFF3_FILE,'w') do |file|
        file.write("##gff-version 3\n")
        Gene.all_genes.each do |gene_id, gene|
            # SEACH FOR GENE POSITION IN CHROMOSOME
            accession = gene.embl.accession # The position is in the accession 
            # Extract chromosome number, the start and end position of the gene in the chromosome.
            acc_regex = Regexp.new(/chromosome:TAIR10:(\d):(\d*):(\d*):1/)
            match = acc_regex.match(accession)
            chr = match[1] # Chr number
            chr_start = match[2] #Start gene in chromosome
            chr_end = match[3] #End gene in chromosome
            # Go through each feature
            gene.sequence.features.each do |feature|
                # Use repeat features only
                next unless feature.feature == "repeat"
                # Determine the orientation of the strand
                Regexp.new(/complement/i).match(feature.position) ? strand = "-" : strand = "+"
                from, to = feature.locations.span # Get the location of the repeat in the gene
				exon_id = feature.assoc['note'] # Get the exon ID
                
                from = chr_start.to_i + from.to_i - 1 # The starting position of the repeat in the chromosome
                to = chr_start.to_i + to.to_i - 1 # The ending position of the repeat in the chromosome
                
                # The GFF3 annotation line. The type is repeat_unit
                file.write("chr#{chr}\tGene.rb\trepeat_unit\t#{from}\t#{to}\t.\t#{strand}\t.\tNote=#{exon_id}\n")
            end
        end
    end
end

# Write chromosome GFF3
write_chr_gff3