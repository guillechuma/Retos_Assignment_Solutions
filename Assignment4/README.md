## Solution to the Assignment 4 of the UPM's Master course in Computational Biology

All the code was written by me (Guillermo Chumaceiro).

This program does a reciprocal best blast hits (RBH) between all proteins of Arabidopsis thaliana and Schizosaccharomyces pombe to find putative orthologues between the two species.

An important remark in finding orthologues through reciprocal best hits is that comparing protein sequences give more accurate results, since they are less redundant than nucleic acids. That is the reason why I chose to convert all the sequences to protein and create a protein database to find the orthologues.

I adjusted two parameters of the BLASTp program to find orthologues [1]:

1. E-Value of 1*10-6.
2. A query coverage of greater or equal to 50% (defined as alignment length/query length).

To run the program you need to clone this repository and use the command line. You need to have blast and blast-legacy installed in you local computer. The main file is named [main.rb](./main.rb). The command to run the program is: 
```
ruby main.rb ./data/athaliana.fa ./data/spombe.fa
```

The result of the program is a report that can be found here: [RBH_ara_spombe.txt](./RBH_ara_spombe.txt)

The next step to determine the homologous proteins between these two species would be to make a phylogenetic analysis on the putative orthologues obtained in the Reciprocal Best Hit. A phylogenetic tree gives a more accurate representation of the evolutionary history between the two species, thus allowing to differentiate paralogues from orthologues. Another thing that phylogenetic trees captures are co-orthologs.

Bibliography

[1] Ward, N., & Moreno-Hagelsieb, G. (2014). Quickly finding orthologs as reciprocal best hits with BLAT, LAST, and UBLAST: how much do we miss?. PloS one, 9(7), e101850. https://doi.org/10.1371/journal.pone.0101850

[2]