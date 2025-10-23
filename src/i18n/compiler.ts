import IntlMessageFormat from 'intl-messageformat'
import type { MessageCompiler, CompileError, MessageContext } from 'vue-i18n'

/**
 * Custom message compiler using intl-messageformat for ICU MessageFormat support.
 * This enables advanced formatting like plurals, select statements, and numbers.
 *
 * @see https://vue-i18n.intlify.dev/guide/advanced/format.html#custom-message-format
 * @see https://formatjs.io/docs/intl-messageformat/
 */
export const messageCompiler: MessageCompiler = (
  message,
  { locale, key, onError }
) => {
  if (typeof message === 'string') {
    /**
     * You can tune your message compiler performance more with your cache strategy or also memoization at here
     */
    const formatter = new IntlMessageFormat(message, locale)
    return (ctx: MessageContext) => {
      return formatter.format(ctx.values) as string
    }
  } else {
    /**
     * for AST.
     * If you would like to support it,
     * You need to transform locale messages such as `json`, `yaml`, etc. with the bundle plugin.
     */
    if (onError) {
      onError(new Error('not support for AST') as CompileError)
    }
    return () => key
  }
}
