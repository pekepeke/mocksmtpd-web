#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# $:.push(File.join(File.dirname(__FILE__), 'lib'))
# require 'rubygems'
# require "bundler"
# Bundler.setup
require 'sinatra'
require 'erubis'
# require "sinatra/reloader" if development?

set :erubis, :escape_html => true
# enable :sessions, :logging
enable :logging

set :public_folder, File.dirname(__FILE__) + "/public"
set :inbox_folder, File.dirname(__FILE__) + "/inbox"

configure :production do
  disable :dump_errors
end

configure :development do
end
configure :test do
end

helpers do
  include Rack::Utils
  alias :h :escape_html
end

before do
  #
end
after do
  #
end

get '/' do
  fpath = File.join(settings.inbox_folder, 'index.html')
  if File.exists? fpath
    @body = File.read(fpath).gsub(/href="(.*)\.html"/, 'href="/inbox/\1"')

    @body = @body[@body.index("<table>")..@body.rindex("</table>")] + "/table>"
  else
    @body = '<p class="lead text-warning">You have not received email yet...</p>'
  end
  erb :index
end

get '/inbox' do
  redirect '/'
end

get '/inbox/:id' do
  fpath = File.join(settings.inbox_folder, params[:id]+'.html')

  if File.exists? fpath
    @body = File.read(fpath).gsub(/href="(.*)\.html"/, 'href="/inbox/\1"')

    @body = @body[@body.index("<h1")..@body.rindex("</div>")] + "/div>"
    @nav = "inbox/#{params[:id]}"
    erb :inbox
  else
    @body = '<p class="lead text-error">mail not found</p>'
    erb :inbox
  end
end

get '/operation/clear' do
  Dir.glob(File.join(settings.inbox_folder, '*.html')) do |f|
    puts f
    File.unlink(f)
  end
  redirect '/'
end

if __FILE__ == $0
end


__END__
@@layout
<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="utf-8">
    <title>MockSMTPD Web</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">
    <meta name="robots" content="noindex, nofollow"/>

    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <style>
      body {
        padding-top: 60px; /* 60px to make the container go all the way to the bottom of the topbar */
      }
      .container {
        padding: 0 60px 0 60px;
      }
    </style>
    <link href="/css/bootstrap-responsive.min.css" rel="stylesheet">

    <script src="/js/jquery-1.9.0.min.js"></script>
    <script src="/js/bootstrap.min.js"></script>

    <!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
    <script src="//html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <script src="//css3-mediaqueries-js.googlecode.com/svn/trunk/css3-mediaqueries.js"></script>
    <![endif]-->
    <script>//<![[CDATA[
      !function($, Global) {
        $(function() {
          $('table')
            .addClass('table table-hover');
        })
      }(jQuery, this);
//]]></script>

    <link rel="shortcut icon" href="/favicon.ico">
    <!-- Le fav and touch icons -->
    <!--
    <link rel="apple-touch-icon" href="images/apple-touch-icon.png">
    <link rel="apple-touch-icon" sizes="72x72" href="images/apple-touch-icon-72x72.png">
    <link rel="apple-touch-icon" sizes="114x114" href="images/apple-touch-icon-114x114.png">
    -->
  </head>
  <body>
    <div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand" href="/">MockSMTPD</a>
          <div class="nav-collapse">
            <ul class="nav">
              <li <%= @nav.nil? ? 'class="active"' : "" %>><a href="/"><i class="icon-envelope icon-white"></i> Inbox</a></li>
              <li class="dropdown">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                  <i class="icon-edit icon-white"></i> Operation
                  <b class="caret"></b>
                </a>
                <ul class="dropdown-menu">
                  <li><a href="/operation/clear"><i class="icon-trash"></i> Clear</a></li>
                </ul>
              </li>
            </ul>
          </div><!--/.nav-collapse -->
        </div>
      </div>
    </div>

    <div class="container">

      <%= yield.trust %>

    </div> <!-- /container -->
  </body>
</html>

@@index
  <h1>Inbox</h1>
  <%= @body.trust %>

@@inbox
  <%= @body.trust %>


