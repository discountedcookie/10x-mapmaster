// Request/response schemas for edge functions
// Using Zod for runtime validation
// This file is for Deno edge functions only

import { z } from 'npm:zod@3.25.76'

// generate-embedding function
export const GenerateEmbeddingRequest = z.object({
  text: z.string().min(1).max(10000),
})
export type GenerateEmbeddingRequestType = z.infer<typeof GenerateEmbeddingRequest>

export const GenerateEmbeddingResponse = z.object({
  embedding: z.array(z.number()),
})
export type GenerateEmbeddingResponseType = z.infer<typeof GenerateEmbeddingResponse>

// call-llm function
export const CallLlmRequest = z.object({
  prompt: z.string().min(1),
  systemPrompt: z.string().optional(),
  model: z.string().optional(),
  // "json" for simple JSON mode, or omit for plain text
  format: z.string().optional(),
  // For structured outputs - pass a JSON schema object
  jsonSchema: z
    .object({
      name: z.string(),
      strict: z.boolean().optional(),
      schema: z.record(z.unknown()),
    })
    .optional(),
  options: z.record(z.unknown()).optional(),
})
export type CallLlmRequestType = z.infer<typeof CallLlmRequest>

export const CallLlmResponse = z.object({
  response: z.string(),
  model: z.string().optional(),
})
export type CallLlmResponseType = z.infer<typeof CallLlmResponse>
