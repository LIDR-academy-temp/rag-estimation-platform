class Estimation < ApplicationRecord
  belongs_to :user
  has_many :functional_blocks, -> { order(:position) }, dependent: :destroy
  has_many :tasks, through: :functional_blocks
  has_many :references, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: %w[draft processing completed failed] }

  accepts_nested_attributes_for :functional_blocks, allow_destroy: true

  scope :recent, -> { order(created_at: :desc) }
  scope :search_by_title, ->(q) { where("title ILIKE ?", "%#{q}%") if q.present? }
end
