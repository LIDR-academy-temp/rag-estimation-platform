class User < ApplicationRecord
  has_secure_password
  has_many :documents, dependent: :destroy
  has_many :estimations, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, on: :create

  before_save { self.email = email.downcase }
end
