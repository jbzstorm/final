# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

quests_table = DB.from(:quests)
signups_table = DB.from(:signups)
answers_table = DB.from(:answers)
users_table = DB.from(:users)

# view all quests
get "/" do
    @quests = quests_table.all
    view "quests"
end

# view a single quest
get "/quests/:id" do
    @users_table = users_table
    @quest = quests_table.where(:id => params["id"]).to_a[0]
    @signups = signups_table.where(:quest_id => params["id"]).to_a
    @count_signup = signups_table.where(:quest_id => params["id"], :attending => true).count
    @answers = answers_table.where(:quest_id => params["id"]).to_a
    @count_finish = answers_table.where(:quest_id => params["id"], :correct => true).count
    view "quest"
end

# create new user
get "/users/new" do
    view "new_user"
end

# receive new user form
post "/users/create" do
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :password => params["password"])
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        # test the password against the one in the users table
        if user[:password] == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    view "logout"
end

