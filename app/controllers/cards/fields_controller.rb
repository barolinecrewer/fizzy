class Cards::FieldsController < ApplicationController
  include CardScoped

  def update
    @card.set_custom_field @board.custom_fields.find(params[:id]), params[:value]

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end
end
