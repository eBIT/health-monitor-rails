# frozen_string_literal: true

module HealthMonitor
  class HealthController < ActionController::Base
    protect_from_forgery with: :exception

    if Rails.version.starts_with? '3'
      before_filter :authenticate_with_basic_auth
      before_filter :set_available_format
    else
      before_action :authenticate_with_basic_auth
      before_action :set_available_format
    end

    def check
      @statuses = statuses

      respond_to do |format|
        format.html
        if use_jbuilder_template?
          format.json
        else
          format.json do
            render json: statuses.to_json, status: statuses[:status]
          end
        end
        format.xml do
          render xml: statuses.to_xml, status: statuses[:status]
        end
      end
    end

    private

    def statuses
      res = HealthMonitor.check(request: request, params: providers_params)
      res.merge(env_vars)
    end

    def env_vars
      v = HealthMonitor.configuration.environment_variables || {}
      v.empty? ? {} : { environment_variables: v }
    end

    def authenticate_with_basic_auth
      return true unless HealthMonitor.configuration.basic_auth_credentials

      credentials = HealthMonitor.configuration.basic_auth_credentials
      authenticate_or_request_with_http_basic do |name, password|
        name == credentials[:username] && password == credentials[:password]
      end
    end

    def providers_params
      params.permit(providers: [])
    end

    def set_available_format
      request.format = :json unless HealthMonitor.configuration.formats.include?(params[:format].to_s.downcase.to_sym)
    end

    def use_jbuilder_template?
      HealthMonitor.configuration.use_jbuilder_template
    end
  end
end
