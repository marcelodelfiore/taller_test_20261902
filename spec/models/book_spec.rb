require 'rails_helper'

RSpec.describe 'Book', type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:reservations) }
  end

  describe 'validations' do
    it { is_expected. validate_presence_of(:author) }
    it { is_expected. validate_presence_of(:title) }
  end
end
