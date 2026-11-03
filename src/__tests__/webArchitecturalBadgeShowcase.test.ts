import { describe, it, expect } from 'vitest';
import {
  calculateQuestProgress,
  filterQuests,
  getBadgeStatusLabel,
  WebArchitecturalQuest,
} from '../components/WebArchitecturalBadgeShowcase';

describe('WebArchitecturalBadgeShowcase Helper Tests', () => {
  const mockQuests: WebArchitecturalQuest[] = [
    {
      id: 'quest-modernism',
      title: 'Soviet Modernism & Brise-Soleil Trail',
      badgeName: 'Modernist Connoisseur',
      description: 'Explore concrete facades and sun screens.',
      category: 'Modernism',
      accentColor: '#D97706',
      requiredStops: 3,
      xpReward: 50,
      stops: [
        {
          id: 'stop-hotel-uzb',
          name: 'Hotel Uzbekistan',
          district: 'Mirabad',
          architecturalStyle: 'Soviet Modernism',
          yearBuilt: 1974,
          fact: 'Features sweeping curved facade.',
        },
        {
          id: 'stop-circus',
          name: 'Tashkent State Circus',
          district: 'Shaykhontohur',
          architecturalStyle: 'Futuristic Dome',
          yearBuilt: 1976,
          fact: '76m dome without pillars.',
        },
        {
          id: 'stop-blue-domes',
          name: 'Blue Domes',
          district: 'Yakkasaray',
          architecturalStyle: 'Ceramic Vaults',
          yearBuilt: 1970,
          fact: 'Airy pavilions.',
        },
      ],
    },
    {
      id: 'quest-heritage',
      title: 'Silk Road Majolica Route',
      badgeName: 'Silk Road Custodian',
      description: 'Turquoise glazed tiles in Old City.',
      category: 'Heritage',
      accentColor: '#2563EB',
      requiredStops: 2,
      xpReward: 50,
      stops: [
        {
          id: 'stop-hast-imam',
          name: 'Hast Imam',
          district: 'Almazar',
          architecturalStyle: 'Timurid Revival',
          fact: 'Carved sandalwood columns.',
        },
        {
          id: 'stop-kukeldash',
          name: 'Kukeldash Madrasah',
          district: 'Shaykhontohur',
          architecturalStyle: '16th Century Islamic',
          fact: 'High entrance peshtaq portal.',
        },
      ],
    },
  ];

  it('calculates progress accurately for empty, partial, and completed quests', () => {
    const modernism = mockQuests[0];

    // Empty
    const emptyProgress = calculateQuestProgress(modernism, []);
    expect(emptyProgress.visitedCount).toBe(0);
    expect(emptyProgress.percentage).toBe(0);
    expect(emptyProgress.isUnlocked).toBe(false);

    // Partial (1 of 3)
    const partialProgress = calculateQuestProgress(modernism, ['stop-hotel-uzb']);
    expect(partialProgress.visitedCount).toBe(1);
    expect(partialProgress.percentage).toBe(33);
    expect(partialProgress.isUnlocked).toBe(false);

    // Completed (3 of 3)
    const fullProgress = calculateQuestProgress(modernism, [
      'stop-hotel-uzb',
      'stop-circus',
      'stop-blue-domes',
    ]);
    expect(fullProgress.visitedCount).toBe(3);
    expect(fullProgress.percentage).toBe(100);
    expect(fullProgress.isUnlocked).toBe(true);
  });

  it('filters quests by all, in_progress, and completed accurately', () => {
    // Heritage quest is completed, Modernism is in_progress
    const visited = ['stop-hast-imam', 'stop-kukeldash', 'stop-hotel-uzb'];

    const all = filterQuests(mockQuests, 'all', visited);
    expect(all.length).toBe(2);

    const inProgress = filterQuests(mockQuests, 'in_progress', visited);
    expect(inProgress.length).toBe(1);
    expect(inProgress[0].id).toBe('quest-modernism');

    const completed = filterQuests(mockQuests, 'completed', visited);
    expect(completed.length).toBe(1);
    expect(completed[0].id).toBe('quest-heritage');
  });

  it('formats badge status label with trilingual support', () => {
    // Unlocked
    expect(getBadgeStatusLabel(true, 100, 'en')).toBe('Badge Unlocked!');
    expect(getBadgeStatusLabel(true, 100, 'uz')).toBe('Nishon ochildi!');
    expect(getBadgeStatusLabel(true, 100, 'ru')).toBe('Бейдж открыт!');

    // In Progress
    expect(getBadgeStatusLabel(false, 33, 'en')).toBe('33% Completed');
    expect(getBadgeStatusLabel(false, 50, 'uz')).toBe('50% bajarildi');
    expect(getBadgeStatusLabel(false, 75, 'ru')).toBe('75% пройдено');
  });
});
