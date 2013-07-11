#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'em-rocketio-linda-client'
require 'base64'

rec_cmd = "/usr/bin/rec"
rec_file = "/tmp/rec-play.mp3"

EM::run do
  url   = ENV["LINDA_BASE"]  || ARGV.shift || "http://localhost:5000"
  space = ENV["LINDA_SPACE"] || "test"
  puts "connecting.. #{space} at #{url}"
  linda = EM::RocketIO::Linda::Client.new url
  ts = linda.tuplespace[space]

  linda.io.on :connect do
    puts "connect!! <#{linda.io.session}> (#{linda.io.type})"

    EM::defer do
      system "#{rec_cmd} #{rec_file}"
    end

    EM::add_timer 3 do
      system "pkill -f '#{rec_cmd}'"
      File.open rec_file do |f|
        ts.write ["audio", "play", "base64", Base64.encode64(f.read)]
      end
      puts "write"
      EM::add_timer 3 do
        EM::stop
      end
    end
  end

  linda.io.on :disconnect do
    puts "RocketIO disconnected.."
    exit 1
  end
end

