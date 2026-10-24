class User < ApplicationRecord
  # Se utilizará método 'has_secure_password' junto con bcrypt
  # para guardar password_digest. auth tipica usando cookies/session
  has_secure_password

  before_validation { self.email = email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true
end
