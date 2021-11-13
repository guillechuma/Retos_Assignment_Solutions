require './Gene'

# Command line arguments (should be two)
input_array = ARGV

genes = File.open('ArabidopsisSubNetwork_GeneList.txt','r')
# Create gene annotated objects 
genes.readlines.each do |gene_id|
    gene_id.strip!
    gene_id.upcase!
    Gene.new(id: gene_id)
end

# Write report of genes on the list that do no have exons with CTTCTT repeat
File.open('genes_not_repeats.txt','w') do |file|
    file.write("This report contains the genes on the list that do no have exons with CTTCTT repeat\n\n")
    Gene.all_genes.each_value do |gene|
        file.write(gene.write_report)
    end
    file.write('End of Report')
end

def write_gff3
    File.open('repeats.gff3','w') do |file|
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

def write_chr_gff3
    File.open('crh_repeats.gff3','w') do |file|
        file.write("##gff-version 3\n")
        Gene.all_genes.each do |gene_id, gene|
            # SEACH FOR CHROMOSOME POSITION
            accession = gene.embl.accession
            acc_regex = Regexp.new(/chromosome:TAIR10:(\d):(\d*):(\d*):1/)
            match = acc_regex.match(accession)
            chr = match[1]
            chr_start = match[2]
            chr_end = match[3]
            gene.sequence.features.each do |feature|
                next unless feature.feature == "repeat"
                # Determine the orientation of the strand
                Regexp.new(/complement/i).match(feature.position) ? strand = "-" : strand = "+"
                from, to = feature.locations.span
				exon_id = feature.assoc['note']
                
                from = chr_start.to_i + from.to_i - 1
                to = chr_start.to_i + to.to_i - 1
                file.write("#{chr}\tGene.rb\trepeat_unit\t#{from}\t#{to}\t.\t#{strand}\t.\tNote=#{exon_id}\n")
            end
        end
    end
end

write_chr_gff3