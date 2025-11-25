export function useSemanticTraits(constraint: string) {
  const affirmed =
    constraint
      .match(/Affirmed:\s([^.]*)/)?.[1]
      ?.split(';')
      .map((s) => s.trim())
      .filter(Boolean)
      .slice(0, 6) ?? []
  const denied =
    constraint
      .match(/Denied:\s([^.]*)/)?.[1]
      ?.split(';')
      .map((s) => s.trim())
      .filter(Boolean)
      .slice(0, 6) ?? []
  return { affirmed, denied }
}
