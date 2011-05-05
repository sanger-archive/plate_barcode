require 'rubygems'
require 'bundler'
Bundler.setup
require 'sinatra'
require 'active_record'

APP_ROOT = File.dirname(File.expand_path(__FILE__))
RAILS_ENV = (ENV['RAILS_ENV'] ||= 'development')
@@database = YAML::load(File.open( File.join(APP_ROOT,'config/database.yml') ))

helpers do
  def get_version_string
    require File.join(APP_ROOT,'lib/versionstrings')
    Deployed::VERSION_STRING
  end
end

class DnaPlate < ActiveRecord::Base
  set_sequence_name "SEQ_DNAPLATE"
  set_table_name "DNA_PLATE"
  set_primary_key "ID_DNAPLATE"

  def self.next_value
    if RAILS_ENV == 'development'
      return rand(100000)
    end
    self.connection.next_sequence_value(self.sequence_name)
  end
end

post '/plate_barcodes.xml' do # fortunately, POST will not get stuck in cache
  DnaPlate.establish_connection(
    @@database["#{RAILS_ENV}_snp"]
  )
  content_type 'application/xml', :charset => 'utf-8'
  <<-_EOF_
<?xml version="1.0" encoding="UTF-8"?><plate_barcodes><barcode>#{DnaPlate.next_value}</barcode></plate_barcodes>
_EOF_
end

get '/' do
  content_type 'text/plain', :charset => 'utf-8'
  get_version_string
end
