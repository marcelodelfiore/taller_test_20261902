require 'rails_helper'

RSpec.describe 'Reservations', type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:book) }
  end

  describe 'validations' do
    it { is_expected. validate_presence_of(:email) }
    it { is_expected. validate_presence_of(:status) }
  end
end
