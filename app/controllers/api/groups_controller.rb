module Api
  class GroupsController < Api::BaseController
    before_action :set_group, only: [:show, :update, :destroy]

    # GET /api/groups
    def index
      authorize Group
      @groups = policy_scope(Group)
      render json: { groups: @groups }, status: :ok
    end

    # GET /api/groups/:id
    def show
      authorize @group
      render json: { group: @group }, status: :ok
    end

    # POST /api/groups
    def create
      authorize Group
      @group = current_user.owned_groups.build(group_params)

      if @group.save
        render json: { group: @group }, status: :created
      else
        render json: { errors: @group.errors.messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/groups/:id
    def update
      authorize @group

      if @group.update(group_params)
        render json: { group: @group }, status: :ok
      else
        render json: { errors: @group.errors.messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/groups/:id
    def destroy
      authorize @group
      @group.destroy
      head :no_content
    end

    private

    def set_group
      @group = Group.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Group not found' }, status: :not_found
    end

    def group_params
      params.require(:group).permit(:name, :description)
    end
  end
end
