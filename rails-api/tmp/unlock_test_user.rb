user = User.find_by(email: "test@example.com")
if user
  user.update_columns(
    failed_attempts: 0,
    locked_at: nil
  )
  puts "User test@example.com unlocked successfully"
  puts "  failed_attempts: #{user.failed_attempts}"
  puts "  locked_at: #{user.locked_at}"
else
  puts "User not found"
end
