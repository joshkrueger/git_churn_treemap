#!/usr/bin/ruby

require 'pp'
require 'rubygems'
require 'json'

def sort_index
  return 0 if ARGV.include?("-commits")
  return 1 if ARGV.include?("-changes")
  0
end

def usage
  puts "git_churn_rate [|-commits|-changes]"
  puts 
  puts "Sort:"
  puts "\t-commits\tSorts output by total number of commits per file"
  puts "\t-changes\tSorts output by total number of changes per file"
  puts
  puts "Other:"
  puts "\t-help\t Shows this stupid message"
end

def children_count(h)
  if h.instance_of? Hash
    total = 0

    h.keys.each do |k|
      total += children_count(h[k])
    end

    return total
  else
    return h[sort_index] if h.instance_of? Array
  end
end

def output_tree_data(h)
  if h.instance_of? Hash
    h.keys.map  do |k|
      tmp = output_tree_data(h[k])
      count = children_count(h[k])
      if tmp.instance_of? Hash and tmp.key? "$area"
        { :name => "#{k} #{count}", :data => tmp }
      else
        { :name => "#{k} #{count}", :data => {"$area" => count}, :children => tmp }
      end
    end
  else
    return {"$area" => h[sort_index]}
  end
end

def main
  data = Hash.new { |h, k| h[k] = Array.new }

  magic_hash = Hash.new { |h, k| h[k] = Hash.new &h.default_proc }

  STDIN.read.split("\n").each do |line|
    insert, delete, file = line.split("\t")
    data[file] = [] unless data.key?(file)
    data[file] << insert.to_i + delete.to_i
  end

  churn = data.to_a.map! do |d|
    [ d[0], d[1].length, d[1].reduce{|sum, n| sum + n.to_i} ]
  end

  churn.each do |c|
    filename = c.shift.split("/").map{ |i| "['#{i}']" }.join()
    eval "magic_hash#{filename} = c"
  end

  count = children_count(magic_hash)
  tree_map = { :children => output_tree_data(magic_hash), :data => { '$area' => count }, :name => "/ #{count}" }

  puts "var kTree = #{tree_map.to_json}"

end

if ARGV.include?("-help") or ARGV.include?("-h") or ARGV.include?("--help") or ARGV.include?("--h")
  usage()
else
  main()
end
