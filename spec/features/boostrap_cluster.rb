require "spec_helper"

feature "Boostrap cluster" do
  before do
    login
  end

  scenario "it lets the user log in" do
    visit "/nodes/index"
    expect(page).to have_content('Bootstrap cluster')
  end
end
