import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ErrorHandling } from '@lib/error-handling';
import { parsePrescriptionDraft } from './prescription-draft.js';

const PROMPT = `You read a photo of a Vietnamese paper prescription.
Reply with one JSON object and no other text.
Use this shape:
{"title":"","doctorName":null,"prescriptionCode":null,"startDate":null,"endDate":null,"items":[{"name":"","genericName":null,"unit":"VIEN","dosagePerTime":1,"currentStock":null,"instructions":null,"schedules":[{"reminderTime":"08:00","daysOfWeek":[1,2,3,4,5,6,7]}]}]}
Rules:
- unit is VIEN for tablets, GOI for sachets, CHAI for bottles.
- reminderTime is HH:mm. Map sáng to 08:00, trưa to 12:00, chiều to 16:00, tối to 20:00.
- daysOfWeek uses 1 for Monday through 7 for Sunday. Use all seven days when the photo does not name days.
- dosagePerTime is the number of units taken at one time.
- currentStock is the total units on the prescription when it is written as a count, otherwise null.
- Dates are YYYY-MM-DD or null when the photo has no date.
- Keep medicine names as printed. Do not invent medicines that are not on the photo.`;

@Injectable()
export class PrescriptionScanService {
  constructor(private readonly configService: ConfigService) {}

  async scan(imageUrl: string | undefined) {
    const url = imageUrl?.trim() ?? '';
    if (!/^https?:\/\//i.test(url)) {
      throw ErrorHandling.BadRequest('imagePrescriptionUrl must be an http or https URL');
    }
    const content = await this.complete(url);
    try {
      return parsePrescriptionDraft(content);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Could not read the prescription';
      throw ErrorHandling.BadRequest(message);
    }
  }

  private async complete(imageUrl: string) {
    const apiKey = this.configService.get<string>('AI_API_KEY')?.trim();
    const baseUrl = (this.configService.get<string>('AI_BASE_URL') ?? 'https://openrouter.ai/api/v1').replace(/\/$/, '');
    const model = this.configService.get<string>('AI_MODEL') ?? 'qwen/qwen2.5-vl-72b-instruct:free';
    if (!apiKey) {
      throw ErrorHandling.BadRequest('AI_API_KEY is not set');
    }

    let response: Response;
    try {
      response = await fetch(`${baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(90_000),
        body: JSON.stringify({
          model,
          temperature: 0,
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: PROMPT },
                { type: 'image_url', image_url: { url: imageUrl } },
              ],
            },
          ],
        }),
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Vision model request failed';
      throw ErrorHandling.BadRequest(`Vision model request failed: ${message}`);
    }

    const body = await response.json().catch(() => undefined) as {
      error?: { message?: string };
      choices?: Array<{ message?: { content?: unknown } }>;
    } | undefined;
    if (!response.ok) {
      const detail = body?.error?.message ?? response.statusText;
      throw ErrorHandling.BadRequest(`Vision model rejected the photo: ${detail}`);
    }
    return textFromMessage(body?.choices?.[0]?.message?.content);
  }
}

function textFromMessage(content: unknown) {
  if (typeof content === 'string') {
    return content;
  }
  if (!Array.isArray(content)) {
    return '';
  }
  return content
    .map((part) => (typeof part === 'object' && part !== null && 'text' in part ? String(part.text) : ''))
    .join('');
}
