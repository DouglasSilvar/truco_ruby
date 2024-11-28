namespace :db do
  desc "Truncate all tables but keep the schema"
  task truncate_all: :environment do
    ActiveRecord::Base.connection.tables.each do |table|
      next if table == "schema_migrations" || table == "ar_internal_metadata"

      ActiveRecord::Base.connection.execute("DELETE FROM #{table};")
    end
    puts "Database truncated successfully!"
  end
end
