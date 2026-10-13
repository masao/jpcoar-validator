#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require "open3"

require_relative "validator.rb"

class JPCOARValidatorSchematron < JPCOARValidator
  SVRL_NAMESPACE = "http://purl.oclc.org/dsdl/svrl"

  def initialize(url,
                 xslt: "xslt/jpcoar2.0.xsl")
    super(url)
    @xslt = xslt
  end

  def validate_jpcoar(metadata, identifier = nil)
    result = validate_xml_schema(metadata, identifier)
    #p identifier

    svrl = schematron_validate(metadata.to_s)
    parse_svrl(svrl, result, identifier)

    result
  end

  private
  def schematron_validate(xml)
    uri = URI("http://127.0.0.1:9000/validate")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/xml"
    request.body = xml

    response = Net::HTTP.start(
      uri.hostname,
      uri.port
    ) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Schematron validation failed: #{response.body}"
    end

    response.body
  end

  def parse_svrl(svrl, result, identifier)
    parser = LibXML::XML::Parser.string(svrl)
    doc = parser.parse

    doc.find(
      "//svrl:failed-assert | //svrl:successful-report",
      "svrl:#{SVRL_NAMESPACE}"
    ).each do |node|
      role = node.attributes["role"]
      level =
        case role
        when "warn"
          :warn
        when "info"
          :info
        else
          :error
        end

      text = node.find(
        "./svrl:text",
        "svrl:#{SVRL_NAMESPACE}"
      ).first

      error = {
        message: text&.content&.strip,
        identifier: identifier,
      }

      if id = node.attributes["id"]
        error[:error_id] = id.to_sym
      end

      if flag = node.attributes["flag"]
        error[:link] = flag.to_sym
      end

      result[level] << error
    end
  end
end

if $0 == __FILE__
   options = {
      :max => 20
   }
   opt = OptionParser.new
   opt.on( '--max VAL'   ){|v| options[ :max ] = v }
   opt.on( '--from VAL'  ){|v| options[ :from ] = v }
   opt.on( '--until VAL' ){|v| options[ :until ] = v }
   opt.parse!( ARGV )
   ARGV.each do |url|
      p url
      validator = JPCOARValidatorSchematron.new( url )
      result = validator.validate( options )
      [ :info, :error, :warn ].each do |k|
         puts "Total #{ result[ k ].size } #{ k }:"
         pp result[ k ]
      end
      if result[ :next_token ]
         puts "resumptionToken: #{ result[ :next_token ].inspect }"
      end
   end
end
