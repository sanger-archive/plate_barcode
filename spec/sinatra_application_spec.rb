# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require './plate_barcode'
require 'rspec'
require 'pry'

RSpec.describe 'Sinatra::Application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /' do
    before { get '/' }

    it 'returns ok' do
      expect(last_response).to be_ok
    end

    it 'prints a version string' do
      expect(last_response.body).to eq('Plate Barcode [test] LOCAL')
    end
  end

  describe 'POST /plate_barcodes.xml' do
    before do
      allow(ActiveRecord::Base.connection).to receive(:next_sequence_value)
        .with('SEQ_DNAPLATE')
        .and_return(1)
      post '/plate_barcodes.xml'
    end

    it 'returns ok' do
      expect(last_response).to be_ok
    end

    it 'prints a barcode object' do
      expect(last_response.body).to eq(
        '<?xml version="1.0" encoding="UTF-8"?><plate_barcodes><barcode>1</barcode></plate_barcodes>'
      )
    end
  end
end
