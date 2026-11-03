import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { AppProvider } from '../context/AppContext';
import { ProfileScreen } from '../screens/ProfileScreen';
import { INITIAL_PEOPLE } from '../data/mockData';

describe('P32-02: Web ProfileScreen Trophy Cabinet Integration Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('renders WebTrophyCabinet inside own ProfileScreen markup', () => {
    const html = renderToStaticMarkup(
      React.createElement(
        AppProvider,
        null,
        React.createElement(ProfileScreen, null),
      ),
    );

    // Verify Trophy Cabinet container is present
    expect(html).toContain('data-testid="web-trophy-cabinet"');
    expect(html).toContain('data-testid="crown-pill"');
    expect(html).toContain('data-testid="mastery-title"');
    expect(html).toContain('Autumn in Tashkent');
    expect(html).toContain('District Laurels');
    expect(html).toContain('Share Accolades');
  });

  it('renders WebTrophyCabinet for other visited community profiles', () => {
    const member = Object.values(INITIAL_PEOPLE)[0];
    const html = renderToStaticMarkup(
      React.createElement(
        AppProvider,
        null,
        React.createElement(ProfileScreen, { userId: member.id }),
      ),
    );

    expect(html).toContain('data-testid="web-trophy-cabinet"');
    expect(html).toContain(member.name);
    expect(html).toContain('data-testid="crown-pill"');
    expect(html).toContain('Seasonal Trophies');
  });
});
