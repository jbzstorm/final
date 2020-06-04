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

before do
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

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
    results = Geocoder.search(@quest[:address])
    @lat_long = results.first.coordinates.join(",")
    puts @lat_long
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
                       :password => BCrypt::Password.create(params["password"]))
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
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        if BCrypt::Password.new(user[:password]) == password_entered
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

# Form to create a new response to attended quest
get "/quests/:id/signups/new" do
    @quest = quests_table.where(:id => params["id"]).to_a[0]
    view "new_signup"
end

# Receiving end of the attending form
post "/quests/:id/signups/create" do
    past_signup = signups_table.where(:quest_id => params["id"]).where(:user_id => @current_user[:id]).to_a[0]
    @quest = quests_table.where(:id => params["id"]).to_a[0]
    if past_signup
        view "create_signup_duplicate"
    else
        signups_table.insert(:quest_id => params["id"],
                            :attending => params["attending"],
                            :user_id => @current_user[:id],
                            :comments => params["comments"])
        view "create_signup"
    end
end

# Form to create a new answer of the quest
get "/quests/:id/answers/new" do
    @quest = quests_table.where(:id => params["id"]).to_a[0]
    view "new_answer"
end

# Receiving end of the answer form
post "/quests/:id/answers/create" do
    @quest = quests_table.where(:id => params["id"]).to_a[0]
    answer_entered = params["answer"]
    past_answer = answers_table.where(:quest_id => params["id"]).where(:user_id => @current_user[:id]).where(:correct => true).to_a[0]
    if past_answer
        view "create_answer_duplicate"
        elsif answer_entered == @quest[:solution]
            answers_table.insert(:quest_id => params["id"],
                                :user_id => @current_user[:id],
                                :answer => params["answer"],
                                :correct => true)
            view "create_answer"
        else
            answers_table.insert(:quest_id => params["id"],
                                :user_id => @current_user[:id],
                                :answer => params["answer"],
                                :correct => false)
            view "create_answer_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end
