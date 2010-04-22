require 'sinatra'
require 'haml'
require 'restclient'
require 'json'

DOWNLOAD_DIR = File.join(File.dirname(__FILE__), 'tmp', 'download')

class WatchedGem
  def initialize(gemname)
    @data = JSON.parse(RestClient.get("http://rubygems.org/api/v1/gems/#{gemname}.json").body)
  end
  def name
    @data['name']
  end
  def version
    @data['version']
  end
  def uri
    @data['gem_uri']
  end
  def gem
    File.basename(uri)
  end
  def download_and_convert!
    unless File.exist?(tarball_path)
      system "rm -rf #{absolute_directory}*"
      system "mkdir -p #{absolute_directory}"
      Dir.chdir(absolute_directory) do
        system "wget #{uri}"
        system "tar xf #{gem}"
        system "tar xzf data.tar.gz"
        system "zcat metadata.gz > metadata.yml"
        system "rm -f data.tar.gz metadata.gz"
      end
      Dir.chdir(File.dirname(absolute_directory)) do
        system "tar czf #{tarball} #{directory}"
        system "rm -rf #{directory}"
      end
    end
  end
  def directory
    "#{name}-#{version}"
  end
  def absolute_directory
    File.join(DOWNLOAD_DIR, directory)
  end
  def tarball
    "#{directory}.tar.gz"
  end
  def tarball_uri
    "/#{File.basename(DOWNLOAD_DIR)}/#{tarball}"
  end
  def tarball_path
    File.join(DOWNLOAD_DIR, tarball)
  end
end

get '/' do
  if params[:gem]
    redirect "/#{params[:gem]}"
  else
    haml :index
  end
end

get '/:gem' do
  begin
    @gem = WatchedGem.new(params[:gem])
    haml :gem
  rescue RestClient::ResourceNotFound
    not_found
  end
end

get '/download/:tarball' do
  begin
    params[:tarball] =~ /^(.+)-(.+).tar.gz$/
      gemname = $1
    gem = WatchedGem.new(gemname)
    gem.download_and_convert!
    expires 86400000 # 1000 days, published versions are supposed to not change
    send_file gem.tarball_path
  rescue RestClient::ResourceNotFound
    not_found
  end
end

not_found do
  haml :not_found
end

__END__
@@ layout
%html
  %head
    %link{:rel => "stylesheet", :type => "text/css", :href => "/style.css"}
  %body
    =yield
@@ index
%h1 Gem watch
%form
  Gem name:
  %input{:type => "text", :name => "gem"}
  %input{:type => "submit", :value => "Watch"}
@@ gem
%h1= 'Gem watch: %s' % @gem.name
%a{:href => "/download/#{@gem.tarball}"}= @gem.tarball
@@ not_found
%h1 Sorry, couldn't find a gem with such name
