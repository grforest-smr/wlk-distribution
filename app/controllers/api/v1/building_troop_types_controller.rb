class Api::V1::BuildingTroopTypesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @types = BuildingTroopType.all
    render json: { status: 'success', data: @types }
  end

  def show
    @type = BuildingTroopType.find_by!(building: params[:building])
    render json: { status: 'success', data: @type }
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Building not found' }, status: :not_found
  end

def update
  @type = BuildingTroopType.find_or_initialize_by(building: params[:building])
  
  if params[:troop_type].blank?
    # Если тип пустой - удаляем запись (автоматический режим)
    @type.destroy if @type.persisted?
    render json: { status: 'success', message: 'Тип удален, будет использовано автоматическое распределение' }
  elsif @type.update(troop_type: params[:troop_type])
    render json: { status: 'success', data: @type }
  else
    render json: { status: 'error', errors: @type.errors.full_messages }, status: :unprocessable_entity
  end
end
end