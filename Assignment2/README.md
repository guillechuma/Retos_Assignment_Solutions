## Solution to the Assignment 2 of the UPM's Master course in Computational Biology

All the code was written by me (Guillermo Chumaceiro).

This program finds the interaction network of Arabidopsis thaliana genes based on the information of the [IntAct database](https://www.ebi.ac.uk/intact/home). Also we generate a report with the KEGG and GO terms associated with each network. The purpose of this interaction network is to see how the protein these co-expressed genes interact with each other.

See the Documentation of the code [here](./doc/) (Generated with yardoc).

To run the program you need to clone this repository and use the command line. The main file is named [main.rb](./main.rb). The command to run the program is: 
```
ruby main.rb ArabidopsisSubNetwork_GeneList.txt NetworksReport.txt
```

The output of the command line program is in the file NetworksReport.txt