# frozen_string_literal: true
# A module containing helper methods to create a testing environment
# for end to end tests.
module Helpers
  # Spawns a salt-minion which connects to velum
  # The minion is a Virtual Machine which we build using terraform.
  def spawn_minion
  end

  # Runs the script that creates the testing environment
  def start_environment
    script = File.join(
      File.dirname(File.dirname(File.dirname(__FILE__))),
      "scripts",
      "start_environment"
    )

    `#{script}`
  end

  private

  # This returns the server's host in tests with "js: true"
  def server_host
    Capybara.current_session.server.try(:host)
  end

  # This returns the server's port in tests with "js: true"
  def server_port
    Capybara.current_session.server.try(:port)
  end

  def login
    visit "/users/sign_in"
    fill_in "user_email", with: "test@test.com"
    fill_in "user_password", with: "password"
    click_on "Log in"
  end
end

RSpec.configure { |config| config.include Helpers, type: :feature }
