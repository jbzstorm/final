# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :quests do
  primary_key :id
  String :title
  String :objective, text: true
  String :clues, text: true
  String :deadline
  String :location
  String :reward, text: true
  String :question, text: true
  String :solution
  Numeric :lat
  Numeric :lng
end
DB.create_table! :signups do
  primary_key :id
  foreign_key :quest_id
  foreign_key :user_id
  Boolean :attending
  String :comments, text: true
end
DB.create_table! :answers do
  primary_key :id
  foreign_key :quest_id
  foreign_key :user_id
  Boolean :finished
  String :answer
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end


# Insert initial (seed) data
quests_table = DB.from(:quests)

quests_table.insert(title: "Ghost in the Hub",
                    objective: "Word on the street, there is a ghost haunting the Hub, find him/her!",
                    clues: "The ghost has been sighted in the mail room recently",
                    deadline: "July 1",
                    location: "Kellogg Global Hub",
                    reward: "All Kelloggers' gratitude and a cup of free coffee",
                    question: "In which year did the ghost graduate from Kellogg?",
                    solution: "2001",
                    lat: 15,
                    lng: 15)

quests_table.insert(title: "Missing food delivery in McManus",
                    objective: "Someone has been stealing other people's food delivery in McManus, find the thief!",
                    clues: "Some students have reported seeing a shady person in study room 1F",
                    deadline: "July 3",
                    location: "McManus",
                    reward: "All you can eat in Burger King",
                    question: "How many deliveries has this thief stolen?",
                    solution: "8",
                    lat: 15,
                    lng: 15)
