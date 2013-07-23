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

class Sinatra::Request
  def pjax?
    env['HTTP_X_PJAX'] || self["_pjax"]
  end
  def ajax?
    env['HTTP_X_REQUESTED_WITH'] == "XMLHttpRequest"
  end
end

get '/' do
  fpath = File.join(settings.inbox_folder, 'index.html')
  if File.exists? fpath
    @body = File.read(fpath)
      .encode("utf-16be", "utf-8", {
              :invalid => :replace,
              :undef => :replace,
              :replace => '〓'})
      .encode('utf-8')
      .gsub(/href="(.*)\.html"/, 'href="/inbox/\1"')

    @body = @body[@body.index("<table>")..@body.rindex("</table>")]
      .gsub(/<table>/, '<table class="table table-hover">') + "/table>"
  else
    @body = '<p class="lead text-warning">You have not received email yet...</p>'
  end
  erb :index, :layout => !(request.pjax? || request.ajax?)
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
    erb :inbox, :layout => !request.pjax?
  else
    @body = '<p class="lead text-error">mail not found</p>'
    erb :inbox, :layout => !(request.pjax? || request.ajax?)
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
        padding-bottom: 30px;
      }
      .container {
        padding: 0 60px 0 60px;
      }
    </style>
    <link href="/css/bootstrap-responsive.min.css" rel="stylesheet">

    <script src="/js/jquery-1.9.0.min.js"></script>
    <script src="/js/jquery.pjax.js"></script>
    <script src="/js/bootstrap.min.js"></script>

    <!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
    <script src="//html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <script src="//css3-mediaqueries-js.googlecode.com/svn/trunk/css3-mediaqueries.js"></script>
    <![endif]-->
    <script>//<![[CDATA[
      !function($, Global) {
        $(function() {
          $(document).pjax('a', '.pjax-container')
          // navbar collapse
          $('.navbar-inner a').on('click', function() {
            if (!$(this).data('target') && !$(this).data('toggle')) {
              var $link = $('a[data-toggle="collapse"]')
                , $target = $($link.data('target'));
              if ($target.hasClass('in')) {
                $link.trigger('click');
              }
            }
          });
          (function (w, r, c) {
            w['r'+r] = w['r'+r] || w['webkitR'+r] || w['mozR'+r] || w['msR'+r] || w['oR'+r] || function(f){ w.setTimeout(f, 1000 / 60); };
            w['c'+c] = w['c'+c] || w['webkitC'+c] || w['mozC'+c] || w['msC'+c] || w['oC'+c] || function(t){ w.clearTimeout(t); };
          })(window, 'equestAnimationFrame', 'ancelRequestAnimationFrame');
          var timer_id = null
            , latest_path = null
            , latest_selector = '.nav li:first a';
          function get_latest_path() {
            return $('.table td a:first').attr('href');
          }
          setInterval(function() {
            if (location.pathname == "/") {
              cancelRequestAnimationFrame(timer_id);
              latest_path = get_latest_path();
              timer_id = requestAnimationFrame(function() {
                $.get("?" + new Date().getTime()).done(function(html) {
                  $('.pjax-container').html(html);
                  var received_latest_path = get_latest_path();
                  if (latest_path != received_latest_path) {
                    window.scrollTo(0, 0);
                  }
                });
                // console.log("reload" + new Date().toString())
              });
            }
          }, 5000);
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
          <a class="btn btn-navbar" data-toggle="collapse" data-bypass="" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand hidden-desktop" href="/">MockSMTPD</a>
          <div class="nav-collapse collapse">
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

    <div class="container pjax-container">

      <%= yield.trust %>

    </div> <!-- /container -->
  </body>
</html>

@@index
  <h1>Inbox</h1>
  <%= @body.trust %>

@@inbox
  <%= @body.trust %>


