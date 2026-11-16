class StepTemplatesController < ApplicationController
  wrap_parameters :step_template, include: %i[ name outline ]

  before_action :set_step_template, only: %i[ update destroy ]

  def index
    @step_templates = Current.account.step_templates.alphabetically
  end

  def create
    @step_template = Current.account.step_templates.create!(new_step_template_params)

    respond_to do |format|
      format.html { redirect_to step_templates_path, notice: "Template saved" }
      format.json { render :show, status: :created }
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def update
    @step_template.update!(step_template_params)

    respond_to do |format|
      format.html { redirect_to step_templates_path, notice: "Template saved" }
      format.json { render :show }
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def destroy
    @step_template.destroy!

    respond_to do |format|
      format.html { redirect_to step_templates_path, notice: "Template deleted" }
      format.json { head :no_content }
    end
  end

  private
    def set_step_template
      @step_template = Current.account.step_templates.find(params[:id])
    end

    # A template can be saved from a card's existing steps instead of typed out.
    def new_step_template_params
      if params[:card_id].present?
        card = Current.user.accessible_cards.find_by!(number: params[:card_id])
        { name: "#{card.title} steps", outline: StepTemplate.outline_of(card) }
      else
        step_template_params
      end
    end

    def step_template_params
      params.expect(step_template: [ :name, :outline ])
    end
end
