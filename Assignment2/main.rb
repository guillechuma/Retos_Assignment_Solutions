require 'rest-client'
require './InteractionParser.rb'
require './InteractionNetwork'
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

gene_file = 'ArabidopsisSubNetwork_GeneList.txt'

puts 'Creating network'

network = InteractionNetwork.new(gene_file: gene_file)

puts network.network
puts "\n"
puts network.save_network

puts 'program finished'
abort

url = 'http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/At4g18960?format=tab25'

if res = fetch(url)

	#File.open('test.tsv', 'w') {|file| file.write(res)}
	# Separate text by line
	row = res.body

	puts row.length == 0
	abort

	int = InteractionParser.new(tab25_data: row)
	puts int.interactions[0].interactorA.taxonomy_id
	puts Gene.get_all_genes.keys
	abort
	
	row = res.body.split('\n')

	# Go through each line
	row.each do |line|
		#puts line
		puts 'line'
		puts line
		puts '-'*10
		#matches = line.match(/\S*?:(.*?)(?:\(.*?\)|\||$)/i)

		id_a, id_b, alt_id_a, alt_id_b, al_a, al_b, int_met, fist_a, id_pub, tax_a, tax_b, int_type, source_db, int_id, int_score = line.split("\t")
		puts alt_id_a
		matches = alt_id_a.scan(/\S*?:(.*?)(?:\(.*?\)|\||$)/i).flatten
		puts matches
		abort
		#puts id_a
		#puts tax_b
	end
end