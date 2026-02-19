require 'rails_helper'

RSpec.describe 'Books GET endpoints', type: :request do
  describe 'GET /books' do
    before do
      # for this exercise, I'm not creating a factory
      3.times { |i| Book.create!(author: "Author #{i}", title: "Title #{i}", status: 'available') }
      Book.create!(author: 'Isaac Asimov', title: 'Foundation', status: 'reserved')
    end

    it 'returns paginated books with meta' do
      get '/books', params: { page: 1, per: 2 }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json['data'].size).to eq(2)
      expect(json['meta']).to include('page' => 1, 'per' => 2)
      expect(json['meta']['total']).to eq(4)
    end

    it 'filters by status' do
      get '/books', params: { status: 'reserved' }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json['data'].size).to eq(1)
      expect(json['data'].first['status']).to eq('reserved')
    end

    it 'returns 422 for invalid status' do
      get '/books', params: { status: 'nope' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to match(/Invalid status/i)
    end

    it 'searches by q in title or author' do
      get '/books', params: { q: 'Asimov' }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['data'].size).to eq(1)
      expect(json['data'].first['author']).to match(/Asimov/)
    end

    it 'includes current_reservation without N+1 behavior (functional check)' do
      book = Book.find_by!(title: 'Foundation')
      Reservation.create!(book: book, email: 'user@example.com', status: 'reserved')

      get '/books', params: { include: 'current_reservation' }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      foundation = json['data'].find { |b| b['title'] == 'Foundation' }
      expect(foundation['current_reservation']).to include('email' => 'user@example.com', 'status' => 'reserved')
    end
  end

  describe 'GET /books/:id' do
    let!(:book) { Book.create!(author: 'Frank Herbert', title: 'Dune', status: 'available') }

    it 'returns book details' do
      get "/books/#{book.id}"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['data']).to include('title' => 'Dune', 'author' => 'Frank Herbert', 'status' => 'available')
    end

    it 'returns 404 if not found' do
      get '/books/999999'

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to match(/not found/i)
    end

    it 'can include reservations paginated' do
      3.times do |i|
        Reservation.create!(book: book, email: "u#{i}@example.com", status: 'reserved')
      end

      get "/books/#{book.id}", params: { include: 'reservations', per: 2, page: 1 }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json['reservations'].size).to eq(2)
      expect(json['meta']).to include('page' => 1, 'per' => 2, 'total' => 3)
    end

    it 'can include current_reservation' do
      Reservation.create!(book: book, email: 'user@example.com', status: 'reserved')

      get "/books/#{book.id}", params: { include: 'current_reservation' }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['data']['current_reservation']).to include('email' => 'user@example.com', 'status' => 'reserved')
    end
  end
end
