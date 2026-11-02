import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import * as soundEffects from '../services/soundEffects';
import { AudienceBadge } from '../components/ui/AudienceBadge';
import { StarRating } from '../components/ui/StarRating';
import { PassportShareModal } from '../components/PassportShareModal';
import { renderToString } from 'react-dom/server';
import React from 'react';

describe('P19-03: Web Companion Audio-Tactile UI Component Integration', () => {
  let playSoundSpy: any;

  beforeEach(() => {
    playSoundSpy = vi.spyOn(soundEffects, 'playSoundWithHaptic').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('AudienceBadge triggers tactile sound on interactive click', () => {
    const onClick = vi.fn();
    const element = AudienceBadge({
      aud: 'friends',
      interactive: true,
      onClick,
    }) as any;

    expect(element.props.role).toBe('button');
    expect(element.props.tabIndex).toBe(0);

    const stopPropagation = vi.fn();
    element.props.onClick({ stopPropagation });

    expect(stopPropagation).toHaveBeenCalled();
    expect(playSoundSpy).toHaveBeenCalledWith('click', 'selection');
    expect(onClick).toHaveBeenCalled();
  });

  it('AudienceBadge does not trigger sound or click when not interactive', () => {
    const onClick = vi.fn();
    const element = AudienceBadge({
      aud: 'public',
      interactive: false,
      onClick,
    }) as any;

    expect(element.props.role).toBeUndefined();
    expect(element.props.onClick).toBeUndefined();
    expect(playSoundSpy).not.toHaveBeenCalled();
    expect(onClick).not.toHaveBeenCalled();
  });

  it('StarRating triggers selection sound on star click when interactive', () => {
    const onChange = vi.fn();
    const element = StarRating({
      rating: 3,
      interactive: true,
      onChange,
    }) as any;

    // element.props.children is an array of 5 star buttons
    const starButtons = element.props.children;
    expect(starButtons).toHaveLength(5);

    // Click 4th star (rating 4)
    const star4 = starButtons[3];
    star4.props.onClick();

    expect(playSoundSpy).toHaveBeenCalledWith('select', 'selection');
    expect(onChange).toHaveBeenCalledWith(4);
  });

  it('StarRating does not trigger sound when non-interactive', () => {
    const onChange = vi.fn();
    const element = StarRating({
      rating: 3,
      interactive: false,
      onChange,
    }) as any;

    const starButtons = element.props.children;
    const star2 = starButtons[1];
    star2.props.onClick();

    expect(playSoundSpy).not.toHaveBeenCalled();
    expect(onChange).not.toHaveBeenCalled();
  });

  it('PassportShareModal renders modal content and handles audio triggers', () => {
    const onClose = vi.fn();
    const html = renderToString(
      React.createElement(PassportShareModal, {
        isOpen: true,
        onClose,
        username: 'tashkent_curator',
        fullName: 'Kamila Rahimova',
      })
    );

    expect(html).toContain('Kamila Rahimova');
    expect(html).toContain('tashkent_curator');
    expect(html).toContain('Share via Telegram');
    expect(html).toContain('Copy Passport Link');

    // Closed modal returns empty
    const closedHtml = renderToString(
      React.createElement(PassportShareModal, {
        isOpen: false,
        onClose,
        username: 'tashkent_curator',
        fullName: 'Kamila Rahimova',
      })
    );
    expect(closedHtml).toBe('');
  });
});
