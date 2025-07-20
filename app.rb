require "sinatra"
require "erb"

require_relative "validator.rb"

class App < Sinatra::Base
  get "/" do
    @url = params[ "url" ]
    @options = {}
    [ :from, :until, :set, :resumptionToken ].each do |k|
      next if params[ k.to_s ].nil? or params[ k.to_s ].empty?
      @options[ k ] = params[ k.to_s ]
    end
    @data = nil
    if not @url.nil? and not @url.empty? and not @url == "http://"
      @validator = JPCOARValidator.new( @url )
      @data = @validator.validate( @options )
    end
    erb :index
  end

  post "/" do
    @xml = params[ "xml" ]
    @options = {}
    @data = nil
    if not @xml.nil? and not @xml.empty?
      @validator = JPCOARValidatorFromString.new( @xml )
      @data = @validator.validate
    end
    erb :index
  end

  helpers ERB::Util
  helpers do
    def help_url
      #obsolete: "http://drf.lib.hokudai.ac.jp/drf/index.php?tech%2Fnote%2Fgeneral%2FOAI-PMH%20validator"
      "https://github.com/masao/jpcoar-validator/wiki/Help"
    end
    def last_modified
      %w(app.rb validator.rb views/index.erb).map{|f| File.mtime f }.sort[-1]
    end
  end
end
