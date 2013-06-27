#!/usr/bin/env ruby

require "rubygems"
require "json"
require "pp"
require "themoviedb"

Tmdb::Api.key("11433deecaf09ef3aa3fb68d7e02a772")

DBFILE = ".coindb.json"
DB_LOCATION = "~/"

class ::Hash
  def method_missing(name)
    return self[name] if key? name
    self.each { |k,v| return v if k.to_s.to_sym == name }
    super.method_missing name
  end
end


class MoviePool
  
  def initialize
    self.read_database
  end
  
  def read_database()
    db_path = DB_LOCATION + DBFILE
    if File.exists? File.expand_path(db_path):
      json = File.read(File.expand_path(db_path))
      @movies = JSON.parse(json)
    end
  end

  def write_database
    File.open(File.expand_path(DB_LOCATION + DBFILE), "w") { |f| f.write(@movies.to_json) }
  end

  def flip
    self.read_database
    pool = []

    @movies.each do |tmdb, movie|
      weight = movie.rating * 10
      weight.to_i.times do pool << tmdb end
    end

    random_movie = @movies[pool.choice]
    return random_movie
  end

  def add(title, uri=nil)
    self.read_database
    movie = Tmdb::Movie.find(title)[0]
    @movies[movie.id.to_s] = {"title" => movie.title,
                              "rating" => movie.vote_average,
                              "tmdb" => movie.id,
                              "released" => movie.release_date}
    @movies[movie.id.to_s]["uri"] = uri if uri
    self.write_database
    puts "Added #{ movie.title } (#{ movie.release_date[0..3] })"
  end

  def list
    self.read_database
    puts "TMDB ID - Title\n\n"
    @movies.each do |key, movie|
      puts "#{ key } - #{ movie.title } (#{ movie.released[0..3] })"
    end
  end

  def remove(tmdb)
    self.read_database
    @movies.delete(tmdb)
    self.write_database
  end

end

if __FILE__ == $0
  action = ARGV[0]
  pool = MoviePool.new
  case action
  when "flip", "f"
    movie = pool.flip
    puts movie.title if movie
  when "watch", "w"
    if ARGV[1]
      pool.watch ARGV[1]
    else
      pool.watch
    end
  when "add", "a"
    if ARGV[2]
      # TODO URI validation
      pool.add(ARGV[1], ARGV[2])
    else
      pool.add ARGV[1]
    end
  when "list", "l"
    pool.list
  when "rm", "del", "delete", "remove", "d"
    pool.remove ARGV[1]
  end
end
