set :environment, "production"

every 1.day, at: "5:00 am" do
  rake "db:truncate_all"
end
