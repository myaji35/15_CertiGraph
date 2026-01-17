User.create!(
  email: "test@example.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  confirmed_at: Time.current,
  terms_agreed: true,
  privacy_agreed: true
)
puts "User test@example.com created successfully"
