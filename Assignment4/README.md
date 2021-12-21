## Solution to the Assignment 4 of the UPM's Master course in Computational Biology

All the code was written by me (Guillermo Chumaceiro).

This program does a reciprocal best blast hits (RBH) between all proteins of Arabidopsis thaliana and Schizosaccharomyces pombe to find putative orthologues between the two species.

An important remark in finding orthologues through reciprocal best hits is that comparing protein sequences give more accurate results, since they are less redundant than nucleic acids. That is the reason why I chose to convert all the sequences to protein and create a protein database to find the orthologues. Also, performing blastp is more efficient than tblastx.

I adjusted two parameters of the BLASTp program to find orthologues [1]:

1. E-Value of 1*10-6.
2. A query coverage of greater or equal to 50% (defined as alignment length/query length).

To run the program you need to clone this repository and use the command line. You need to have blast and blast-legacy installed in you local computer. The main file is named [main.rb](./main.rb). The command to run the program is: 
```
ruby main.rb ./data/athaliana.fa ./data/spombe.fa RBH_arabidopsis_spombe.txt
```

The result of the program is a report that can be found here: [RBH_ara_spombe.txt](./RBH_ara_spombe.txt)

### Next steps to confirm orthology

1. The ideal step to determine the orthologue proteins between these two species would be to make a phylogenetic analysis on the putative orthologues obtained in the Reciprocal Best Hit. A phylogenetic tree gives a more accurate representation of the evolutionary history between the two species, thus allowing to differentiate paralogues from orthologues. Another thing that phylogenetic trees captures are co-orthologs. The idea behind this method, although it is computationally more expensive, would be to include a third species (the more the better) and find putative orthologues and construct a gene tree with the ortologue genes. then we find the species tree between and reconcile both trees to find the duplication and speciation events, thus separating orthologues from paralogues. This step is hard and computationally expensive [2].

2. Another way we can include a third species to the analysis of orthology is to do RBH of the third species with the initial two and form what are called Clusters of Orthologous Groups (COG). If two genes are the RBH, then if we compare them both to a third gene and are at the same time RBH of that third gene, chances are high that these genes are indeed orthologues. To form a COG we need that the RBH of the three species form a triangle relationship [3]. 

3. Another easier and valid approach that we can do to confirm that two RBH are orthologues is to make a functional analysis of the pair of genes. In theory, orhologues are more likely to have the same function. So a simple way to eliminate false positives is to find the GO terms of each pair and see if they are the same, specially the molecular function and the biological process. We can determine a threshold to consider two genes homologues. For example, if they same more than 80% of their GO terms they are orthologues [2].

### Bibliography

[1] Ward, N., & Moreno-Hagelsieb, G. (2014). Quickly finding orthologs as reciprocal best hits with BLAT, LAST, and UBLAST: how much do we miss?. PloS one, 9(7), e101850. https://doi.org/10.1371/journal.pone.0101850

[2] Fang, G., Bhardwaj, N., Robilotto, R., & Gerstein, M. B. (2010). Getting started in gene orthology and functional analysis. PLoS computational biology, 6(3), e1000703. https://doi.org/10.1371/journal.pcbi.1000703

[3] Li, L., Stoeckert, C. J., Jr, & Roos, D. S. (2003). OrthoMCL: identification of ortholog groups for eukaryotic genomes. Genome research, 13(9), 2178–2189. https://doi.org/10.1101/gr.1224503