class ChatTeam < ActiveRecord::Base
  validates :team_id, presence: true

  belongs_to :namespace
end
