import { TRPCError } from '@trpc/server'
import { z } from 'zod'
import { router, protectedProcedure } from './webdev-adapter.mjs'
import { readPlayerSave, writePlayerSave } from './player-saves.mjs'

function playerId(ctx) {
  if (!Number.isSafeInteger(ctx.user.id) || ctx.user.id < 1) {
    throw new TRPCError({ code: 'FORBIDDEN', message: 'player_account_required' })
  }
  return ctx.user.id
}

const saveInput = z.object({
  expectedRevision: z.number().int().min(0).max(4294967294),
  snapshot: z.string().min(2).max(512000),
}).strict()

function checkSnapshot(snapshot) {
  try {
    const value = JSON.parse(snapshot)
    return value && typeof value === 'object' && !Array.isArray(value) && value.version === 1 &&
      typeof value.points === 'number' && typeof value.highestNight === 'number' &&
      Array.isArray(value.owned) && Array.isArray(value.endings) && Array.isArray(value.discovered) &&
      typeof value.run === 'object' && value.run !== null && !Array.isArray(value.run)
  } catch {
    return false
  }
}

export const gameRouter = router({
  player: protectedProcedure.query(({ ctx }) => ({ id: ctx.user.id, name: ctx.user.name })),
  readSave: protectedProcedure.query(({ ctx }) => readPlayerSave(playerId(ctx))),
  writeSave: protectedProcedure.input(saveInput).mutation(({ ctx, input }) => {
    if (!checkSnapshot(input.snapshot)) {
      throw new TRPCError({ code: 'BAD_REQUEST', message: 'invalid_save' })
    }
    return writePlayerSave(playerId(ctx), input.expectedRevision, input.snapshot)
  }),
})
