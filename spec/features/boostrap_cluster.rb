require "spec_helper"

feature "Boostrap cluster" do
  before do
    start_environment
    login
  end

  after do
    cleanup_environment
  end

  scenario "it lets the user log in" do
    visit "/nodes/index"
    expect(page).to have_content('Bootstrap cluster')
  end
end
