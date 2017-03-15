require 'spec_helper'

describe ProtectedTags::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { project.owner }
  let(:params) do
    {
      name: 'master',
      merge_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }],
      push_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }]
    }
  end

  describe '#execute' do
    subject(:service) { described_class.new(project, user, params) }

    it 'creates a new protected tag' do
      expect { service.execute }.to change(ProtectedTag, :count).by(1)
      expect(project.protected_tags.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
      expect(project.protected_tags.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
    end
  end
end
