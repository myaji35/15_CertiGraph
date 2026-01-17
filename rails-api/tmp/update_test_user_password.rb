user = User.find_by(email: "test@example.com")
if user
  user.password = "Password123!"
  user.password_confirmation = "Password123!"
  user.save(validate: false)
  puts "User test@example.com password kept as 'Password123!'"
else
  puts "User not found"
end
