#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# $:.push(File.join(File.dirname(__FILE__), 'lib'))
# require 'rubygems'
# require "bundler"
# Bundler.setup

require "net/smtp"

from = "from@example.com"
to   = "to@example.com"

body = <<EOT
From: #{from}
To: #{to}
Subject: test
Date: #{Time::now.strftime("%a, %d %b %Y %X %z")}

Hi,

This is US-ASCII mail test.
EOT

Net::SMTP.start("localhost", 25) {|smtp| smtp.send_mail body, from, to }

# if __FILE__ == $0
# end

__END__
