#\ -w -p 3011
# frozen_string_literal: true

require './plate_barcode'

disable :run, :reload

run Sinatra::Application
