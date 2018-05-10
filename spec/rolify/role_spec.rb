require "spec_helper"

describe Rolify do

  context 'cache' do
    let(:user) { User.first }
    before { user.grant(:zombie) }
    specify do
      expect(user).to have_role(:zombie)
      user.remove_role(:zombie)
      expect(user).to_not have_role(:zombie)
    end
  end

  context 'cache' do
    let(:user) { User.first }
    let(:zombie) { Role.first }
    before { user.grant(zombie) }
    specify do
      expect(user).to have_role(zombie)
      user.remove_role(zombie)
      expect(user).to_not have_role(zombie)
    end
  end
    
  context 'cache' do
    let(:user) { User.first }
    let(:zombie_id) { Role.first.id }
    before { user.grant(zombie_id) }
    specify do
      expect(user).to have_role(zombie_id)
      user.remove_role(zombie_id)
      expect(user).to_not have_role(zombie_id)
    end
  end
end
