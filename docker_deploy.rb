#!/usr/bin/env ruby

name = 'conditioner'
require "./lib/legion/extensions/#{name}/version"
version = Legion::Extensions::Conditioner::VERSION

puts "Building docker image for Legion v#{version}"
system("docker build --tag legionio/lex-#{name}:v#{version} .")
puts 'Pushing to hub.docker.com'
system("docker push legionio/lex-#{name}:v#{version}")
system("docker push legionio/lex-#{name}:latest")
puts 'completed'
