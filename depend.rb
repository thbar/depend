require "bundler"
Bundler.require(:default)

require "json"
require 'sinatra/reloader' if development?

get "/" do
  erb :index
end

get "/search" do
  if !params[:gem].empty?
    redirect "/gem/#{params[:gem]}"
  else
    redirect "/"
  end
end

get "/gem/:name" do
  results = rubygems_get(gem_name: params[:name], endpoint: "reverse_dependencies?only=runtime")

  weighted_results = {}

  results.each do |name|
    begin
      weighted_results[name] = rubygems_get(gem_name: name)["downloads"]
    rescue => e
      puts "API Error for #{name}: #{e.message}"
    end
  end

  @gems = []

  sorted_by_download_count = weighted_results.sort do |(name1, count1), (name2, count2)|
    count2 <=> count1
  end

  sorted_by_download_count.first(50).each do |(name, count)|
    @gems << { name: name, downloads: count }
  end

  erb :gem
end

private

def rubygems_get(gem_name: "", endpoint: "")
  path = File.join("/api/v1/gems/", gem_name, endpoint).chomp("/") + ".json"
  response = connection.get(path)
  JSON.parse(response.body)
end

def connection
  @connection ||= begin
    conn = Faraday.new(url: "https://rubygems.org") do |faraday|
      faraday.adapter :httpclient
    end
  end
end
