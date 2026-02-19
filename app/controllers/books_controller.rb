class BooksController < ApplicationController
  # POST /books/:id/reserve
  def reserve
    book = Book.find(params[:id])

    return render json: { error: 'Book is already reserved' }, status: :conflict if book.status == 'reserved'
    return render json: { error: 'Book is checked out' }, status: :conflict if book.status == 'checked_out'

    email = reserve_params[:email]

    reservation = nil
    Book.transaction do
      reservation = book.reservations.create!(email: email, status: 'reserved')
      book.update!(status: 'reserved')
    end

    render json: reservation, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Book not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def reserve_params
    params.require(:reservation).permit(:email)
  end
end
