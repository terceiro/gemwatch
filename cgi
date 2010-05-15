#!/usr/bin/env ruby

gemwatch_dir = File.symlink?(__FILE__) ? File.dirname(File.readlink(__FILE__)) : File.dirname(__FILE__)
$:.unshift gemwatch_dir
require 'gemwatch'

GemWatch.prefix = ENV["SCRIPT_NAME"]
GemWatch.assets_path = "/gemwatch"

Rack::Handler::CGI.run Sinatra::Application
