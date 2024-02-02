# frozen_string_literal: true

class Api::V1::Timelines::ListController < Api::V1::Timelines::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:lists' }
  before_action :require_user!
  before_action :set_list
  before_action :set_statuses

  PERMITTED_PARAMS = %i(limit).freeze

  def show
    account_ids = @statuses.filter(&:quote?).map { |status| status.quote.account_id }.uniq
    accounts = Account.where(id: account_ids)

    render json: @statuses,
           each_serializer: REST::StatusSerializer,
           relationships: StatusRelationshipsPresenter.new(@statuses, current_user.account_id),
           account_relationships: AccountRelationshipsPresenter.new(accounts, current_user&.account_id)
  end

  private

  def set_list
    @list = List.where(account: current_account).find(params[:id])
  end

  def set_statuses
    @statuses = cached_list_statuses
  end

  def cached_list_statuses
    cache_collection list_statuses, Status
  end

  def list_statuses
    list_feed.get(
      limit_param(DEFAULT_STATUSES_LIMIT),
      params[:max_id],
      params[:since_id],
      params[:min_id]
    )
  end

  def list_feed
    ListFeed.new(@list)
  end

  def next_path
    api_v1_timelines_list_url params[:id], next_path_params
  end

  def prev_path
    api_v1_timelines_list_url params[:id], prev_path_params
  end
end
