require 'spec_helper'

describe("Favorites",:type=>:request,:integration=>true) do

  before :each do
    logout 
    @save_favorites_button=I18n.t('revs.favorites.save_to_favorites')
    @remove_favorites_button=I18n.t('revs.favorites.remove_from_favorites')
    @druid1='qk978vx9753'
    @druid2='dd482qk0417'
    @Next = "Next"
  end
  
  it "should not show save/remove favorites link for non-logged in users" do
    visit catalog_path(@druid1)
    should_not_have_button(@save_favorites_button)
    should_not_have_button(@remove_favorites_button)    
  end

  it "should show save favorites link for a logged in user and allow them to add a favorite" do
   
    user=get_user(user_login)
    login_as(user_login)
    visit catalog_path(@druid1)
    should_have_button(@save_favorites_button)
    should_not_have_button(@remove_favorites_button)    
    
    # check database to be sure there are no favorites for this user
    user.favorites.size.should == 0

    click_button(@save_favorites_button) # save the favorite

    should_not_have_button(@save_favorites_button) # button switches to remove
    should_have_button(@remove_favorites_button)    

    user.favorites.where(:druid=>@druid1).size.should == 1 # favorite is now saved
    user.favorites.size.should == 1 # user now has one favorite
        
    # druid2 is not a favorite yet
    visit catalog_path(@druid2)
    should_have_button(@save_favorites_button)
    should_not_have_button(@remove_favorites_button)
    click_button(@save_favorites_button) # save it!

    user.favorites.where(:druid=>@druid2).size.should == 1 # favorite is now saved
    user.favorites.size.should == 2 # user now has two favorites

    click_button(@remove_favorites_button) # get rid of the favorite

    should_have_button(@save_favorites_button) # button switches back to add
    should_not_have_button(@remove_favorites_button)    
    
    # favorite is gone
    user.favorites.where(:druid=>@druid2).size.should == 0 # favorite is now gone
    user.favorites.size.should == 1 # user now has one favorite    
    
  end
  
  it "should not show any favorites on a user's profile page if they don't have any favorites" do
    
    login_as(user_login)
    visit user_profile_name_path(user_login)
    page.should have_content I18n.t('revs.favorites.you_can_save_favorites')
    visit user_favorites_path(user_login)
    page.should have_content I18n.t('revs.favorites.personal_none')

  end

  it "should show favorites on a user's profile page if they have favorites and full favorites page should show all of them" do
    
    login_as(curator_login)
    visit user_profile_name_path(curator_login)
    page.should_not have_content I18n.t('revs.favorites.you_can_save_favorites')
    page.should have_content "#{I18n.t('revs.favorites.head')} 4"
    page.should have_content "1 #{I18n.t('revs.favorites.singular')} not shown"
    visit user_favorites_path(curator_login)
    page.should have_content "Bryar 250 Trans-American:10"
    page.should have_content "A Somewhat Shorter Than Average Title"
    page.should have_content "Thompson Raceway, May 1 -- AND A long title can go here so let's see how it looks when it is really long"
    page.should have_content "Marlboro 12 Hour, August 12-14"

  end
  
  it "should allow a user to see a list of his favorites that paginates and allow the user to move between pages" do
    
    description = "This is a decription "
    login_as(user_login)
    
    #Get a two page list of druids
    fav_druids = (item_druids-default_hidden_druids).first(SavedItem.favorites_per_page*2)
    fav_druids.each do |druid| 
      visit catalog_path(druid)
      click_button(@save_favorites_button) 
    end
    #Check Out Pagination 
    visit user_favorites_path(user_login)
    page.should have_content @Next
    page.should have_content "Last"
    
    #Make Sure We Go To the Second Page
    click_link(@Next)

    
    page.should have_content "First"
    page.should have_content "Previous"
  end
  

  it "should allow a user to edit a favorite when viewing all their favorites" do
      new_description="Hello, I am a new description for a favorite."
      
      login_as(user_login)
      visit catalog_path(@druid1)
      click_button(@save_favorites_button)
      visit user_favorites_path(user_login)
      page.should have_content get_title_from_druid(@druid1)
      page.should have_content I18n.t('revs.favorites.add_item_note')
      page.should have_no_content new_description
      click_link(I18n.t('revs.favorites.add_item_note'))
      page.should have_content I18n.t('revs.nav.update')
      fill_in('saved_item_description', :with => new_description)
      click_button(I18n.t('revs.nav.update'))
      page.should have_content I18n.t('revs.favorites.edit_item_note')
      
      #Go check databse to make sure this was updated
      user = get_user(user_login)
      user.favorites[0].description.should == new_description
      
      #Go back to the favorites page and ensure the new description is still there
      logout
      login_as(user_login)
      visit user_favorites_path(user_login)
      page.should have_content new_description
      page.should have_content get_title_from_druid(@druid1)
      
  end
  
  it "should allow a user to remove a favorite when viewing all their favorites" do
    login_as(user_login)
    user = get_user(user_login)
    user.favorites.size.should == 0
    visit catalog_path(@druid1)
    click_button(@save_favorites_button)
    user = get_user(user_login)
    user.favorites.size.should == 1
    visit user_favorites_path(user_login)
    page.should have_content get_title_from_druid(@druid1)
    click_button(I18n.t('revs.favorites.remove_from_favorites'))
    user = get_user(user_login)
    user.favorites.size.should == 0
    logout
    login_as(user_login)
    visit user_favorites_path(user_login)
    page.should have_no_content get_title_from_druid(@druid1)
    page.should have_content I18n.t('revs.favorites.personal_none')
    
    
  end
  
  
end