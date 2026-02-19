require 'rails_helper'

RSpec.describe 'Book Reservations', type: :request do
  describe 'POST /books/:id/reserve' do
    let!(:book) { Book.create!(author: 'Isaac Asimov', title: 'Foundation', status: 'available') }

    it 'creates a reservation and marks the book as reserved' do
      post "/books/#{book.id}/reserve", params: { reservation: { email: 'user@example.com' } }

      expect(response).to have_http_status(:created)

      book.reload
      expect(book.status).to eq('reserved')

      json = response.parsed_body
      expect(json['email']).to eq('user@example.com')
      expect(json['status']).to eq('reserved')

      expect(Reservation.count).to eq(1)
      expect(Reservation.first.book_id).to eq(book.id)
    end

    it 'returns 409 if the book is already reserved' do
      book.update!(status: 'reserved')

      post "/books/#{book.id}/reserve", params: { reservation: { email: 'user@example.com' } }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body['error']).to match(/already reserved/i)
    end

    it 'returns 409 if the book is checked out' do
      book.update!(status: 'checked_out')

      post "/books/#{book.id}/reserve", params: { reservation: { email: 'user@example.com' } }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body['error']).to match(/checked out/i)
    end

    it 'returns 404 if the book does not exist' do
      post "/books/999999/reserve", params: { reservation: { email: 'user@example.com' } }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to match(/not found/i)
    end

    it 'returns 422 for invalid email and does not change the book' do
      post "/books/#{book.id}/reserve", params: { reservation: { email: 'invalid' } }

      expect(response).to have_http_status(:unprocessable_entity)

      book.reload
      expect(book.status).to eq('available')
      expect(Reservation.count).to eq(0)
    end
  end
end
