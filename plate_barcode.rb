# frozen_string_literal: true

RAILS_ENV = (ENV['RAILS_ENV'] ||= 'development')

require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'builder'
require 'sinatra'
require './lib/deployed_version'

# Establish a connection to the database.  If we're in development mode then the database
# connection should be made to behave like one to an Oracle DB.
ActiveRecord::Base.establish_connection(
  YAML.load_file('config/database.yml')[RAILS_ENV]
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
    new(next_sequence)
  end

  def self.next_sequence
    ActiveRecord::Base.connection.next_sequence_value('SEQ_DNAPLATE')
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end

  attr_reader :number
  private_class_method :new

  def initialize(number)
    @number = number.to_i
  end

  def to_xml
    presenter.to_xml
  end

  private

  def presenter
    Presenter.new(self)
  end

  # Class used by XML builder to render the barcode
  class Presenter
    def initialize(barcode)
      @barcode = barcode
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.plate_barcodes { xml.barcode(@barcode.number) }
      xml.target!
    end
  end
end

helpers do
  def version_string
    "#{Deployed::APP_NAME} [#{RAILS_ENV}] #{Deployed::RELEASE_NAME}"
  end
end

post '/plate_barcodes.xml' do # fortunately, POST will not get stuck in cache
  content_type 'application/xml', charset: 'utf-8'
  body Barcode.create.to_xml
end

get '/' do
  content_type 'text/plain', charset: 'utf-8'
  version_string
end
