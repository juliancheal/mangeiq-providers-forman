require "foreman_api_client"

describe ManageIQ::Providers::Foreman::Provider do
  let(:provider) { FactoryBot.build(:provider_foreman) }
  let(:attrs) do
    {:base_url => provider.url, :username => "admin", :password => "smartvm", :timeout => 100, :verify_ssl => OpenSSL::SSL::VERIFY_PEER}
  end

  describe "#connect" do
    it "with no port" do
      expect(ForemanApiClient::Connection).to receive(:new).with(attrs)
      provider.connect
    end

    it "with a port" do
      provider.url = "example.com:555"
      attrs[:base_url] = "example.com:555"

      expect(ForemanApiClient::Connection).to receive(:new).with(attrs)
      provider.connect
    end

    it "without https uri" do
      provider.url = "example.com"
      attrs[:base_url] = "example.com"
      expect { provider.verify_credentials }.to raise_error(RuntimeError, "URL has to be HTTPS")
    end
  end

  describe "#destroy" do
    it "will remove all child objects" do
      provider = FactoryBot.create(:provider_foreman, :zone => FactoryBot.create(:zone))

      provider.configuration_manager.configured_systems = [
        FactoryBot.create(:configured_system, :computer_system =>
          FactoryBot.create(:computer_system,
                             :operating_system => FactoryBot.create(:operating_system),
                             :hardware         => FactoryBot.create(:hardware),
                            )
                          )
      ]
      provider.configuration_manager.configuration_profiles =
        [FactoryBot.create(:configuration_profile)]
      provider.provisioning_manager.operating_system_flavors =
        [FactoryBot.create(:operating_system_flavor)]
      provider.provisioning_manager.customization_scripts =
        [FactoryBot.create(:customization_script)]

      provider.destroy

      expect(Provider.count).to              eq(0)
      expect(ConfiguredSystem.count).to      eq(0)
      expect(ComputerSystem.count).to        eq(0)
      expect(OperatingSystem.count).to       eq(0)
      expect(Hardware.count).to              eq(0)
      expect(ConfigurationProfile.count).to  eq(0)
      expect(OperatingSystemFlavor.count).to eq(0)
      expect(CustomizationScript.count).to   eq(0)
    end
  end

  describe "#save" do
    it "will update the name for the manager" do
      provider = FactoryBot.create(:provider_foreman, :zone => FactoryBot.create(:zone), :name => 'Old Name')
      expect(provider.configuration_manager.name).to eq('Old Name Configuration Manager')

      provider.update(:name => 'New Name')
      expect(provider.configuration_manager.name).to eq('New Name Configuration Manager')
      expect(provider.provisioning_manager.name).to eq('New Name Provisioning Manager')
    end
  end
end
