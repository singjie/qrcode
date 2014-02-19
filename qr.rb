require 'sinatra'
require 'uri'
require 'mini_magick'
require 'open-uri'
require 'cgi'

def to_image url, size
  #https://google-developers.appspot.com/chart/infographics/docs/qr_codes
  
  escaped_url = CGI::escape(url)
  
  #enc_uri = URI.escape("http://chart.apis.google.com/chart?cht=qr&chs=#{size}x#{size}&chl=#{escaped_url}&chld=H|0")
  
  enc_uri = "http://chart.apis.google.com/chart?cht=qr&chs=#{size}x#{size}&chl=#{escaped_url}&chld=#{CGI::escape("H|0")}"
  
  puts "Encoded URL #{enc_uri}"
  
  data = open(enc_uri).read
  
  image = MiniMagick::Image.read(data)
  
  result = image.composite(MiniMagick::Image.open("icon.png")) do |c|
    c.gravity "center"
  end
  
  content_type 'application/octet-stream'
  attachment("qrcode.png")
  
  result.to_blob
end

get '/' do
  erb :index
end

post '/qrcode' do
  hash = params[:qr]
  
  url = hash["url"]
  
  unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
    url = "http://#{url}"
  end
  
  utm_params = []
  hash.each do |key, value|
    next if key == "url"
    next if value.nil? || value.empty?
    utm_params << "#{key}=#{value}"
  end
  
  if utm_params.count > 0
    url += "?"
    url += utm_params.join("&")
  end
  
  puts "Final URL: #{url}"
  
  image = to_image(url, 480)
end