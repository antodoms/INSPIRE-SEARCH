#!/usr/bin/env ruby

require 'elasticsearch'
require 'csv'
require 'json'
require 'pry'
require 'benchmark'


HOME = "/Users/antodoms"
excess_words = [".","(",")","&","to","and","or","the","a","about","above","after","again","against","all","am","an","any","are","aren't","as","at","be","because","been","before","being","below","between","both","but","by","can't","cannot","could","couldn't","did","didn't","do","does","doesn't","doing","don't","down","during","each","few","for","from","further","had","hadn't","has","hasn't","have","haven't","having","he","he'd","he'll","he's","her","here","here's","hers","herself","him","himself","his","how","how's","i","i'd","i'll","i'm","i've","if","in","into","is","isn't","it","it's","its","itself","let's","me","more","most","mustn't","my","myself","no","nor","not","of","off","on","once","only","other","ought","our","ours","ourselves","out","over","own","same","shan't","she","she'd","she'll","she's","should","shouldn't","so","some","such","than","that","that's","their","theirs","them","themselves","then","there","there's","these","they","they'd","they'll","they're","they've","this","those","through","too","under","until","up","very","was","wasn't","we","we'd","we'll","we're","we've","were","weren't","what","what's","when","when's","where","where's","which","while","who","who's","whom","why","why's","with","won't","would","wouldn't","you","you'd","you'll","you're","you've","your","yours","yourself","yourselves"]


loop do
  # some code here


        puts "Please choose from the following options:"
        puts "1. Clone from Git repository"
        puts "2. Start Reindexing Process"
        puts "3. Index the data to Elasticsearch"
        puts "4. Exit"



        command  = gets.chomp
        command = command.to_i

        if command == 1
            Dir.chdir '~'
						puts 'cloning Git repository'
						system 'git clone https://github.com/antodoms/INSPIRE-SEARCH'

        elsif command == 2
        		client = Elasticsearch::Client.new log: true
        		client.transport.reload_connections!

        		Dir.chdir HOME+'/INSPIRE-SEARCH/db'
            puts '........ Deleting Old Data from Index........'
            system 'curl -XDELETE http://localhost:9200/estates'
            system 'curl -XDELETE http://localhost:9200/estate'

            puts '........ Setting up the Estate ElasticSearch Index Configuration......'

            client.indices.create index: 'estate', body: {
						  settings: {
                          analysis: {
                            filter: {
                              qgram_filter: {
                                            type: "ngram",
                                            min_gram: 2,
                                            max_gram: 3
                                        }
                            },
                            analyzer: {
                                        index_ngram: {
                                            type: "custom",
                                            tokenizer: "standard",
                                            filter: "qgram_filter"
                                        },
                                        search_ngram: {
                                        		type: "custom",
                                            tokenizer: "standard",
                                            filter: "qgram_filter"
                                        }
                                    }
                          }
                          
                        },
                        mappings: {
                            property: {
                              properties: {
                                    location: {
                                      type: "geo_shape",
                                      tree: "quadtree",
                                       precision: "1km",
                                       points_only: true
                                    },
                                  description: {
								                    analyzer: "index_ngram",
								                    type: "string"
                                  }
                                }
                            }
                        }
						}

            client.indices.create index: 'estates', body: {
						  settings: {
                          analysis: {
                            filter: {
                              qgram_filter: {
                                            type: "ngram",
                                            min_gram: 2,
                                            max_gram: 3
                                        }
                            },
                            analyzer: {
                                        search_ngram: {
                                        		type: "custom",
                                            tokenizer: "standard",
                                            filter: "ngram"
                                        }
                                    }
                          }
                          
                        },
                        mappings: {
                            property: {
                              properties: {
                                    location: {
                                      type: "geo_shape",
                                      tree: "quadtree",
                                       precision: "1km",
                                       points_only: true
                                    },
                                  description: {
								                    type: "string",
								                    #index: "not_analyzed"
								                    analyzer: "search_ngram"
                                  
                                  }
                                }
                            }
                        }
						}

						puts '       '
						puts '........ Extracting Property Address Data......'

						timeaddress = Benchmark.measure {
						  final_data = {}
							address_data = CSV.table('PropertyAddress.csv')
							transformed_data = address_data.map { |row| row.to_hash }

							File.open('PropertyAddress.json', 'w') do |file|

								transformed_data.each do |data|
									tempdata = {}
									templocation = {}

									templocation[:type] = "Point".to_s
									templocation[:coordinates]= ["#{data[:lng].to_s}","#{data[:lat].to_s}"]
									tempdata[:address] = data[:formated_address].to_s
									tempdata[:location] = templocation
									final_data[data[:proid]] = tempdata
								end

								file.puts final_data.to_json
							end
							 }

							puts 'cpu time, system time, total and real elapsed time'
						 	puts timeaddress.real

						 	puts '       '
							puts '........ Extracting Property Basic Data......'


							time = Benchmark.measure {
								extracted_data   = CSV.table('PropertyBasic.csv')
								address_data = file = File.read('PropertyAddress.json')
								data_hash = JSON.parse(file)
								transformed_data = extracted_data.map { |row| row.to_hash }


								File.open('PropertyBasic.json', 'w') do |file|

									transformed_data.each do |data|
										id = data[:proid].to_s
										index={}
										idindex={}
										final_data = {}
										index["_id"] = id.to_s
										idindex["index"] = index
										#binding.pry
										if(data_hash[id] != nil )
											final_data[:id] = data[:proid].to_s
											#final_data[:price] = data[:price].to_s
											
											cleaned_array = data[:des_content].to_s.downcase.gsub(/[^a-z0-9\s]/i, '').split.uniq.reject {|term| excess_words.include? term}

											#final_data[:address] = data_hash[id]["address"].to_s
											final_data[:location] = data_hash[id]["location"]
											final_data[:description] = "#{cleaned_array.join(" ")} #{data_hash[id]["address"].to_s} #{data[:protype].to_s}"
											#final_data[:propertytype] = data[:protype].to_s

											file.puts idindex.to_json
											file.puts final_data.to_json
										end
									end

								end
							}

							puts 'cpu time, system time, total and real elapsed time'
						 	puts time.real
						
							puts '............Starting Indexing Process............'
						 	timeindexing = Benchmark.measure {
						 		system 'curl -XPOST http://localhost:9200/estates/property/_bulk --data-binary "@PropertyBasic.json"'
						 		system 'curl -XPOST http://localhost:9200/estate/property/_bulk --data-binary "@PropertyBasic.json"'
						 	}
            	
            	puts 'cpu time, system time, total and real elapsed time'
						 	puts timeindexing.real
            	
        elsif command == 3
        	client = Elasticsearch::Client.new log: true
        	client.transport.reload_connections!

        	Dir.chdir HOME+'/INSPIRE-SEARCH/db'
            puts '........ Deleting Old Data from Index........'
            system 'curl -XDELETE http://localhost:9200/estates'
            system 'curl -XDELETE http://localhost:9200/estate'

            puts '........ Setting up the Estate ElasticSearch Index Configuration......'

            client.indices.create index: 'estate', body: {
						  settings: {
                          analysis: {
                            filter: {
                              qgram_filter: {
                                            type: "ngram",
                                            min_gram: 2,
                                            max_gram: 3
                                        }
                            },
                            analyzer: {
                                        index_ngram: {
                                            type: "custom",
                                            tokenizer: "standard",
                                            filter: "qgram_filter"
                                        }
                                    }
                          }
                          
                        },
                        mappings: {
                            property: {
                              properties: {
                                    location: {
                                      type: "geo_shape",
                                      tree: "quadtree",
                                       precision: "1km",
                                       points_only: true
                                    },
                                  description: {
								                    analyzer: "index_ngram",
								                    type: "string"
                                  }
                                }
                            }
                        }
						}

            client.indices.create index: 'estates', body: {
						  settings: {
                          analysis: {
                            filter: {
                              qgram_filter: {
                                            type: "ngram",
                                            min_gram: 2,
                                            max_gram: 8
                                        }
                            },
                            analyzer: {
                                        search_ngram: {
                                        		type: "custom",
                                            tokenizer: "standard",
                                            filter: ["standard", "lowercase", "stop"]
                                        }
                                    }
                          }
                          
                        },
                        mappings: {
                            property: {
                              properties: {
                                    location: {
                                      type: "geo_shape",
                                      tree: "quadtree",
                                       precision: "1km",
                                       points_only: true
                                    },
                                  description: {
								                    type: "string",
								                    analyzer: "search_ngram"
                                  
                                  }
                                }
                            }
                        }
						}


        	puts '............Starting Indexing Process............'
						 	timeindexing = Benchmark.measure {
						 		system 'curl -XPOST http://localhost:9200/estates/property/_bulk --data-binary "@PropertyBasic.json"'
						 		system 'curl -XPOST http://localhost:9200/estate/property/_bulk --data-binary "@PropertyBasic.json"'
						 	}
            	
            	puts 'cpu time, system time, total and real elapsed time'
						 	puts timeindexing.real
        end

    break if command == 4
end
