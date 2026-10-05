import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { GENERAL_INFO_DISCLAIMER } from '../medicine-info/medicine-info.js';
import { MedicineInfoService } from '../medicine-info/medicine-info.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { type ChatAnswer, decide, declined, guard, type HistoryItem, lookupUnavailable, medicineInfoAnswer } from './chat.rules.js';

export class ChatDto {
  @ApiProperty({ example: 'I have a sore throat' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  message: string;
}

const chatLimit = () => Number(process.env.CHAT_THROTTLE_LIMIT ?? 30);

@ApiTags('chat')
@ApiBearerAuth()
@Controller('chat')
export class ChatController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly medicineInfo: MedicineInfoService,
  ) {}

  /**
   * Two jobs only: recall what the signed-in user took before for a symptom, or look up a medicine.
   * Anything that needs a doctor is sent to a doctor; anything else is declined.
   */
  @Post()
  @HttpCode(200)
  // A lookup may call a model, so chat has its own, lower limit.
  @Throttle({ default: { ttl: 60_000, limit: chatLimit } })
  async chat(@UserId() userId: string, @Body() dto: ChatDto): Promise<ChatAnswer> {
    const [medicines, allergies] = await Promise.all([
      this.prisma.medicine.findMany({
        where: { userId, source: 'PRESCRIPTION' },
        include: { prescription: { include: { doctor: true } } },
      }),
      this.prisma.allergy.findMany({ where: { userId } }),
    ]);
    const history: HistoryItem[] = medicines.flatMap((m) =>
      m.prescription
        ? [
            {
              medicineId: m.id,
              name: m.name,
              dose: m.dose,
              frequency: m.frequency,
              duration: m.duration,
              feedback: m.feedback,
              condition: m.prescription.condition,
              prescriber: m.prescription.doctor?.name ?? null,
              date: m.prescription.date,
            },
          ]
        : [],
    );
    const names = allergies.map((a) => a.name);

    const decision = decide(dto.message, history, names);
    if (decision.kind !== 'LOOKUP') return guard(decision, history, names, GENERAL_INFO_DISCLAIMER);

    // Only the medicine name goes to the lookup, never the message or the user's data.
    const info = await this.medicineInfo.find(decision.name);
    // A bare word we could not check is not called out of scope: the lookup failed, and we say so.
    if (!info.found && info.reason === 'UNAVAILABLE' && decision.own.length === 0 && !decision.explicit) {
      return lookupUnavailable();
    }
    if (!info.found && decision.own.length === 0 && (info.reason === 'NOT_A_MEDICINE' || !decision.explicit)) {
      return declined();
    }
    const name = decision.own[0]?.name ?? (info.found ? info.name : decision.name);
    const general = info.found ? { usedFor: info.usedFor, storage: info.storage, disclaimer: GENERAL_INFO_DISCLAIMER } : null;
    return guard(medicineInfoAnswer(decision, general, name, names), history, names, GENERAL_INFO_DISCLAIMER);
  }
}
