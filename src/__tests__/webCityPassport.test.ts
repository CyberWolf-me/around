import { describe, it, expect } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { WebCityPassport } from '../components/WebCityPassport';

describe('WebCityPassport Component Tests', () => {
  it('renders ribbon header and initial district stamps tab', () => {
    const html = renderToStaticMarkup(
      React.createElement(WebCityPassport, {
        username: 'kamila',
        neighborhood: 'Mirabad',
        dropsCount: 12,
        visitedDistricts: ['Mirabad', 'Yakkasaray'],
      })
    );

    expect(html).toContain('TASHKENT CITY PASSPORT · @kamila');
    expect(html).toContain('12 Tashkent Districts');
    expect(html).toContain('Ceramic Metro Seals');
    expect(html).toContain('Chilanzar Red');
    expect(html).toContain('Uzbekistan Blue');
    expect(html).toContain('Yunusabad Green');
  });

  it('renders territory crowns section with tastemaker standing', () => {
    const html = renderToStaticMarkup(
      React.createElement(WebCityPassport, {
        username: 'bekzod',
        neighborhood: 'Yakkasaray',
        dropsCount: 18,
        crownsCount: 2,
        initialTab: 'crowns',
      })
    );

    expect(html).toContain('TASHKENT CITY PASSPORT · @bekzod');
    expect(html).toContain('Yakkasaray');
    expect(html).toContain('18 verified drops');
  });
});
