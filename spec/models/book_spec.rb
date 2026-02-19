require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:reservations).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Book::STATUSES) }
  end
end
