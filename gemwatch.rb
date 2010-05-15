require 'sinatra'
require 'haml'
require 'restclient'
require 'json'

require 'open-uri'

DOWNLOAD_BASE = File.join(File.dirname(__FILE__), 'tmp', 'download')

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
  class CommandFailed < Exception; end
  def initialize(gemname)
    begin
      @data = JSON.parse(RestClient.get("http://rubygems.org/api/v1/gems/#{gemname}.json").body)
    rescue RestClient::ResourceNotFound
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
  def info
    @data['info']
  end
  def gem
    File.basename(uri)
  end
  def run(cmd)
    system(cmd)
    if $? && ($? >> 8) > 0
      raise GemWatch::Gem::CommandFailed, "[#{cmd} failed!]"
    end
  end
  def download(uri)
    open(uri, 'rb') do |downloaded_gem|
      File.open(gem, 'wb') do |file|
        file.write(downloaded_gem.read)
      end
    end
  end
  def download_and_convert!
    unless File.exist?(tarball_path)
      FileUtils.rm_rf(absolute_directory)
      FileUtils.mkdir_p(absolute_directory)
      Dir.chdir(absolute_directory) do
        download uri
        run "tar xfm #{gem}"
        run "tar xzfm data.tar.gz"
        run "zcat metadata.gz > metadata.yml"
        FileUtils.rm_f([gem, "data.tar.gz", "metadata.gz"])
      end
      Dir.chdir(File.dirname(absolute_directory)) do
        run "tar czf #{tarball} #{directory}"
        FileUtils.rm_rf(directory)
      end
    end
  end
  def directory
    "#{name}-#{version}"
  end
  def download_dir
    @download_dir ||= File.join(DOWNLOAD_BASE, name[0..0], name)
  end
  def absolute_directory
    File.join(download_dir, directory)
  end
  def tarball
    "#{directory}.tar.gz"
  end
  def tarball_path
    File.join(download_dir, tarball)
  end
  def archived
    @archived ||= Dir.glob(File.join(download_dir, '*.tar.gz')).map { |f| File.basename(f) }
  end
  def archived?(tarball)
    archived.include?(tarball)
  end
  def archived_path(tarball)
    File.join(download_dir, tarball)
  end
  def download_for(wanted_version)
    tarball = "#{name}-#{wanted_version}.tar.gz"
    if archived?(tarball)
      archived_path(tarball)
    else
      if wanted_version == version
        download_and_convert!
        tarball_path
      else
        raise GemWatch::Gem::NotFound
      end
    end
  end
end
module HostHelper
  def host_with_port
    if request.respond_to?(:host_with_port)
      request.host_with_port
    else
      request.host + ([80,443].include?(request.port) ? '' : (':' + request.port.to_s))
    end
  end
end

helpers GemWatch, HostHelper

get '/?' do
  expires 86400, :public  # 1 day
  if params[:gem]
    redirect app_url("/#{params[:gem]}")
  else
    haml :index
  end
end

get '/:gem' do
  expires 14400, :public # 4 hours
  begin
    @gem = GemWatch::Gem.new(params[:gem])
    haml :gem
  rescue GemWatch::Gem::NotFound
    not_found
  end
end

get '/download/:tarball' do
  expires 86400000, :public # 1000 days, published versions are supposed to not change
  begin
    params[:tarball] =~ /^(.+)-(.+).tar.gz$/
    gem_name = $1
    gem_version = $2

    gem = GemWatch::Gem.new(gem_name)
    send_file gem.download_for(gem_version)
  rescue GemWatch::Gem::NotFound
    not_found
  end
end

not_found do
  haml :not_found
end

error 500 do
  haml :error
end

__END__
@@ layout
%html
  %head
    %meta{"http-equiv" => "content-type", :content => "text/html;charset=UTF-8"}
    %title= [@title, "Gemwatch"].compact.join(' - ')
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
- @title = @gem.name
%h1= 'Gem watch: %s' % @gem.name
%blockquote= @gem.info
%h2 Available downloads
%p
  Most recent version:
  %a{:href => app_url("/download/#{@gem.tarball}")}= @gem.tarball
- unless @gem.archived.empty?
  %p
    Archived versions:
    %ul
      - @gem.archived.reverse.each do |filename|
        %li
          %a{:href => app_url("/download/#{filename}")}= filename
%h2 Usage in debian/watch file
%p Use the following in your <code>debian/watch</code> file:
%pre= "version=3\nhttp://#{host_with_port}#{app_url('/'+ @gem.name)} .*/#{@gem.name}-(.*)\.tar\.gz"
%a{:href => app_url("/")} Try another gem
@@ not_found
- @title = "Not Found"
- @body_class = 'not-found'
%h1 Not Found
%p Sorry, we couldn't find a gem with such name (or version)
%a{:href => app_url("/")} Try again
@@ error
- @title = 'Internal error'
- @body_class = 'internal-error'
%h1 Internal error
%p Sorry, gemwatch detected an internal error and cannot continue with your request.
%a{:href => app_url('/')} Start over
