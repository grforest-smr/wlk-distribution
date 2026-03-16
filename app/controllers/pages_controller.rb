class PagesController < ApplicationController
  before_action :authenticate_admin, only: [:admin]
  
  def index
    # Главная страница
  end

  def register
    # Страница регистрации (больше не используется)
  end

  def admin
    # Админ-панель
  end

  def results
    # Страница результатов (больше не используется)
  end

  
def instructions
  # Страница с инструкцией
end

  private

  def authenticate_admin
    authenticate_or_request_with_http_basic do |username, password|
      username == Rails.application.credentials.dig(:admin, :username) && 
      password == Rails.application.credentials.dig(:admin, :password)
    end
  end
end
