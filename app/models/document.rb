class Document < ApplicationRecord
  belongs_to :user
  has_one :chunks_breakdown, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :search_by_title, ->(q) { where("title ILIKE ?", "%#{q}%") if q.present? }
end
