import { describe, it, expect } from 'vitest';
import {
  buildPassportShareCopy,
  generateTelegramShareUrl,
  generateTelegramDirectMsgUrl,
} from '../components/PassportShareModal';

describe('P17-03: Web Companion Telegram Direct Share & Passport Link Generator', () => {
  const sampleOptions = {
    username: 'kamila_r',
    fullName: 'Kamila Rahimova',
    archetype: 'Coffee Connoisseur',
    totalDrops: 18,
    favoriteDistrict: 'Mirabad',
    streakWeeks: 4,
    baseUrl: 'https://around.tashkent.app',
  };

  it('builds rich formatted copy for Telegram passport sharing', () => {
    const copy = buildPassportShareCopy(sampleOptions);

    expect(copy).toContain("Kamila Rahimova's Taste Passport");
    expect(copy).toContain('Top Neighborhood: Mirabad');
    expect(copy).toContain('Archetype: Coffee Connoisseur');
    expect(copy).toContain('Verified Drops: 18');
    expect(copy).toContain('Discovery Streak: 4 weeks');
    expect(copy).toContain('Explore trusted local places discovered by friends in Tashkent:');
  });

  it('builds standard t.me/share/url web intent link with encoded parameters', () => {
    const shareUrl = generateTelegramShareUrl(sampleOptions);

    expect(shareUrl.startsWith('https://t.me/share/url?')).toBe(true);

    const parsed = new URL(shareUrl);
    expect(parsed.searchParams.get('url')).toBe('https://around.tashkent.app/u/kamila_r/passport');

    const textParam = parsed.searchParams.get('text');
    expect(textParam).not.toBeNull();
    expect(textParam).toContain('Kamila Rahimova');
    expect(textParam).toContain('Mirabad');
    expect(textParam).toContain('Coffee Connoisseur');
  });

  it('builds native tg://msg_url deep link for instantaneous Telegram app switching', () => {
    const deepLink = generateTelegramDirectMsgUrl(sampleOptions);

    expect(deepLink.startsWith('tg://msg_url?')).toBe(true);
    expect(deepLink).toContain('url=https%3A%2F%2Faround.tashkent.app%2Fu%2Fkamila_r%2Fpassport');
    expect(deepLink).toContain('text=');
  });

  it('handles default options safely when optional fields are omitted', () => {
    const minimal = {
      username: 'aziz_k',
      fullName: 'Aziz Karimov',
    };

    const copy = buildPassportShareCopy(minimal);
    expect(copy).toContain("Aziz Karimov's Taste Passport");
    expect(copy).toContain('Top Neighborhood: Tashkent');
    expect(copy).toContain('Archetype: Urban Explorer');
    expect(copy).toContain('Verified Drops: 0');
    expect(copy).not.toContain('Discovery Streak:');

    const shareUrl = generateTelegramShareUrl(minimal);
    const parsed = new URL(shareUrl);
    expect(parsed.searchParams.get('url')).toBe('https://around.tashkent.app/u/aziz_k/passport');
  });
});
