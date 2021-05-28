require "rails_helper"

describe "Localization" do
  scenario "Wrong locale" do
    login_as_manager
    visit management_root_path(locale: :es)
    visit management_root_path(locale: :klingon)

    expect(page).to have_text("Gestión")
  end

  scenario "Available locales appear in the locale switcher" do
    login_as_manager

    within(".locale-form .js-location-changer") do
      expect(page).to have_content "Español"
      expect(page).to have_content "English"
    end
  end

  scenario "The current locale is selected" do
    login_as_manager
    expect(page).to have_select("locale-switcher", selected: "English")
    expect(page).to have_text("Management")
  end

  scenario "Changing the locale" do
    login_as_manager
    expect(page).to have_content("Language")

    select("Español", from: "locale-switcher")
    expect(page).to have_content("Idioma")
    expect(page).not_to have_content("Language")
    expect(page).to have_select("locale-switcher", selected: "Español")
  end

  scenario "Locale switcher not present if only one locale" do
    allow(I18n).to receive(:available_locales).and_return([:en])

    login_as_manager
    expect(page).not_to have_content("Language")
    expect(page).not_to have_css("div.locale")
  end
end
