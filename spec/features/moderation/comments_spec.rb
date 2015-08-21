require 'rails_helper'

feature 'Moderate Comments' do

  feature 'Hiding Comments' do

    scenario 'Hide', :js do
      citizen = create(:user)
      moderator = create(:moderator)

      debate = create(:debate)
      comment = create(:comment, commentable: debate, body: 'SPAM')

      login_as(moderator.user)
      visit debate_path(debate)

      within("#comment_#{comment.id}") do
        click_link 'Hide'
        expect(page).to have_css('.comment .faded')
      end

      login_as(citizen)
      visit debate_path(debate)

      expect(page).to have_css('.comment', count: 1)
      expect(page).to have_content('This comment has been deleted')
      expect(page).to_not have_content('SPAM')
    end

    scenario 'Children visible', :js do
      citizen = create(:user)
      moderator = create(:moderator)

      debate = create(:debate)
      comment = create(:comment, commentable: debate, body: 'SPAM')
      create(:comment, commentable: debate, body: 'Acceptable reply', parent_id: comment.id)

      login_as(moderator.user)
      visit debate_path(debate)

      within("#comment_#{comment.id}") do
        first(:link, "Hide").click
        expect(page).to have_css('.comment .faded')
      end

      login_as(citizen)
      visit debate_path(debate)

      expect(page).to have_css('.comment', count: 2)
      expect(page).to have_content('This comment has been deleted')
      expect(page).to_not have_content('SPAM')

      expect(page).to have_content('Acceptable reply')
    end
  end

  scenario 'Moderator actions in the comment' do
    citizen = create(:user)
    moderator = create(:moderator)

    debate = create(:debate)
    create(:comment, commentable: debate)

    login_as(moderator.user)
    visit debate_path(debate)

    expect(page).to have_css("#moderator-comment-actions")

    login_as(citizen)
    visit debate_path(debate)

    expect(page).to_not have_css("#moderator-comment-actions")
  end

  feature '/moderation/ menu' do

    background do
      moderator = create(:moderator)
      login_as(moderator.user)

      user = create(:user)
      debate = create(:debate, title: 'Democracy')
      @comment = create(:comment, commentable: debate, body: 'spammy spam')
      InappropiateFlag.flag!(user, @comment)

      visit moderation_comments_path
    end

    scenario 'Flagged comment shows the right params' do
      within("#comment_#{@comment.id}") do
        expect(page).to have_link('Democracy')
        expect(page).to have_content('spammy spam')
        expect(page).to have_content('1')
        expect(page).to have_link('Hide')
        expect(page).to have_content('Mark as reviewed')
      end
    end

    scenario 'Hiding a comment' do
      within("#comment_#{@comment.id}") do
        click_link('Hide')
      end

      expect(current_path).to eq(moderation_comments_path)
      expect(page).to_not have_selector("#comment_#{@comment.id}")

      expect(@comment.reload).to be_hidden
    end

    scenario 'Marking a comment as reviewed' do
      within("#comment_#{@comment.id}") do
        click_link('Mark as reviewed')
      end

      expect(current_path).to eq(moderation_comments_path)

      within("#comment_#{@comment.id}") do
        expect(page).to have_content('Reviewed')
      end

      expect(@comment.reload).to be_reviewed
    end
  end

end
