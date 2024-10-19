class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :role, optional: true
  belongs_to :career, optional: true
  has_many :enrollments, dependent: :destroy
  has_many :courses, through: :enrollments
  has_many :notifications, dependent: :destroy
  has_many :friends, dependent: :destroy
  has_many :followers, dependent: :destroy
  has_many :professors, dependent: :destroy

  validates :nombre_completo, :email, :user_name, presence: true
  validates :email, :user_name, uniqueness: true

  # Relaciones de seguidores
  has_many :followed_users, class_name: 'Follower', foreign_key: 'user_id', dependent: :destroy
  has_many :followers, through: :followed_users, source: :follower

  # Relaciones de seguidos
  has_many :following_users, class_name: 'Follower', foreign_key: 'follower_id', dependent: :destroy
  has_many :following, through: :following_users, source: :user
end
