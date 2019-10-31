# frozen_string_literal: true

HealthMonitor::Engine.routes.draw do
  get HealthMonitor.configuration.monitoring_url, to: 'health#check'
end
