require 'spec_helper'

feature 'Issue notes polling', :feature, :js do
  let(:project) { create(:empty_project, :public) }
  let(:issue) { create(:issue, project: project) }

  describe 'updates' do
    before do
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'should display the new comment' do
      note = create(:note, noteable: issue, project: project, note: 'Looks good!')
      page.execute_script('notes.refresh();')

      expect(page).to have_selector("#note_#{note.id}", text: 'Looks good!')
    end
  end

  describe 'updates' do
    let(:user) { create(:user) }
    let(:note_text) { "Hello World" }
    let!(:existing_note) { create(:note, noteable: issue, project: project, author: user, note: note_text) }

    before do
      login_as(user)
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'should display the updated content' do
      expect(page).to have_selector("#note_#{existing_note.id}", text: note_text)

      updated_text = "Bye World"
      existing_note.update(note: updated_text)
      page.execute_script('notes.refresh();')

      expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
    end

    it 'when editing but have not changed anything, and an update comes in, show the updated content in the textarea' do
      find("#note_#{existing_note.id} .js-note-edit").click
      expect(page).to have_field("note[note]", with: note_text)

      updated_text = "Bye World"
      existing_note.update(note: updated_text)
      page.execute_script('notes.refresh();')

      expect(page).to have_field("note[note]", with: updated_text)
    end

    it 'when editing but you changed some things, and an update comes in, show a warning' do
      find("#note_#{existing_note.id} .js-note-edit").click
      expect(page).to have_field("note[note]", with: note_text)
      find("#note_#{existing_note.id} .js-note-text").set('something random')

      updated_text = "Bye World"
      existing_note.update(note: updated_text)
      page.execute_script('notes.refresh();')

      expect(page).to have_selector(".alert")
    end

    it 'when editing but you changed some things, an update comes in, and you press cancel, show the updated content' do
      find("#note_#{existing_note.id} .js-note-edit").click
      expect(page).to have_field("note[note]", with: note_text)
      find("#note_#{existing_note.id} .js-note-text").set('something random')

      updated_text = "Bye World"
      existing_note.update(note: updated_text)
      page.execute_script('notes.refresh();')

      find("#note_#{existing_note.id} .note-edit-cancel").click

      expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
    end
  end
end
