# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.setup
require 'sinatra'
require 'active_record'

APP_ROOT = File.dirname(File.expand_path(__FILE__))
RAILS_ENV = (ENV['RAILS_ENV'] ||= 'development')

helpers do
  def version_string
    require File.join(APP_ROOT, 'lib/versionstrings')
    "#{Deployed::APP_NAME} [#{RAILS_ENV}] #{Deployed::RELEASE_NAME}"
  end
end

# Establish a connection to the database.  If we're in development mode then the database
# connection should be made to behave like one to an Oracle DB.
ActiveRecord::Base.establish_connection(
  YAML.safe_load(File.open(File.join(APP_ROOT, 'config/database.yml')))[
    RAILS_ENV
  ]
)

# This isn't the best:
# - Installing oracle gems on a development system is a pain, so we use an alternative database adapter
# - But in practice we don't actually want anything, as we're just going to mock it all
# - So we use a null database adapter
# - But that doesn't actually support next_sequence_value
# - So we monkey patch it in.
# - I'm hoping to come up with a better solution here? Postgres?
if %w[development test].include?(RAILS_ENV)
  module ActiveRecord
    module ConnectionAdapters
      # Re-open the NullDBAdapter gem for monkeypatching in a next_sequence_value method
      class NullDBAdapter
        def next_sequence_value(_name)
          @sequence ||= 0
          @sequence += 1
        end
      end
    end
  end
end

# Wraps the counter to generate a simple barcode object consisting of an integer
class Barcode
  def self.create
    new(ActiveRecord::Base.connection.next_sequence_value('SEQ_DNAPLATE'))
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end

  def initialize(number)
    @number = number
  end
  private_class_method :new

  def number
    @number.to_i
  end

  def present_in_xml
    Presenter.new(self)
  end

  require 'builder'

  # Class used by XML builder to render the barcode
  class Presenter
    def initialize(barcode)
      @barcode = barcode
    end

    def write(output)
      output.content_type('application/xml', charset: 'utf-8')
      output.body(to_xml)
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.plate_barcodes { xml.barcode(@barcode.number) }
      xml.target!
    end
  end
end

post '/plate_barcodes.xml' do # fortunately, POST will not get stuck in cache
  Barcode.create.present_in_xml.write(self)
end

get '/' do
  content_type 'text/plain', charset: 'utf-8'
  version_string
end
