# frozen_string_literal: true

module RailsSettings
  class Railtie < Rails::Railtie
    initializer "rails_settings.active_record.initialization" do
      RailsSettings::Base.after_commit ->(obj) { obj.class.clear_cache }, on: :create
      RailsSettings::Base.after_commit ->(obj) { obj.class.clear_cache }, on: :update
      RailsSettings::Base.after_commit ->(obj) { obj.class.clear_cache }, on: :destroy
    end

    initializer "rails_settings.configure_rails_initialization" do |app|
      app.middleware.use RailsSettings::Middleware
    end
  end
end
