class Reference < ApplicationRecord
  belongs_to :estimation

  scope :by_similarity, -> { order(similarity_score: :desc) }
end
