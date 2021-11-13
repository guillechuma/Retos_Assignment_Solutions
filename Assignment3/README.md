## Solution to the Assignment 3 of the UPM's Master course in Computational Biology

All the code was written by me (Guillermo Chumaceiro).

This program does several things.

1. Creates and annotates genes in the gene list with CTTCTT repeat sequences present in the exons.
    1. It takes into account the possibility of sequence overlapping.
    2. It annotates the forward and the reverse CTTCTT correctly.
2. Create a report of genes on the list that do not have exons with the CTTCTT repeat. (see [genes_not_repeats.txt](./genes_not_repeats.txt))
3. Create a GFF3 file of the repeat_unit feature using each gene coordinate. (see [repeats.gff3](./repeats.gff3))
4. Create another GFF3 file of the repeat_unit CTTCTT that has the chromosome coordinates. (see [chr_repeats.gff3](./chr_repeats.gff3))
    - This GFF3 file can be added as a track on ENSEMBL and visualize the repeat_units.

See the Documentation of the code [here](./doc/) (Generated with yardoc).

To run the program you need to clone this repository and use the command line. The main file is named [main.rb](./main.rb). The command to run the program is: 
```
ruby main.rb ArabidopsisSubNetwork_GeneList.txt genes_not_repeats.txt repeats.gff3 chr_repeats.gff3
```

This image [Arabidopsis_thaliana_219022154_19027528.png](./Arabidopsis_thaliana_219022154_19027528.png) is the ENSEMBL region of gene AT2G46340.
It shows the gene track and also the CTTCTT repeat track in brown. The upper part is the forward stand and the lower part is the reverse strand.