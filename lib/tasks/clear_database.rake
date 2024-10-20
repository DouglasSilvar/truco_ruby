namespace :db do
    desc "Limpar todas as tabelas do banco de dados"
    task clear_all: :environment do
      RoomPlayer.delete_all
      Room.delete_all
      Player.delete_all
  
      puts "Todas as tabelas foram limpas!"
    end
  end
  