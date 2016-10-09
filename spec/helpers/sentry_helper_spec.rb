require 'spec_helper'

describe SentryHelper do
  describe '#sentry_dsn_public' do
    it 'returns nil if no sentry_dsn is set' do
      allow(ApplicationSetting.current).to receive(:sentry_dsn).and_return(nil)
      expect(helper.sentry_dsn_public).to eq(nil)
    end

    it 'returns the uri string with no password if sentry_dsn is set' do
      allow(ApplicationSetting.current).to receive(:sentry_dsn).and_return('https://test:dsn@host/path')
      expect(helper.sentry_dsn_public).to eq('https://test@host/path')
    end
  end
end