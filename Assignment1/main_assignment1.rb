# Import the other classes
require './Gene.rb'
require './HybridCross.rb'
require './SeedStock.rb'
require './StockDatabase.rb'

# Global variables
# Paths for tsv files
$stock_file = './StockDatabaseDataFiles/seed_stock_data.tsv'

# Create a new stock database
database = StockDatabase.new

# Fill database with tsv file stock data
database.load_from_file($stock_file)

database.get_seed_stock('A348')

database.plant_seed(7)

database.write_database('new_seed_stock_data.tsv')

gene = Gene.new(
    gene_id: 'AT1G69120',
    gene_name: 'ap1',
    mutant_phenotype: "meristems replace first and second whorl")

puts gene.gene_id