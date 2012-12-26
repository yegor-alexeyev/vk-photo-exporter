#!/usr/bin/env ruby
# encoding: UTF-8
require 'vk-ruby'
require 'mechanize'

client_id = ARGV[0]
client_login = ARGV[1]
client_password = ARGV[2]
uid = ARGV[3]

agent = Mechanize.new
login_page = agent.get 'http://vk.com'
login_page.forms.first.email = client_login
login_page.forms.first.pass = client_password
agent.submit login_page.forms.first

params = {:client_id => client_id, :settings => 'friends,photos',:display => :page,:redirect_uri => 'http://oauth.vk.com/blank.html',:response_type => :token}

page = agent.get 'http://oauth.vk.com/authorize?' + (params.map{|k,v| "#{k}=#{v}" }).join('&')
reg = /^http:\/\/oauth\.(vkontakte\.ru|vk\.com)\/.+\#access_token=(.*?)&expires_in=(.*?)&user_id=(.*?)$/
access_token, expires_in, user_id = *(page.uri).to_s.match(reg)[2..4]

app = VK::Application.new access_token: access_token

((app.photos.getAlbums uid: uid) +
 [{'title' => 'Фотографии со страницы', 'aid' => 'profile', 'owner_id' => uid,'description' => ''},
 {'title' => 'Фотографии на стене', 'aid' => 'wall', 'owner_id' => uid,'description' => ''},
 {'title' => 'Сохраненные фотографии', 'aid' => 'saved', 'owner_id' => uid,'description' => ''}]).each do |album|
  dir = (album['title']+ ' ' + album['description']).strip;
  Dir.mkdir dir;
  Dir.chdir dir do puts
    index = 1;
    (app.photos.get uid: album["owner_id"], aid: album["aid"]).each do |photo|
      url = photo['src_xxbig'] || photo['src_big']
      extension = url.split('.').last
      if photo['text'] && !photo['text'].empty?
        filename = index.to_s + ' - ' +  photo['text'] + '.' + extension
      else
        filename = index.to_s + '.' + extension
      end
#TODO slash shoud be substituted
      `wget --no-verbose --output-document '#{filename}' #{url} 2>> ../error.log`
      puts filename
      index+=1
      sleep 1
    end
  end
end
