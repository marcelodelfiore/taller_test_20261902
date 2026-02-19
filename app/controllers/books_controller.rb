class BooksController < ApplicationController
  MAX_PER_PAGE = 100
  DEFAULT_PER_PAGE = 25

  # GET /books
  #
  # Params:
  # - page: 1.. (default 1)
  # - per: 1..100 (default 25)
  # - status: available|reserved|checked_out
  # - q: search in title/author
  # - include: current_reservation (optional)
  def index
    page = params.fetch(:page, 1).to_i
    per  = params.fetch(:per, DEFAULT_PER_PAGE).to_i
    per  = [[per, 1].max, MAX_PER_PAGE].min
    page = [page, 1].max

    scope = Book.all

    if params[:status].present?
      unless Book::STATUSES.include?(params[:status])
        return render json: { error: 'Invalid status' }, status: :unprocessable_content
      end
      scope = scope.where(status: params[:status])
    end

    if params[:q].present?
      q = params[:q].to_s.strip
      pattern = "%#{q.downcase}%"
      scope = scope.where('LOWER(title) LIKE ? OR LOWER(author) LIKE ?', pattern, pattern)
    end

    total = scope.count
    scope = scope.order(created_at: :desc, id: :desc)
      .offset((page - 1) * per)
      .limit(per)

    books = scope.to_a

    include_current = params[:include].to_s.split(',').include?('current_reservation')
    if include_current
      book_ids = books.map(&:id)
      current_res_by_book_id =
        Reservation.where(book_id: book_ids, status: 'reserved')
        .order(created_at: :desc, id: :desc)
        .group_by(&:book_id)

      data = books.map do |b|
        current = current_res_by_book_id[b.id]&.first
        book_json(b).merge(
          current_reservation: current && reservation_json(current)
        )
      end
    else
      data = books.map { |b| book_json(b) }
    end

    render json: {
      data: data,
      meta: { page: page, per: per, total: total }
    }
  end

  # GET /books/:id
  #
  # Params:
  # - include: reservations,current_reservation
  # - page/per (only used if include=reservations)
  def show
    book = Book.find(params[:id])

    includes = params[:include].to_s.split(',').map(&:strip)
    include_reservations = includes.include?('reservations')
    include_current = includes.include?('current_reservation')

    response = { data: book_json(book) }

    if include_current
      current = book.reservations.where(status: 'reserved').order(created_at: :desc, id: :desc).first
      response[:data][:current_reservation] = current && reservation_json(current)
    end

    if include_reservations
      page = params.fetch(:page, 1).to_i
      per = params.fetch(:per, DEFAULT_PER_PAGE).to_i
      per = [[per, 1].max, MAX_PER_PAGE].min
      page = [page, 1].max

      res_scope = book.reservations.order(created_at: :desc, id: :desc)
      total = res_scope.count
      reservations = res_scope.offset((page - 1) * per).limit(per)

      response[:reservations] = reservations.map { |r| reservation_json(r) }
      response[:meta] = { page: page, per: per, total: total }
    end

    render json: response
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Book not found' }, status: :not_found
  end

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

    render json: reservation_json(reservation), status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Book not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def reserve_params
    params.require(:reservation).permit(:email)
  end

  def book_json(book)
    {
      id: book.id,
      title: book.title,
      author: book.author,
      status: book.status,
      created_at: book.created_at,
      updated_at: book.updated_at
    }
  end

  def reservation_json(res)
    {
      id: res.id,
      book_id: res.book_id,
      email: res.email,
      status: res.status,
      created_at: res.created_at,
      updated_at: res.updated_at
    }
  end
end
