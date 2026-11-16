class Boards::CustomFieldsController < ApplicationController
  wrap_parameters :custom_field, include: %i[ name kind options ]

  include BoardScoped

  before_action :ensure_permission_to_admin_board, except: :index

  def index
    @custom_fields = @board.custom_fields.alphabetically
  end

  def create
    @custom_field = @board.custom_fields.create!(custom_field_params)

    respond_to do |format|
      format.html { redirect_to edit_board_path(@board), notice: "Field added" }
      format.json { render partial: "boards/custom_fields/custom_field", locals: { custom_field: @custom_field }, status: :created }
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def destroy
    @board.custom_fields.find(params[:id]).destroy!

    respond_to do |format|
      format.html { redirect_to edit_board_path(@board), notice: "Field removed" }
      format.json { head :no_content }
    end
  end

  private
    def custom_field_params
      params.expect(custom_field: [ :name, :kind, :options ])
    end
end
