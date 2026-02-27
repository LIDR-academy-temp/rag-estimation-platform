class Reference < ApplicationRecord
  belongs_to :estimation

  validates :similarity_score, numericality: { in: 0..1 }, allow_nil: true

  scope :by_similarity, -> { order(similarity_score: :desc) }
end
