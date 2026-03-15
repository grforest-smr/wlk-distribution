class Api::V1::DistributionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def run
    use_strength = params[:use_strength] != 'false'
    
    service = PlayerDistributionService.new
    result = service.distribute_all_slots(use_strength)
    
    if result[:error]
      render json: { status: 'error', message: result[:error] }
    else
      service.save_distribution(result[:output])
      render json: { 
        status: 'success', 
        message: 'Distribution completed',
        data: {
          slot1: result[:slot1],
          slot2: result[:slot2]
        }
      }
    end
  end

  def latest
    @distributions = Distribution.where(distribution_date: Date.current)
      .includes(:player)
      .order(:slot, :building)
    
    render json: { status: 'success', data: @distributions }
  end
end