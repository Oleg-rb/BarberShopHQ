require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'sinatra/activerecord'

# set :database, "sqlite3:barbershop.db"

def get_db
	db = set :database, "sqlite3:barbershop.db"
	db.results_as_hash = true
	return db
end
# set :database, {adapter: "sqlite3", database: "barbershop.db"}
#ActiveRecord::Base.establish_connection(
#       :adapter  => "sqlite3",
#       :database => "barbershop.db"
#       )

class Client < ActiveRecord::Base
end

class Barber < ActiveRecord::Base
end

def is_barber_exists? db, name
	db.execute('select *from Barbers where barbers_name=?', [name]).length > 0
end

def seed_db db, barbers
	barbers.each do |barber|
		if !is_barber_exists? db, barber
			db.execute 'insert into Barbers (barbers_name) values (?)', [barber]
		end
	end
end

before do
	@barbers = Barber.order 'created_at DESC'
end

get '/' do
	erb :index
end

get '/about' do
	erb :about
end

get '/admin' do
	erb :admin
end

get '/contacts' do
	erb :contacts
end

get '/visit' do
	erb :visit
end

get '/showusers' do
	db = get_db
	@results = db.execute 'select * from Users order by id desc'

	erb :showusers
end

post '/admin' do
	@login    = params[:login]
	@password = params[:password]
	@file     = params[:file]

	if @login == 'admin' && @password == 'secret' && @file == 'Посетители'
		@logfile = @file_users
		send_file './public/users.txt'
		erb :create
	elsif @login == 'admin' && @password == 'secret' && @file == 'Контакты'
		@logfile = @file_contacts
		send_file './public/contacts.txt'
		erb :create
	else
		@error ='Access denied'
		erb :admin
	end	
end

post '/contacts' do

	@email        = params[:email]
	@user_message = params[:user_message]

	hh = { :email        => 'Введите Ваш емайл',
		   :user_message => 'Введите Ваше сообщение' }

		@error = hh.select {|key,_| params[key] == ""}.values.join(", ")

		if @error != ''
			return erb :contacts
		end

	@title = "Большое спасибо!"
	@message = "<h4>Ваше сообщение очень важно для нас!</h4>
	            <h4>Мы не передаём информацию третьим лицам!</h4>"

	file_contacts = File.open './public/contacts.txt', 'a'
	file_contacts.write "Users_email: #{@email},   Users_message: #{@user_message}\n"
	file_contacts.close

	erb :message
end

post '/visit' do

	@user_name  = params[:user_name]
	@phone      = params[:phone]
	@date_time  = params[:date_time]
	@specialist = params[:specialist]
	@color      = params[:color]

	hh = { :user_name  => 'Введите Ваше имя',
		   :phone     => 'Введите номер Вашего телефона',
		   :date_time => 'Введите дату и время' }

		@error = hh.select {|key,_| params[key] == ""}.values.join(", ")

		if @error != ''
			return erb :visit
		end

	db = get_db
	db.execute 'insert into Users (name, phone, date_stamp, barber, color) values (?, ?, ?, ?, ?)', [@user_name, @phone, @date_time, @specialist, @color]
	db.close

	@title = "Спасибо за Ваш выбор, #{@user_name}!"
	@message = "Ваш парикмахер #{@specialist} будет ждать Вас #{@date_time}!"

	file_users = File.open './public/users.txt', 'a'
	file_users.write "User: #{@user_name},   Phone: #{@phone},   Date and time: #{@date_time},   Specialist: #{@specialist},   Color: #{@color}\n"
	file_users.close

	erb :message
end
