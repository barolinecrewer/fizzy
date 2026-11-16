class Cards::TemplatingsController < ApplicationController
  include CardScoped

  def new
    @step_templates = Current.account.step_templates.alphabetically
  end

  def create
    Current.account.step_templates.find(params[:step_template_id]).apply_to(@card)

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :created }
    end
  end
end
