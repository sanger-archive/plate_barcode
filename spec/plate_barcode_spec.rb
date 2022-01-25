ENV['RAILS_ENV'] = 'test'

require './plate_barcode'
require 'rspec'
require 'pry'

RSpec.describe 'The PlateBarcode service' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /' do
    it "prints a version string" do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('Plate Barcode [test] LOCAL')
    end
  end

  describe 'POST /plate_barcodes.xml' do
    before do
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::NullDBAdapter).to receive(:next_sequence_value).with('SEQ_DNAPLATE').and_return(1)
    end

    it "prints a barcode object" do
      post '/plate_barcodes.xml'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('<?xml version="1.0" encoding="UTF-8"?><plate_barcodes><barcode>1</barcode></plate_barcodes>')
    end
  end
end
