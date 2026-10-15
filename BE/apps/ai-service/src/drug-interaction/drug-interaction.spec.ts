import { describe, expect, it } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { DrugInteractionService } from './drug-interaction.service.js';
import { parseDrugInteraction, prepareDrugInteraction } from './drug-interaction.js';

describe('prepareDrugInteraction', () => {
  it('does not call the model for the first medicine', () => {
    expect(prepareDrugInteraction([], ['Paracetamol'])).toMatchObject({
      action: 'skip',
      result: { checked: true, hasWarning: false },
    });
  });

  it('asks when a new medicine is added beside an active one', () => {
    expect(prepareDrugInteraction(['Aspirin'], ['Warfarin'])).toEqual({
      action: 'ask',
      current: ['Aspirin'],
      incoming: ['Warfarin'],
    });
  });

  it('asks when several new medicines arrive together', () => {
    const plan = prepareDrugInteraction([], ['Warfarin', 'Aspirin']);
    expect(plan.action).toBe('ask');
  });

  it('drops blank names, control characters, and repeated spellings', () => {
    const plan = prepareDrugInteraction(
      ['  Aspirin \n', 'aspirin', 12],
      ['Warfarin', ' warfarin ', ''],
    );
    expect(plan).toEqual({
      action: 'ask',
      current: ['Aspirin'],
      incoming: ['Warfarin'],
    });
  });
});

describe('parseDrugInteraction', () => {
  it('reads a fenced warning', () => {
    const parsed = parseDrugInteraction(`
      \`\`\`json
      { "hasWarning": true, "summary": "Warfarin và Aspirin làm tăng nguy cơ chảy máu." }
      \`\`\`
    `);
    expect(parsed).toEqual({
      checked: true,
      hasWarning: true,
      summary: 'Warfarin và Aspirin làm tăng nguy cơ chảy máu.',
    });
  });

  it('treats the string true as a warning and fills an empty summary', () => {
    expect(parseDrugInteraction('{"hasWarning":"true","summary":"  "}').hasWarning).toBe(true);
    expect(parseDrugInteraction('{"hasWarning":"true","summary":"  "}').summary.length).toBeGreaterThan(0);
  });

  it('rejects a reply that is not JSON', () => {
    expect(() => parseDrugInteraction('không có json')).toThrow('interaction JSON');
  });
});

describe('DrugInteractionService', () => {
  const service = new DrugInteractionService({ get: () => undefined } as unknown as ConfigService);

  it('skips OpenRouter when there is nothing to compare', async () => {
    await expect(service.check({ currentNames: [], newNames: ['Paracetamol'] })).resolves.toMatchObject({
      checked: true,
      hasWarning: false,
    });
  });

  it('refuses to call the model when the API key is missing', async () => {
    await expect(service.check({ currentNames: ['Aspirin'], newNames: ['Warfarin'] })).rejects.toMatchObject({
      message: 'AI_API_KEY is not set',
    });
  });
});
