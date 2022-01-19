#\ -w -p 3011
require "./plate_barcode"
disable :run, :reload

run Sinatra::Application
