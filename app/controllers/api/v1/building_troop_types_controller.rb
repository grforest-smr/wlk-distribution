class Api::V1::BuildingTroopTypesController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET /api/v1/building_troop_types
  def index
    @types = BuildingTroopType.all.order(:slot, :building)
    render json: { status: 'success', data: @types }
  end

  # GET /api/v1/building_troop_types/:slot/:building
  def show
    @type = BuildingTroopType.find_by!(
      building: params[:building],
      slot: params[:slot]
    )
    render json: { status: 'success', data: @type }
  rescue ActiveRecord::RecordNotFound
    render json: { 
      status: 'error', 
      message: "Building type not found for slot #{params[:slot]} and building #{params[:building]}" 
    }, status: :not_found
  end

  # PUT /api/v1/building_troop_types/:slot/:building
  def update
    @type = BuildingTroopType.find_or_initialize_by(
      building: params[:building],
      slot: params[:slot]
    )
    
    if params[:troop_type].blank?
      # Если тип пустой - удаляем запись (автоматический режим)
      if @type.persisted?
        @type.destroy
        render json: { 
          status: 'success', 
          message: 'Auto mode activated for this building' 
        }
      else
        render json: { 
          status: 'success', 
          message: 'Already in auto mode' 
        }
      end
    elsif @type.update(troop_type: params[:troop_type])
      render json: { 
        status: 'success', 
        message: 'Building type updated', 
        data: @type 
      }
    else
      render json: { 
        status: 'error', 
        errors: @type.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/building_troop_types/slot/:slot
  def by_slot
    @types = BuildingTroopType.for_slot(params[:slot])
    render json: { 
      status: 'success', 
      data: @types,
      slot: params[:slot] 
    }
  end
end