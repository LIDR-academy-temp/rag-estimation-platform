class Estimation < ApplicationRecord
  belongs_to :user
  has_many :functional_blocks, -> { order(:position) }, dependent: :destroy
  has_many :tasks, through: :functional_blocks
  has_many :references, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: %w[draft processing structuring validating completed failed] }
  validates :global_rate, numericality: { greater_than: 0 }, allow_nil: true
  validates :currency, inclusion: { in: %w[EUR USD GBP] }, allow_nil: true
  validates :confidence_score, numericality: { in: 0..1 }, allow_nil: true

  accepts_nested_attributes_for :functional_blocks, allow_destroy: true

  scope :recent, -> { order(created_at: :desc) }
  scope :search_by_title, ->(q) { where("title ILIKE ?", "%#{q}%") if q.present? }
end
