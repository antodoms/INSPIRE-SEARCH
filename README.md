# INSPIRE-ELASTICSEARCH

This is a web version of the INSPIRE - FRAMEWORK using the ELASTICSEARCH.

## ELASTICSEARCH INSTALLATION

To make this work perfectly. The first requirement is Elastic Search Server is already running in your system.

https://www.elastic.co/downloads/elasticsearch

Now change to Elastic search Directory

```console
cd elasticsearch
bin/elasticsearch 
```
This will run in background and needs to be on all the time.

## INDEXING THE DATA TO ELASTICSEARCH

```console
cd ~
git clone https://github.com/antodoms/INSPIRE-SEARCH'
cd INSPIRE-SEARCH
ruby db/indexElasticSearch.rb 
```

## USING THE INSPIRE-ELASTICSEARCH

Use the following code in your console to try out the search.

```console
cd ~
cd INSPIRE-SEARCH
PHP -S localhost:4000 
```

Now you can access the website in the link http://localhost:4000


