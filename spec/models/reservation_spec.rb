require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:book) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to allow_value('user@example.com').for(:email) }
    it { is_expected.not_to allow_value('bad-email').for(:email) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Reservation::STATUSES) }
  end
end
