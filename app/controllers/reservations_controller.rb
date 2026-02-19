class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ show update destroy ]

   # POST /reservations
  def create
    @reservation = Reservation.new(reservation_params)

    if @reservation.save
      render json: @reservation, status: :created, location: @reservation
    else
      render json: @reservation.errors, status: :unprocessable_content
    end
  end

   private
    # Only allow a list of trusted parameters through.
    def reservation_params
      params.expect(reservation: [ :email ])
    end
end
