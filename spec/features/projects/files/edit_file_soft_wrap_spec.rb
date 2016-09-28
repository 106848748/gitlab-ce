require 'spec_helper'

feature 'User uses soft wrap whilst editing file', feature: true, js: true do
  before do
    user = create(:user)
    project = create(:project)
    project.team << [user, :master]
    login_as user
    visit namespace_project_new_blob_path(project.namespace, project, 'master', file_name: 'test_file-name')
    editor = find('.file-editor.code')
    editor.click
    editor.send_keys 'Touch water with paw then recoil in horror chase dog then
      run away chase the pig around the house eat owner\'s food, and knock
      dish off table head butt cant eat out of my own dish. Cat is love, cat
      is life rub face on everything poop on grasses so meow. Playing with
      balls of wool flee in terror at cucumber discovered on floor run in
      circles tuxedo cats always looking dapper, but attack dog, run away
      and pretend to be victim so all of a sudden cat goes crazy, yet chase
      laser. Make muffins sit in window and stare ooo, a bird! yum lick yarn
      hanging out of own butt jump off balcony, onto stranger\'s head yet
      chase laser. Purr for no reason stare at ceiling hola te quiero.'.squish
  end

  let(:toggle_button) { find('.soft-wrap-toggle') }

  scenario 'user clicks the "No wrap" button and then "Soft wrap" button' do
    wrapped_content_width = get_content_width
    toggle_button.click
    expect(toggle_button).to have_content 'Soft wrap'
    unwrapped_content_width = get_content_width
    expect(unwrapped_content_width).to be > wrapped_content_width

    toggle_button.click
    expect(toggle_button).to have_content 'No wrap'
    expect(get_content_width).to be < unwrapped_content_width
  end

  scenario 'user adds a ".js" extension and then changes to a ".md" extension' do
    wrapped_content_width = get_content_width

    fill_in 'file_name', with: 'test_file-name.js'
    expect(toggle_button).to have_content 'Soft wrap'
    unwrapped_content_width = get_content_width
    expect(unwrapped_content_width).to be > wrapped_content_width

    fill_in 'file_name', with: 'test_file-name.md'
    expect(toggle_button).to have_content 'No wrap'
    expect(get_content_width).to be < unwrapped_content_width
  end

  scenario 'user clicks "No wrap" and then changes to a ".md" extension' do
    wrapped_content_width = get_content_width

    toggle_button.click
    expect(toggle_button).to have_content 'Soft wrap'
    unwrapped_content_width = get_content_width
    expect(unwrapped_content_width).to be > wrapped_content_width

    fill_in 'file_name', with: 'test_file-name.md'
    expect(toggle_button).to have_content 'Soft wrap'
    expect(unwrapped_content_width).to be == get_content_width
  end

  def get_content_width
    find('.ace_content')[:style].slice!(/width: \d+/).slice!(/\d+/)
  end
end
