import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  CuratorPostcardGenerator,
  generateWebReceiptNumber,
  getWebPostcardThemeStyles,
  WebCuratorPostcard,
} from '../components/CuratorPostcardGenerator';

describe('P27-03: CuratorPostcardGenerator Web Component & Receipt Styling Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const testPostcard: WebCuratorPostcard = {
    placeId: 'place_breadly',
    placeName: 'Breadly Bakery & Cafe',
    district: 'Mirabad',
    atmosphereTag: 'Aesthetic Coffee',
    verifiedSeal: 'SEAL-MIR-892',
    nearestSubway: 'Oybek',
    curatorName: 'Kamila Rahimova',
    curatorHandle: 'kamila_tashkent',
    curatorTier: 'Local Legend',
    curatorXp: 850,
    receiptNumber: 'REC-MIR-2026-774',
    theme: 'paper',
    aspectRatio: '9:16',
  };

  it('generateWebReceiptNumber generates structured receipt code from district', () => {
    expect(generateWebReceiptNumber('Mirabad')).toBe('REC-MIR-2026-774');
    expect(generateWebReceiptNumber('Chilanzar')).toBe('REC-CHI-2026-774');
    expect(generateWebReceiptNumber('Yakkasaray')).toBe('REC-YAK-2026-774');
    expect(generateWebReceiptNumber('')).toBe('REC-TAS-2026-774');
    expect(generateWebReceiptNumber('Uz')).toBe('REC-TAS-2026-774');
  });

  it('getWebPostcardThemeStyles returns distinct color palettes for themes', () => {
    const paper = getWebPostcardThemeStyles('paper');
    expect(paper.bg).toBe('#FFFDF9');
    expect(paper.text).toBe('#161412');
    expect(paper.sealColor).toBe('#FF5A1F');

    const carbon = getWebPostcardThemeStyles('carbon');
    expect(carbon.bg).toBe('#1C1A18');
    expect(carbon.text).toBe('#FFFFFF');
    expect(carbon.sealColor).toBe('#FF5A1F');

    const mint = getWebPostcardThemeStyles('mint');
    expect(mint.bg).toBe('#EAF7F2');
    expect(mint.text).toBe('#0D3326');
    expect(mint.sealColor).toBe('#0E7A53');
  });

  it('renders postcard with all metadata and barcode', () => {
    const html = renderToStaticMarkup(
      React.createElement(CuratorPostcardGenerator, {
        postcard: testPostcard,
        language: 'en',
      })
    );

    expect(html).toContain('Breadly Bakery &amp; Cafe');
    expect(html).toContain('MIRABAD');
    expect(html).toContain('Aesthetic Coffee');
    expect(html).toContain('SEAL-MIR-892');
    expect(html).toContain('Oybek');
    expect(html).toContain('Kamila Rahimova');
    expect(html).toContain('@kamila_tashkent');
    expect(html).toContain('Local Legend');
    expect(html).toContain('850 XP');
    expect(html).toContain('REC-MIR-2026-774');
    expect(html).toContain('TASHKENT CULTURAL RECEIPT');
    expect(html).toContain('Share to Telegram');
    expect(html).toContain('VERIFIED VISIT');
  });

  it('supports Uzbek and Russian localizations', () => {
    const uzHtml = renderToStaticMarkup(
      React.createElement(CuratorPostcardGenerator, {
        postcard: testPostcard,
        language: 'uz',
      })
    );
    expect(uzHtml).toContain('TOSHKENT MADANIY CHEKI &amp; KARTA');
    expect(uzHtml).toContain('Telegramga Ulashish');
    expect(uzHtml).toContain('TASDIQLANGAN');

    const ruHtml = renderToStaticMarkup(
      React.createElement(CuratorPostcardGenerator, {
        postcard: testPostcard,
        language: 'ru',
      })
    );
    expect(ruHtml).toContain('ТАШКЕНТСКИЙ КУЛЬТУРНЫЙ ЧЕК');
    expect(ruHtml).toContain('Поделиться в Telegram');
    expect(ruHtml).toContain('ПРОВЕРЕНО');
  });

  it('renders correctly with carbon theme and 1:1 aspect ratio', () => {
    const customPostcard: WebCuratorPostcard = {
      ...testPostcard,
      theme: 'carbon',
      aspectRatio: '1:1',
    };

    const html = renderToStaticMarkup(
      React.createElement(CuratorPostcardGenerator, {
        postcard: customPostcard,
      })
    );

    expect(html).toContain('carbon');
    expect(html).toContain('#1C1A18');
  });
});
