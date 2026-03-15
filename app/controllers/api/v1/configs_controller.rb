class Api::V1::ConfigsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @configs = Config.all
    render json: { status: 'success', data: @configs }
  end

  def show
    @config = Config.find_by!(key: params[:key])
    render json: { status: 'success', data: @config }
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Config not found' }, status: :not_found
  end

  def update
    @config = Config.find_by!(key: params[:key])
    if @config.update(value: params[:value])
      render json: { status: 'success', data: @config }
    else
      render json: { status: 'error', errors: @config.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Config not found' }, status: :not_found
  end
end