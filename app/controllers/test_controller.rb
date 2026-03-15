class TestController < ApplicationController
  include ActionView::Rendering
  include ActionView::Layouts

  def index
    render "index"
  end
end