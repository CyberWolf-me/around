#!/usr/bin/env node
/**
 * Around — Web Intelligence Engine for Polsia Autonomous Daemon
 *
 * Provides live web search and market intelligence extraction without requiring external API keys.
 * Used by Department 1 (Auditor) and Department 2 (CEO) to ground product iterations in real-world
 * Tashkent culture, trending venues, and modern social discovery app benchmarks.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

/**
 * Searches the web via DuckDuckGo and extracts structured snippets.
 * @param {string} query
 * @param {number} limit
 * @returns {Promise<Array<{title: string, snippet: string}>>}
 */
export async function searchWeb(query, limit = 5) {
  try {
    const url = 'https://html.duckduckgo.com/html/?q=' + encodeURIComponent(query);
    const res = await fetch(url, {
      headers: { 'User-Agent': USER_AGENT },
      signal: AbortSignal.timeout(10000),
    });

    if (!res.ok) return [];

    const html = await res.text();
    const results = [];

    // Extract snippets from DDG HTML
    const snippetRegex = /class="result__snippet[^>]*>([\s\S]*?)<\/a>/g;
    const titleRegex = /class="result__a"[^>]*>([\s\S]*?)<\/a>/g;

    const snippets = [];
    const titles = [];

    let match;
    while ((match = snippetRegex.exec(html)) !== null && snippets.length < limit * 2) {
      const clean = match[1]
        .replace(/<[^>]+>/g, '')
        .replace(/&quot;/g, '"')
        .replace(/&#x27;/g, "'")
        .replace(/&amp;/g, '&')
        .trim();
      if (clean) snippets.push(clean);
    }

    while ((match = titleRegex.exec(html)) !== null && titles.length < limit * 2) {
      const clean = match[1]
        .replace(/<[^>]+>/g, '')
        .replace(/&quot;/g, '"')
        .replace(/&#x27;/g, "'")
        .replace(/&amp;/g, '&')
        .trim();
      if (clean) titles.push(clean);
    }

    const count = Math.min(titles.length, snippets.length, limit);
    for (let i = 0; i < count; i++) {
      results.push({
        title: titles[i],
        snippet: snippets[i],
      });
    }

    // Fallback if titleRegex didn't align
    if (results.length === 0 && snippets.length > 0) {
      for (let i = 0; i < Math.min(snippets.length, limit); i++) {
        results.push({
          title: `Result ${i + 1}`,
          snippet: snippets[i],
        });
      }
    }

    return results;
  } catch (err) {
    return [];
  }
}

/**
 * Executes a structured multi-topic intelligence briefing covering:
 * - Tashkent third-wave coffee & specialty roasters
 * - Contemporary Uzbek dining & nightlife
 * - Mobile discovery & viral social loops
 * @returns {Promise<{tashkentCoffee: any[], tashkentDining: any[], viralMechanics: any[]}>}
 */
export async function fetchTashkentBriefing() {
  const [coffee, dining, viral] = await Promise.all([
    searchWeb('Tashkent third-wave specialty coffee roasters cafés 2026', 4),
    searchWeb('Tashkent contemporary restaurants Uzbek cuisine wine bar nightlife', 4),
    searchWeb('places discovery social app viral invite loop user retention mechanics', 3),
  ]);

  return {
    tashkentCoffee: coffee,
    tashkentDining: dining,
    viralMechanics: viral,
    generatedAt: new Date().toISOString(),
  };
}

/**
 * Generates or updates the workspace WEB_INTELLIGENCE.md file.
 */
export async function generateBriefingFile(filePath = 'WEB_INTELLIGENCE.md') {
  const briefing = await fetchTashkentBriefing();

  const md = `# Around — Live Web & Market Intelligence Briefing

Generated: \`${briefing.generatedAt}\`
Source: Polsia Autonomous Web Intelligence Engine

## 1. Tashkent Specialty Coffee & Urban Rhythms
${
  briefing.tashkentCoffee.length > 0
    ? briefing.tashkentCoffee.map((r, i) => `${i + 1}. **${r.title}**: ${r.snippet}`).join('\n\n')
    : '_Live snippets loading..._'
}

## 2. Contemporary Uzbek Dining & Nightlife Culture
${
  briefing.tashkentDining.length > 0
    ? briefing.tashkentDining.map((r, i) => `${i + 1}. **${r.title}**: ${r.snippet}`).join('\n\n')
    : '_Live snippets loading..._'
}

## 3. Social Discovery & Viral Network Mechanics
${
  briefing.viralMechanics.length > 0
    ? briefing.viralMechanics.map((r, i) => `${i + 1}. **${r.title}**: ${r.snippet}`).join('\n\n')
    : '_Live snippets loading..._'
}
`;

  fs.writeFileSync(path.resolve(process.cwd(), filePath), md, 'utf8');
  return { briefing, md };
}

// CLI entrypoint
const isDirectCli = process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
if (isDirectCli) {
  const args = process.argv.slice(2);
  const qIdx = args.indexOf('--query');
  if (qIdx !== -1 && args[qIdx + 1]) {
    searchWeb(args[qIdx + 1]).then((res) => {
      console.log(JSON.stringify(res, null, 2));
    });
  } else {
    generateBriefingFile().then(({ md }) => {
      console.log('✓ Generated WEB_INTELLIGENCE.md:');
      console.log(md.slice(0, 500) + '...\n');
    });
  }
}
