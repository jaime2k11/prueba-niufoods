# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seeds basicos. Crea usuarios iniciales.
user_emails = ['admin@niufoods.cl', 'test@niufoods.cl']
default_password = 'password123'
begin
  if defined?(User)
    user_emails.each do |email|
      User.find_or_create_by!(email:) do |u|
        u.password = u.password_confirmation = default_password
      end
    end
    puts "Seeds loaded (users)."
  else
    puts "Seeds skipped (User not loaded yet)."
  end
rescue => e
  puts "Seeds skipped: #{e.message}"
end


