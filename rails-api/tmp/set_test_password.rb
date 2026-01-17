require 'bcrypt'

user = User.find_by(email: "test@example.com")
if user
  # Directly set the encrypted password for "password123" bypassing validations
  encrypted = BCrypt::Password.create("password123", cost: 4)
  user.update_column(:encrypted_password, encrypted)
  puts "User test@example.com password set to 'password123'"
  puts "Encrypted: #{encrypted}"
else
  puts "User not found"
end
