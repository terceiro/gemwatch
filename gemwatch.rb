require 'sinatra'
require 'haml'
require 'restclient'
require 'json'

DOWNLOAD_DIR = File.join(File.dirname(__FILE__), 'tmp', 'download')

module GemWatch
  class << self
    attr_accessor :assets_path, :prefix
  end
  self.assets_path = ""
  self.prefix = ""
  def asset_url(url)
    GemWatch.assets_path + url
  end
  def app_url(url)
    GemWatch.prefix + url
  end
end

class GemWatch::Gem
  class NotFound < Exception; end
  def initialize(gemname, wanted_version = nil)
    begin
      @data = JSON.parse(RestClient.get("http://rubygems.org/api/v1/gems/#{gemname}.json").body)
    rescue RestClient::ResourceNotFound
      raise GemWatch::Gem::NotFound
    end
    if wanted_version && wanted_version != version
      raise GemWatch::Gem::NotFound
    end
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
        system "rm -f #{gem} data.tar.gz metadata.gz"
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

helpers GemWatch

get '/?' do
  if params[:gem]
    redirect app_url("/#{params[:gem]}")
  else
    haml :index
  end
end

get '/:gem' do
  begin
    @gem = GemWatch::Gem.new(params[:gem])
    haml :gem
  rescue GemWatch::Gem::NotFound
    not_found
  end
end

get '/download/:tarball' do
  begin
    params[:tarball] =~ /^(.+)-(.+).tar.gz$/
    gem_name = $1
    gem_version = $2

    gem = GemWatch::Gem.new(gem_name, gem_version)
    gem.download_and_convert!
    expires 86400000, :public # 1000 days, published versions are supposed to not change
    send_file gem.tarball_path
  rescue GemWatch::Gem::NotFound
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
    %link{:rel => "stylesheet", :type => "text/css", :href => asset_url("/style.css")}
  %body{:class => @body_class}
    %div.wrap
      =yield
    %script{:src => "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js", :type => "text/javascript", :charset => "utf-8"}
    %script{:src => asset_url("/gemwatch.js"), :type => "text/javascript", :charset => "utf-8"}
@@ index
%h1 Gem watch
%form
  Gem name:
  %input{:type => "text", :name => "gem", :id => "gem"}
  %input{:type => "submit", :value => "Watch"}
@@ gem
%h1= 'Gem watch: %s' % @gem.name
%h2 Available downloads
%ul
  %li
    %a{:href => app_url("/download/#{@gem.tarball}")}= @gem.tarball
%h2 Usage in debian/watch file
%p Use the following in your <code>debian/watch</code> file:
%pre= "version=3\nhttp://#{request.host_with_port}#{app_url('/'+ @gem.name)} .*/#{@gem.name}-(.*)\.tar\.gz"
%a{:href => app_url("/")} Try another gem
@@ not_found
- @body_class = 'not-found'
%h1 Not Found
%p Sorry, we couldn't find a gem with such name (or version)
%a{:href => app_url("/")} Try again
